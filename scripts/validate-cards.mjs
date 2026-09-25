import { readFileSync } from "node:fs";
import vm from "node:vm";

const source = readFileSync(new URL("../src/main.js", import.meta.url), "utf8");
const namesMatch = source.match(/const cardNames = (\[[\s\S]*?\n\]);/);
if (!namesMatch) throw new Error("cardNames não encontrado");
const names = vm.runInNewContext(namesMatch[1]);
if (names.length !== 110) throw new Error(`Esperadas 110 figurinhas; encontradas ${names.length}`);

const sets = {};
for (const rarity of ["uncommon", "rare", "epic", "mythic", "legendary", "secret"]) {
  const match = source.match(new RegExp(`const ${rarity}Ids = new Set\\((\\[[^;]+\\])\\);`));
  if (!match) throw new Error(`Lista ${rarity} não encontrada`);
  sets[rarity] = new Set(vm.runInNewContext(match[1]));
}
const counts = { common: 0, uncommon: 0, rare: 0, epic: 0, mythic: 0, legendary: 0, secret: 0 };
for (let id = 1; id <= names.length; id++) {
  const rarity = ["secret", "legendary", "mythic", "epic", "rare", "uncommon"].find(key => sets[key].has(id)) || "common";
  counts[rarity]++;
}
const expected = { common: 50, uncommon: 27, rare: 15, epic: 9, mythic: 4, legendary: 2, secret: 3 };
if (JSON.stringify(counts) !== JSON.stringify(expected)) throw new Error(`Distribuição incorreta: ${JSON.stringify(counts)}`);
console.log(JSON.stringify({ total: names.length, rarities: counts }));
