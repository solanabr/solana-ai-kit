#!/usr/bin/env node
import { performance } from "node:perf_hooks";

const DEFAULT_RPC = "https://api.mainnet-beta.solana.com";

function readArgs() {
  const args = process.argv.slice(2);
  const config = { rpcs: [], json: false, samples: 5 };
  for (let i = 0; i < args.length; i += 1) {
    if (args[i] === "--rpc") config.rpcs.push(args[++i]);
    else if (args[i] === "--json") config.json = true;
    else if (args[i] === "--samples") config.samples = Number(args[++i]);
  }
  if (!config.rpcs.length) config.rpcs.push(DEFAULT_RPC);
  return config;
}

async function rpc(url, method, params = []) {
  const started = performance.now();
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ jsonrpc: "2.0", id: method, method, params })
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
}

function verdict(checks) {
  if (!checks.healthOk) return "unhealthy";
  if (checks.errors.length) return "degraded";
  if (checks.maxLatencyMs > 1_000) return "slow";
  return "healthy";
}

function recommendations(checks) {
  const tips = [];
  if (!checks.healthOk) tips.push("Do not use this endpoint for production sends until getHealth is ok.");
  if (checks.maxLatencyMs > 1_000) tips.push("Latency is high; use a dedicated send provider for user-facing transactions.");
  if (!checks.latestBlockhash) tips.push("Could not fetch latest blockhash; transaction builders will fail or use stale data.");
  if (!checks.performanceSamples) tips.push("Could not fetch performance samples; monitor provider health separately.");
  if (!tips.length) tips.push("Endpoint is suitable for basic reads; still add expiry-aware confirmation for sends.");
  return tips;
}

async function checkEndpoint(url, samples) {
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
      const { result, latencyMs } = await rpc(url, method, params);
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

function printText(results) {
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

const config = readArgs();
const results = [];
for (const url of config.rpcs) {
  results.push(await checkEndpoint(url, config.samples));
}

if (config.json) console.log(JSON.stringify({ schema: "solana-rpc-health/v1", results }, null, 2));
else printText(results);

