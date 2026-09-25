import { cpSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";

const root = resolve(import.meta.dirname, "..");
const dist = resolve(root, "dist");
rmSync(dist, { recursive: true, force: true });
mkdirSync(resolve(dist, "server"), { recursive: true });
mkdirSync(resolve(dist, ".openai"), { recursive: true });
const source = readFileSync(resolve(root, "worker/index.js"), "utf8");
const page = readFileSync(resolve(root, "worker/page.html"), "utf8");
const built = source.replace('const page = "__PAGE_HTML__";', `const page = ${JSON.stringify(page)};`);
if (built === source) throw new Error("Page placeholder was not found");
writeFileSync(resolve(dist, "server/index.js"), built);
cpSync(resolve(root, ".openai/hosting.json"), resolve(dist, ".openai/hosting.json"));
console.log("Worker build ready");

