const page = "__PAGE_HTML__";

const PACKS = [
  { id: "common", name: "Comum", chance: 65, size: () => 1 + Math.floor(Math.random() * 2) },
  { id: "uncommon", name: "Incomum", chance: 20, size: () => 3 },
  { id: "rare", name: "Rara", chance: 8, size: () => 4 + Math.floor(Math.random() * 2) },
  { id: "epic", name: "Épica", chance: 4, size: () => 6 },
  { id: "mythic", name: "Mítica", chance: 2, size: () => 7 },
  { id: "legendary", name: "Lendária", chance: 0.8, size: () => 10 },
  { id: "secret", name: "Secreta", chance: 0.2, size: () => 10 },
];
const RANGES = [[1,45],[46,69],[70,83],[84,91],[92,95],[96,97],[98,100]];
const REWARDS = [2,4,7,12,20,35,60];
const PULL_WEIGHTS = [[88,8,2.8,.7,.3,.18,.02],[68,21,7,2.5,1,.45,.05],[50,27,14,6,2,.9,.1],[39,25,17,13,4,1.8,.2],[31,24,18,14,9,3.5,.5],[24,21,18,15,11,9,2],[22,20,18,15,10,10,5]];

function json(data, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" } });
}
function userFrom(request) {
  const id = request.headers.get("oai-authenticated-user-id");
  if (!id) return null;
  return {
    id,
    email: request.headers.get("oai-authenticated-user-email") || "Conta ChatGPT",
    name: decodeName(request.headers),
  };
}
function decodeName(headers) {
  const value = headers.get("oai-authenticated-user-full-name");
  if (!value || headers.get("oai-authenticated-user-full-name-encoding") !== "percent-encoded-utf-8") return null;
  try { return decodeURIComponent(value); } catch { return null; }
}
function sameOrigin(request) {
  const origin = request.headers.get("origin");
  return !origin || origin === new URL(request.url).origin;
}
function today(request) {
  const formatter = new Intl.DateTimeFormat("en-CA", { timeZone: "America/Fortaleza", year: "numeric", month: "2-digit", day: "2-digit" });
  return formatter.format(new Date());
}
function rarityIndex(cardId) {
  return RANGES.findIndex(([a,b]) => cardId >= a && cardId <= b);
}
function chooseWeighted(weights) {
  let x = Math.random() * weights.reduce((a,b) => a + b, 0);
  for (let i = 0; i < weights.length; i++) { x -= weights[i]; if (x <= 0) return i; }
  return 0;
}
function randomCard(ri) {
  const [a,b] = RANGES[ri];
  return a + Math.floor(Math.random() * (b - a + 1));
}
function chooseTier() { return chooseWeighted(PACKS.map(p => p.chance)); }
function drawPack(tier) {
  const result = [];
  if (tier === 6) result.push(randomCard(5), randomCard(6));
  else result.push(randomCard(tier));
  while (result.length < PACKS[tier].size()) result.push(randomCard(chooseWeighted(PULL_WEIGHTS[tier])));
  return result.sort((a,b) => rarityIndex(a) - rarityIndex(b));
}
async function ensureUser(db, user) {
  await db.batch([
    db.prepare("INSERT INTO users (id, email, display_name) VALUES (?, ?, ?) ON CONFLICT(id) DO UPDATE SET email = excluded.email, display_name = excluded.display_name, updated_at = CURRENT_TIMESTAMP").bind(user.id, user.email, user.name),
    db.prepare("INSERT INTO progress (user_id) VALUES (?) ON CONFLICT(user_id) DO NOTHING").bind(user.id),
  ]);
}
async function readProgress(db, userId) {
  const row = await db.prepare("SELECT owned_json, juice, last_opened, packs FROM progress WHERE user_id = ?").bind(userId).first();
  if (!row) throw new Error("Progresso indisponível");
  let owned = {};
  try { owned = JSON.parse(row.owned_json || "{}"); } catch { owned = {}; }
  return { owned, juice: Number(row.juice) || 0, lastOpened: row.last_opened || null, packs: Number(row.packs) || 0 };
}
function applyDraw(state, tier, source) {
  const draw = drawPack(tier), entries = [], seen = new Set(Object.keys(state.owned).filter(k => state.owned[k] > 0));
  let reward = 0;
  for (const id of draw) {
    const isNew = !seen.has(String(id));
    if (isNew) seen.add(String(id)); else reward += REWARDS[rarityIndex(id)];
    state.owned[id] = (state.owned[id] || 0) + 1;
    entries.push({ id, is_new: isNew });
  }
  if (source === "daily") state.juice += 5;
  if (source === "mystery") state.juice -= 30;
  state.juice += reward;
  state.packs += 1;
  return { entries, reward: reward + (source === "daily" ? 5 : 0) };
}
async function session(request, env, user) {
  await ensureUser(env.DB, user);
  const state = await readProgress(env.DB, user.id);
  return json({ user: { email: user.email, name: user.name }, state, daily_available: state.lastOpened !== today(request) });
}
async function openPack(request, env, user, source) {
  if (!sameOrigin(request)) return json({ error: "Origem inválida" }, 403);
  await ensureUser(env.DB, user);
  const state = await readProgress(env.DB, user.id);
  const date = today(request);
  if (source === "daily" && state.lastOpened === date) return json({ error: "O pacote diário já foi aberto." }, 409);
  if (source === "mystery" && state.juice < 30) return json({ error: "Você precisa de 30 Suco de Caju." }, 409);
  const tier = chooseTier();
  const { entries, reward } = applyDraw(state, tier, source);
  if (source === "daily") state.lastOpened = date;
  const result = await env.DB.prepare("UPDATE progress SET owned_json = ?, juice = ?, last_opened = ?, packs = ?, updated_at = CURRENT_TIMESTAMP WHERE user_id = ? AND (last_opened IS NULL OR last_opened <> ? OR ? = 'mystery')").bind(JSON.stringify(state.owned), state.juice, state.lastOpened, state.packs, user.id, date, source).run();
  if (!result.meta?.changes) return json({ error: "O pacote diário já foi aberto." }, 409);
  return json({ pack_rarity: PACKS[tier].name, pack_tier: PACKS[tier].id, entries, reward, state, daily_available: state.lastOpened !== date });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname === "/") return new Response(page, { headers: { "content-type": "text/html; charset=utf-8", "cache-control": "no-store" } });
    if (url.pathname.startsWith("/api/")) {
      const user = userFrom(request);
      if (!user) return json({ error: "Entre com sua conta ChatGPT para continuar.", sign_in: "/signin-with-chatgpt?return_to=/" }, 401);
      try {
        if (url.pathname === "/api/session" && request.method === "GET") return await session(request, env, user);
        if (url.pathname === "/api/open-daily" && request.method === "POST") return await openPack(request, env, user, "daily");
        if (url.pathname === "/api/buy-mystery" && request.method === "POST") return await openPack(request, env, user, "mystery");
      } catch (error) {
        console.error("Album API error", error);
        return json({ error: "Não foi possível acessar seu álbum agora. Tente novamente." }, 500);
      }
    }
    return new Response("Not found", { status: 404 });
  },
};
