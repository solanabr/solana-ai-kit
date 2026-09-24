import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { spawnSync } from "node:child_process";
import test from "node:test";
import { fileURLToPath } from "node:url";

import {
  checkEndpoint,
  readArgs,
  recommendations,
  rpc
} from "../.claude/skills/solana-rpc-reliability/scripts/rpc-health-check.mjs";

const scriptUrl = new URL(
  "../.claude/skills/solana-rpc-reliability/scripts/rpc-health-check.mjs",
  import.meta.url
);

test("readArgs applies defaults and accepts zero performance samples", () => {
  assert.deepEqual(readArgs([]), {
    rpcs: ["https://api.mainnet-beta.solana.com"],
    json: false,
    samples: 5
  });
  assert.deepEqual(readArgs(["--rpc", "https://rpc.example.com", "--samples", "0", "--json"]), {
    rpcs: ["https://rpc.example.com"],
    json: true,
    samples: 0
  });
});

test("readArgs rejects missing and invalid RPC values", () => {
  assert.throws(() => readArgs(["--rpc"]), /--rpc requires a value/);
  assert.throws(() => readArgs(["--rpc", "not-a-url"]), /valid HTTP\(S\) URL/);
  assert.throws(() => readArgs(["--rpc", "ftp:\/\/rpc.example.com"]), /valid HTTP\(S\) URL/);
});

test("readArgs rejects missing and invalid sample counts", () => {
  assert.throws(() => readArgs(["--samples"]), /--samples requires a value/);
  assert.throws(() => readArgs(["--samples", "many"]), /non-negative integer/);
  assert.throws(() => readArgs(["--samples", "-1"]), /non-negative integer/);
  assert.throws(() => readArgs(["--samples", "1.5"]), /non-negative integer/);
});

test("CLI reports argument validation errors without a stack trace", () => {
  const result = spawnSync(process.execPath, [fileURLToPath(scriptUrl), "--rpc"], {
    encoding: "utf8"
  });
  assert.equal(result.status, 1);
  assert.match(result.stderr, /^Error: --rpc requires a value\.\s*$/);
  assert.doesNotMatch(result.stderr, /\n\s+at /);
});

test("rpc aborts a stalled request after the configured timeout", { timeout: 1_000 }, async () => {
  const fetchImpl = (_url, { signal }) => new Promise((_resolve, reject) => {
    signal.addEventListener("abort", () => {
      const error = new Error("aborted");
      error.name = "AbortError";
      reject(error);
    }, { once: true });
  });

  await assert.rejects(
    rpc("https://rpc.example.com", "getHealth", [], { fetchImpl, timeoutMs: 20 }),
    (error) => {
      assert.equal(error.name, "TimeoutError");
      assert.match(error.message, /getHealth timed out after 20ms/);
      assert.ok(Number.isFinite(error.latencyMs));
      return true;
    }
  );
});

test("an empty performance sample list remains a valid zero result", async () => {
  const results = {
    getHealth: "ok",
    getVersion: { "solana-core": "test" },
    getSlot: 0,
    getLatestBlockhash: { value: { blockhash: "abc", lastValidBlockHeight: 0 } },
    getBlockHeight: 0,
    getRecentPerformanceSamples: []
  };
  const fetchImpl = async (_url, options) => {
    const request = JSON.parse(options.body);
    return {
      ok: true,
      status: 200,
      statusText: "OK",
      text: async () => JSON.stringify({ jsonrpc: "2.0", id: request.id, result: results[request.method] })
    };
  };

  const result = await checkEndpoint("https://rpc.example.com", 0, { fetchImpl, timeoutMs: 100 });
  assert.equal(result.performanceSamples, 0);
  assert.equal(result.averageTps, null);
  assert.equal(result.slot, 0);
  assert.equal(result.blockHeight, 0);
  assert.equal(result.lastValidBlockHeight, 0);
  assert.doesNotMatch(result.recommendations.join("\n"), /Could not fetch performance samples/);
  assert.match(recommendations({ ...result, performanceSamples: null }).join("\n"), /Could not fetch performance samples/);
});

test("diagnostic documentation names fields emitted by the script", async () => {
  const docs = await readFile(
    new URL("../.claude/skills/solana-rpc-reliability/references/diagnostic-workflow.md", import.meta.url),
    "utf8"
  );
  assert.match(docs, /`maxLatencyMs > 1000`/);
  assert.match(docs, /`slot`/);
  assert.match(docs, /`performanceSamples=null`/);
  assert.match(docs, /`averageTps`/);
  assert.doesNotMatch(docs, /`latencyMs >|`slotLag`|`tpsSample/);
});
