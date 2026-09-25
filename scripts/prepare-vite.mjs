import { readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";

const root = resolve(import.meta.dirname, "..");
const template = readFileSync(resolve(root, "worker/page.html"), "utf8");
const html = template.replace(/\s*<script>[\s\S]*?<\/script>\s*<\/body>/, '\n  <script type="module" src="/src/main.js"></script>\n</body>');
if (html === template) throw new Error("Could not replace legacy script");
writeFileSync(resolve(root, "index.html"), html);
console.log("Vite HTML ready");
