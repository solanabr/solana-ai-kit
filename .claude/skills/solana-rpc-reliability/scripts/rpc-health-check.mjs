#!/usr/bin/env node
import { resolve } from "node:path";
import { performance } from "node:perf_hooks";
import { pathToFileURL } from "node:url";

const DEFAULT_RPC = "https://api.mainnet-beta.solana.com";
export const REQUEST_TIMEOUT_MS = 5_000;

function requireValue(args, index, option) {
  const value = args[index + 1];
  if (value === undefined || value.startsWith("--")) {
    throw new Error(`${option} requires a value.`);
  }
  return value;
}

function validateRpcUrl(value) {
  let parsed;
  try {
    parsed = new URL(value);
  } catch {
    throw new Error(`--rpc must be a valid HTTP(S) URL: ${value}`);
  }
  if (!parsed.hostname || !["http:", "https:"].includes(parsed.protocol)) {
    throw new Error(`--rpc must be a valid HTTP(S) URL: ${value}`);
  }
  return value;
}

function parseSamples(value) {
  const samples = Number(value);
  if (!value.trim() || !Number.isSafeInteger(samples) || samples < 0) {
    throw new Error(`--samples must be a non-negative integer: ${value}`);
  }
  return samples;
}

export function readArgs(args = process.argv.slice(2)) {
  const config = { rpcs: [], json: false, samples: 5 };
  for (let i = 0; i < args.length; i += 1) {
    if (args[i] === "--rpc") {
      config.rpcs.push(validateRpcUrl(requireValue(args, i, "--rpc")));
      i += 1;
    } else if (args[i] === "--json") {
      config.json = true;
    } else if (args[i] === "--samples") {
      config.samples = parseSamples(requireValue(args, i, "--samples"));
      i += 1;
    } else {
      throw new Error(`Unknown argument: ${args[i]}`);
    }
  }
  if (!config.rpcs.length) config.rpcs.push(DEFAULT_RPC);
  return config;
}

export async function rpc(
  url,
  method,
  params = [],
  { fetchImpl = globalThis.fetch, timeoutMs = REQUEST_TIMEOUT_MS } = {}
) {
  if (typeof fetchImpl !== "function") throw new Error("fetch is not available in this Node.js runtime.");
  if (!Number.isFinite(timeoutMs) || timeoutMs <= 0) {
    throw new Error("timeoutMs must be a positive number.");
  }

  const started = performance.now();
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetchImpl(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ jsonrpc: "2.0", id: method, method, params }),
      signal: controller.signal
    });
    const latencyMs = Math.round(performance.now() - started);
    const text = await response.text();
    let body;
    try {
      body = JSON.parse(text);
    } catch {
      body = { error: { message: text.slice(0, 300) } };
    }
    if (!response.ok || body.error) {
      const error = new Error(body.error?.message ?? response.statusText);
      error.latencyMs = latencyMs;
      error.status = response.status;
      error.body = body;
      throw error;
    }
    return { result: body.result, latencyMs };
  } catch (error) {
    const latencyMs = Math.round(performance.now() - started);
    if (error?.name === "AbortError") {
      const timeoutError = new Error(`RPC ${method} timed out after ${timeoutMs}ms.`);
      timeoutError.name = "TimeoutError";
      timeoutError.latencyMs = latencyMs;
      throw timeoutError;
    }
    if (error && typeof error === "object") {
      error.latencyMs ??= latencyMs;
      throw error;
    }
    const wrapped = new Error(String(error));
    wrapped.latencyMs = latencyMs;
    throw wrapped;
  } finally {
    clearTimeout(timeout);
  }
}

export function verdict(checks) {
  if (!checks.healthOk) return "unhealthy";
  if (checks.errors.length) return "degraded";
  if (checks.maxLatencyMs > 1_000) return "slow";
  return "healthy";
}

