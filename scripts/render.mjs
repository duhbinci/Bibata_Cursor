// Parallel bitmap rendering: splits render.json into one config per theme
// and runs cbmp on each concurrently (cbmp itself renders themes serially).
import { spawn } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { availableParallelism, tmpdir } from "node:os";
import { join, resolve as abs } from "node:path";

const bin = join(process.cwd(), "node_modules", "cbmp", "bin", "cbmp.js");

const config = JSON.parse(readFileSync("render.json", "utf8"));
const jobs = Number(process.env.JOBS) || availableParallelism();
const tmp = mkdtempSync(join(tmpdir(), "cbmp-"));
const keys = Object.keys(config);

const run = (key) =>
  new Promise((done, reject) => {
    const file = join(tmp, `${key}.json`);
    const cfg = { ...config[key], dir: abs(config[key].dir), out: abs(config[key].out) };
    writeFileSync(file, JSON.stringify({ [key]: cfg }));
    const p = spawn(process.execPath, [bin, file], { stdio: "inherit" });
    p.on("exit", (code) => (code === 0 ? done() : reject(new Error(`${key} failed (${code})`))));
  });

let next = 0;
const worker = async () => {
  while (next < keys.length) await run(keys[next++]);
};

try {
  await Promise.all(Array.from({ length: Math.min(jobs, keys.length) }, worker));
} finally {
  rmSync(tmp, { recursive: true, force: true });
}