export function recommendations(checks) {
  const tips = [];
  if (!checks.healthOk) tips.push("Do not use this endpoint for production sends until getHealth is ok.");
  if (checks.maxLatencyMs > 1_000) tips.push("Latency is high; use a dedicated send provider for user-facing transactions.");
  if (!checks.latestBlockhash) tips.push("Could not fetch latest blockhash; transaction builders will fail or use stale data.");
  if (checks.performanceSamples === null) tips.push("Could not fetch performance samples; monitor provider health separately.");
  if (!tips.length) tips.push("Endpoint is suitable for basic reads; still add expiry-aware confirmation for sends.");
  return tips;
}

export async function checkEndpoint(url, samples, rpcOptions = {}) {
  const checks = {
    url,
    checkedAt: new Date().toISOString(),
    healthOk: false,
    version: null,
    slot: null,
    latestBlockhash: null,
    lastValidBlockHeight: null,
    blockHeight: null,
    performanceSamples: null,
    averageTps: null,
    maxLatencyMs: 0,
    calls: [],
    errors: []
  };

  async function capture(label, method, params = []) {
    try {
      const { result, latencyMs } = await rpc(url, method, params, rpcOptions);
      checks.maxLatencyMs = Math.max(checks.maxLatencyMs, latencyMs);
      checks.calls.push({ label, method, latencyMs, ok: true });
      return result;
    } catch (error) {
      checks.maxLatencyMs = Math.max(checks.maxLatencyMs, error.latencyMs ?? 0);
      checks.calls.push({ label, method, latencyMs: error.latencyMs ?? null, ok: false });
      checks.errors.push({ label, method, message: error.message, status: error.status ?? null });
      return null;
    }
  }

  const health = await capture("health", "getHealth");
  checks.healthOk = health === "ok";
  checks.version = await capture("version", "getVersion");
  checks.slot = await capture("slot", "getSlot", [{ commitment: "confirmed" }]);
  const blockhash = await capture("latestBlockhash", "getLatestBlockhash", [{ commitment: "confirmed" }]);
  checks.latestBlockhash = blockhash?.value?.blockhash ?? null;
  checks.lastValidBlockHeight = blockhash?.value?.lastValidBlockHeight ?? null;
  checks.blockHeight = await capture("blockHeight", "getBlockHeight", [{ commitment: "confirmed" }]);
  const perf = await capture("performanceSamples", "getRecentPerformanceSamples", [samples]);
  checks.performanceSamples = perf?.length ?? null;
  checks.averageTps = perf?.length
    ? Math.round(perf.reduce((sum, sample) => sum + sample.numTransactions / sample.samplePeriodSecs, 0) / perf.length)
    : null;

  return {
    ...checks,
    verdict: verdict(checks),
    recommendations: recommendations(checks)
  };
}

export function printText(results) {
  for (const result of results) {
    console.log(`RPC: ${result.url}`);
    console.log(`Verdict: ${result.verdict}`);
    console.log(`Health: ${result.healthOk ? "ok" : "not ok"}`);
    console.log(`Slot: ${result.slot ?? "n/a"}`);
    console.log(`Block height: ${result.blockHeight ?? "n/a"}`);
    console.log(`Average TPS sample: ${result.averageTps ?? "n/a"}`);
    console.log(`Max latency: ${result.maxLatencyMs}ms`);
    console.log("Recommendations:");
    for (const tip of result.recommendations) console.log(`- ${tip}`);
    if (result.errors.length) {
      console.log("Errors:");
      for (const error of result.errors) console.log(`- ${error.method}: ${error.message}`);
    }
    console.log("");
  }
}

export async function main(args = process.argv.slice(2), rpcOptions = {}) {
  const config = readArgs(args);
  const results = [];
  for (const url of config.rpcs) {
    results.push(await checkEndpoint(url, config.samples, rpcOptions));
  }

  if (config.json) console.log(JSON.stringify({ schema: "solana-rpc-health/v1", results }, null, 2));
  else printText(results);
  return results;
}

const isMain = process.argv[1] && pathToFileURL(resolve(process.argv[1])).href === import.meta.url;
if (isMain) {
  try {
    await main();
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exitCode = 1;
  }
}

