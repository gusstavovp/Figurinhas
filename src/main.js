import { createClient } from "@supabase/supabase-js";

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || "https://umayamlvxcdccmkpghmg.supabase.co";
const supabaseKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY || "sb_publishable_R5rN_XnQ7u_B-bv900ZY1g_K6V_wIIl";
const configured = supabaseUrl?.startsWith("https://") && supabaseKey?.startsWith("sb_publishable_");
const supabase = configured ? createClient(supabaseUrl, supabaseKey) : null;
const TOTAL_CARDS = 110;

const rarities = [
  { id: "common", name: "Comum", color: "#9aa0b6", count: 35, packChance: 65, size: "1–2", guarantee: "1 comum ou melhor" },
  { id: "uncommon", name: "Incomum", color: "#5fe0a1", count: 26, packChance: 20, size: "3", guarantee: "1 incomum ou melhor" },
  { id: "rare", name: "Rara", color: "#53b8ff", count: 21, packChance: 8, size: "4–5", guarantee: "1 rara ou melhor" },
  { id: "epic", name: "Épica", color: "#b277ff", count: 14, packChance: 4, size: "6", guarantee: "1 épica ou melhor" },
  { id: "mythic", name: "Mítica", color: "#ff6eb5", count: 7, packChance: 2, size: "7", guarantee: "1 mítica ou melhor" },
  { id: "legendary", name: "Lendária", color: "#ffd75f", count: 4, packChance: .8, size: "10", guarantee: "1 lendária exclusiva" },
  { id: "secret", name: "Secreta", color: "#ff775f", count: 3, packChance: .2, size: "10", guarantee: "1 lendária + 1 secreta" }
];

const cardNames = [
  "Pedro Víctor Furry", "Pedro Víctor com Furry", "Pedro Víctor 67", "Pedro Víctor tomando Suco de Caju", "Pedro Víctor sendo o Suco de Caju",
  "Pedro Víctor com arroz e feijão", "Pedro Víctor sendo o arroz e feijão", "Pedro Víctor sendo o animatronic Freddy", "Pedro Víctor Chica", "Pedro Víctor Foxy",
  "Pedro Víctor Bonnie", "Pedro Víctor Funtime Freddy", "Pedro Víctor Funtime Foxy", "Pedro Víctor Ballora", "Pedro Víctor professor de matemática",
  "Pedro Víctor com roupa colorida", "Pedro Víctor Batman", "Pedro Víctor Mulher-Maravilha", "Pedro Víctor Superman", "Pedro Víctor Flash",
  "Pedro Víctor Coringa", "Pedro Víctor Arlequina", "Pedro Víctor Duas-Caras", "Pedro Víctor Hulk", "Pedro Víctor com roupa de dormir",
  "Pedro Víctor sendo o Gon de Hunter x Hunter", "Pedro Víctor sendo o CJ", "Pedro Víctor com Novinho", "Pedro Víctor com Novinho", "Pedro Víctor cozinheiro",
  "Pedro Víctor policial", "Pedro Víctor papagaio de Gustavo", "Pedro Víctor chinela Havaiana", "Pedro Víctor relógio", "Pedro Víctor comendo carne",
  "Pedro Víctor Manoel Gomes", "Pedro Víctor cavalo", "Pedro Víctor Stand Notorious B.I.G.", "Pedro Víctor Isaac", "Pedro Víctor Saiko",
  "Pedro Víctor cupido", "Pedro Víctor palhaço", "Pedro Víctor jogador de futebol", "Pedro Víctor caixa de som", "Pedro Víctor jogador de LoL",
  "Pedro Víctor gordo", "Pedro Víctor na academia", "Pedro Víctor Minecraft", "Pedro Víctor mago", "Pedro Víctor criança",
  "Pedra Víctoria", "Pedro Víctor idoso", "Pedro Víctor Lanterna Rosa", "Pedro Víctor pecado da Ira", "Pedro Víctor Bob Esponja",
  "Paulo Víctor", "Pedro Liso", "Pedro Víctor matuto", "Pedro Víctor rico", "Pedro Víctor Avatar",
  "Pedro Víctor Saiyajin", "Pedro Víctor Fortnite", "Pedro Víctor Morty", "Pedro Víctor Rick", "Pedro Víctor Lula Molusco",
  "Pedro Víctor Patrick Estrela", "Pedro Potter", "Pedro Víctor tomando morango ao leite", "Pedro Víctor Springtrap", "Pedro Víctor dirigindo moto",
  "Pedro Víctor Curupira", "Pedro Víctor Cuca", "Pedro Víctor Iara", "Pedro Víctor Saci", "Pedro Víctor Boitatá",
  "Pedro Víctor Mapinguari", "Pedro Víctor cabelo grande", "Pedro Víctor mandrake", "Pedro Víctor gótico emo", "Pedro Víctor cabelo colorido",
  "Pedro Víctor de barba", "Pedro Víctor ônibus", "Pedro Víctor Célio, motorista de ônibus", "Pedro Víctor Orochinho", "Pedro Víctor Sasuke",
  "Pedro Víctor Naruto", "Pedro Víctor Sakura", "Pedro Víctor Kakashi", "Pedro Víctor lendo livro", "Pedro Víctor consertando carro",
  "Pedro Víctor consertando computador", "Pedro Víctor cafetão", "Pedro Víctor sugar baby", "Pedro Víctor bebezão da boca inchada", "Pedro Víctor Kurapika Kurta",
  "Pedro Víctor sombra", "Pedro Víctor luz", "Pedro Víctor apaixonado", "Pedro Víctor com raiva", "Pedro Víctor feliz",
  "Pedro Víctor babando", "Pedro Víctor Voldemort", "Pedro Víctor Salsicha", "Pedro Víctor Scooby-Doo", "Pedro Víctor + Marília",
  "Pedro Víctor Trox", "Pedro Víctor Mamutinho", "Pedro Víctor dedo enroscado", "Pedro Víctor Fantominho", "Pedro Víctor"
];

const uncommonIds = new Set([7, 9, 16, 25, 28, 31, 32, 33, 34, 36, 37, 39, 40, 42, 47, 55, 58, 66, 68, 75, 77, 78, 79, 80, 81, 83]);
const rareIds = new Set([10, 20, 21, 22, 23, 41, 43, 48, 53, 62, 63, 64, 70, 71, 72, 73, 74, 76, 86, 87, 94]);
const epicIds = new Set([1, 11, 17, 18, 19, 24, 26, 27, 49, 60, 61, 84, 85, 88]);
const mythicIds = new Set([13, 38, 54, 69, 95, 96, 97]);
const legendaryIds = new Set([4, 67, 102, 109]);
const secretIds = new Set([5, 12, 110]);
const rarityFor = id => secretIds.has(id) ? "secret" : legendaryIds.has(id) ? "legendary" : mythicIds.has(id) ? "mythic" : epicIds.has(id) ? "epic" : rareIds.has(id) ? "rare" : uncommonIds.has(id) ? "uncommon" : "common";
const packThemes = [
  { id: "animatronics", name: "Animatronics", icon: "🤖", color: "#ff775f", description: "Freddy, Chica, Foxy, Bonnie e companhia.", cardIds: [8,9,10,11,12,13,14,69] },
  { id: "food", name: "Comidas & bebidas", icon: "🧃", color: "#ffd66b", description: "Suco de Caju, arroz, feijão e outras delícias.", cardIds: [4,5,6,7,35,55,65,66,68,103,104] },
  { id: "heroes", name: "Heróis & vilões", icon: "🦸", color: "#53b8ff", description: "Heróis, vilões e uniformes lendários.", cardIds: [17,18,19,20,21,22,23,24,53] },
  { id: "games", name: "Anime & games", icon: "🎮", color: "#b277ff", description: "Anime, jogos e personagens de outros universos.", cardIds: [26,27,38,39,45,48,54,60,61,62,63,64,84,85,86,87,88,95] },
  { id: "folklore", name: "Folclore & magia", icon: "🪄", color: "#5fe0a1", description: "Lendas brasileiras, magia e criaturas misteriosas.", cardIds: [49,67,71,72,73,74,75,76,102,109] },
  { id: "routine", name: "Profissões & rotina", icon: "🛠️", color: "#54ddff", description: "Trabalhos, estudos, veículos e vida cotidiana.", cardIds: [15,25,30,31,34,43,47,52,70,82,83,89,90,91] },
  { id: "special", name: "Estilos & especiais", icon: "✨", color: "#ff6eb5", description: "Amigos, emoções, estilos e versões inesperadas.", cardIds: [1,2,3,16,28,29,32,33,36,37,40,41,42,44,46,50,51,56,57,58,59,77,78,79,80,81,92,93,94,96,97,98,99,100,101,105,106,107,108,110] }
];
const icons = ["🐺", "🎨", "6️⃣", "🧃", "🥤", "🍛", "🍚", "🐻", "🐤", "🦊", "🐰", "🎭", "🤖", "🩰", "📐", "🌈", "🦇", "⚔️", "🦸", "⚡", "🃏", "♦️", "🎲", "💚", "🌙", "🎣", "🚗", "🤝", "😎", "🍳", "👮", "🦜", "🩴", "⌚", "🥩", "🎤", "🐴", "🟣", "🎮", "🎬", "💘", "🤡", "⚽", "🔊", "🕹️", "🍔", "🏋️", "⛏️", "🧙", "🧒", "👸", "👴", "💗", "🔥", "🧽", "👨", "✨", "🌵", "💰", "🌊", "🐉", "🏰", "👦", "🧪", "🦑", "⭐", "⚡", "🍓", "🐇", "🏍️", "👣", "🐊", "🧜", "🧢", "🔥", "🌳", "💇", "😎", "🖤", "🎨", "🧔", "🚌", "🚍", "🎙️", "👁️", "🍥", "🌸", "🥷", "📚", "🔧", "💻", "🕴️", "💎", "👶", "⛓️", "🌑", "☀️", "😍", "😡", "😁", "🤤", "🪄", "🥪", "🐕", "💞", "🤪", "🦣", "☝️", "👻", "❓"];
const cards = cardNames.map((name, index) => ({
  id: index + 1,
  name,
  rarity: rarityFor(index + 1),
  icon: icons[index],
  image: `/stickers/cards/${String(index + 1).padStart(3, "0")}.jpg`,
  description: `Uma versão única de Pedro Víctor para a coleção. ${rarityFor(index + 1) === "secret" ? "Esta figurinha secreta só aparece depois de ser descoberta." : "Encontre-a abrindo pacotes e cumprindo missões."}`
}));

const juiceRewards = { common: 2, uncommon: 4, rare: 7, epic: 12, mythic: 20, legendary: 35, secret: 60 };
const missions = [
  { id: "daily_pack", icon: "🎁", title: "Explorador diário", description: "Abra o pacote grátis do dia.", reward: "Pacote + 5 🧃" },
  { id: "memory", icon: "🧠", title: "Memória cósmica", description: "Encontre seis pares em 40 segundos e com no máximo 12 erros.", reward: "+8 🧃" },
  { id: "quiz", icon: "❓", title: "Quiz do Pedro", description: "Acerte três perguntas seguidas. Um erro encerra a rodada.", reward: "+6 🧃" },
  { id: "caju", icon: "🧃", title: "Caça ao caju", description: "Pegue dez cajus móveis em apenas 12 segundos.", reward: "+10 🧃" },
  { id: "rarity", icon: "💎", title: "Mestre das raridades", description: "Identifique a raridade de cinco figurinhas. Dois erros encerram a rodada.", reward: "+7 🧃" },
  { id: "sequence", icon: "👁️", title: "Sequência secreta", description: "Memorize cinco figurinhas e repita a ordem sem errar.", reward: "+9 🧃" },
  { id: "order", icon: "🔢", title: "Ordem relâmpago", description: "Toque em oito figurinhas, do menor número ao maior, em 14 segundos.", reward: "+11 🧃" }
];
const state = { owned: {}, juice: 0, lastOpened: null, packs: 0, activities: {}, activityDate: null };
let currentFilter = "all", currentRarity = "all", registerMode = false, dailyAvailable = false, gameTimer = null, targetTimer = null;
let currentUser = null, socialProfile = null, friends = [], friendships = [], trades = [], currentDetailCard = null, friendOwned = {}, postPendingDelete = null;
const byId = id => document.getElementById(id);
const rarity = id => rarities.find(r => r.id === id);
const todayKey = () => new Intl.DateTimeFormat("en-CA", { timeZone: "America/Fortaleza" }).format(new Date());

function stats() {
  const unique = Object.keys(state.owned).filter(k => state.owned[k] > 0 && Number(k) <= TOTAL_CARDS).length;
  const total = Object.entries(state.owned).filter(([k]) => Number(k) <= TOTAL_CARDS).reduce((sum, [, count]) => sum + count, 0);
  return { unique, dupes: Math.max(0, total - unique), percent: Math.round((unique / TOTAL_CARDS) * 100) };
}
function renderStats() {
  const s = stats();
  byId("ownedCount").textContent = s.unique; byId("percentStat").textContent = `${s.percent}%`; byId("dupeStat").textContent = s.dupes; byId("juiceBalance").textContent = state.juice; byId("buyMystery").disabled = state.juice < 30;
  document.querySelectorAll("[data-buy-theme]").forEach(button => button.disabled = state.juice < 40);
  document.querySelector(".progress-fill").style.width = `${s.percent}%`; document.querySelector(".progress-track").setAttribute("aria-valuenow", s.unique);
  byId("collectionCopy").textContent = s.unique === TOTAL_CARDS ? "Coleção completa. Você conquistou todas as versões!" : `${TOTAL_CARDS - s.unique} descobertas faltam — as secretas só aparecem depois de encontradas.`;
}
function renderAlbum() {
  const grid = byId("albumGrid");
  const filtered = cards.filter(card => { const owned = Boolean(state.owned[card.id]); if (card.rarity === "secret" && !owned) return false; return (currentFilter === "all" || (currentFilter === "owned" && owned) || (currentFilter === "missing" && !owned)) && (currentRarity === "all" || card.rarity === currentRarity); });
  grid.innerHTML = filtered.length ? "" : '<div class="empty">Nenhuma figurinha combina com este filtro. As secretas só surgem quando descobertas.</div>';
  filtered.forEach(card => { const r = rarity(card.rarity), owned = Boolean(state.owned[card.id]), button = document.createElement("button"); button.className = `sticker rarity-${card.rarity} ${owned ? "" : "locked"}`; button.style.setProperty("--rarity", r.color); button.innerHTML = `<span class="sticker-badge">${r.name}</span>${state.owned[card.id] > 1 ? `<span class="dupe">+${state.owned[card.id] - 1}</span>` : ""}<img class="sticker-visual sticker-photo" src="${card.image}" alt="" loading="lazy" decoding="async"><span class="sticker-info"><span class="sticker-name">${owned ? card.name : "Figurinha oculta"}</span><span class="sticker-rarity">${r.name}</span></span>`; button.disabled = !owned; button.setAttribute("aria-label", owned ? `${card.name}, ${r.name}` : `Figurinha ${card.id} ainda não encontrada`); if (owned) button.onclick = () => showDetail(card); grid.appendChild(button); });
}
function renderOdds() {
  const rows = (metric, max, formatter) => rarities.map(r => `<div class="prob-row"><span class="rarity-key"><i class="dot" style="--c:${r.color}"></i>${r.name}</span><span class="bar"><i style="--c:${r.color};--w:${(r[metric] / max) * 100}%"></i></span><b>${formatter(r[metric])}</b></div>`).join("");
  byId("packOdds").innerHTML = rows("packChance", 65, value => `${value}%`); byId("stickerOdds").innerHTML = rows("count", 35, String);
  byId("packRules").innerHTML = rarities.map(r => `<tr><td><span class="rarity-key"><i class="dot" style="--c:${r.color}"></i>${r.name}</span></td><td>${r.size} figurinhas</td><td>${r.guarantee}</td><td><strong>+${juiceRewards[r.id]} 🧃</strong></td></tr>`).join("");
  byId("rarityFilter").innerHTML = '<option value="all">Toda raridade</option>' + rarities.filter(r => r.id !== "secret" || cards.some(card => card.rarity === "secret" && state.owned[card.id])).map(r => `<option value="${r.id}">${r.name}</option>`).join("");
}
function missionDone(id) { return id === "daily_pack" ? !dailyAvailable : state.activityDate === todayKey() && Boolean(state.activities?.[id]); }
function renderMissions() {
  const completed = missions.filter(mission => missionDone(mission.id)).length;
  byId("missionSummary").textContent = `${completed} / ${missions.length} concluídas`; byId("missionProgress").style.setProperty("--w", `${(completed / missions.length) * 100}%`);
  byId("missionGrid").innerHTML = missions.map(mission => { const done = missionDone(mission.id), action = mission.id === "daily_pack" ? "Ir para o pacote" : "Jogar agora"; return `<article class="mission-card ${done ? "done" : ""}"><div class="mission-icon">${mission.icon}</div><h3>${mission.title}</h3><p>${mission.description}</p><div class="mission-reward">${mission.reward}</div><button class="${done ? "ghost" : "primary"}" data-mission="${mission.id}" ${done ? "disabled" : ""}>${done ? "✓ Concluída" : action}</button></article>`; }).join("");
  document.querySelectorAll("[data-mission]").forEach(button => button.onclick = () => { const id = button.dataset.mission; if (id === "daily_pack") setActiveView("album"); else startGame(id); });
}
function updateDaily() { const button = byId("openPack"); button.disabled = !dailyAvailable; button.textContent = dailyAvailable ? "Abrir pacote grátis" : "Pacote de hoje aberto"; byId("packMessage").textContent = dailyAvailable ? "Um pacote está esperando por você." : "Volte amanhã para uma nova surpresa."; byId("countdown").textContent = dailyAvailable ? "Disponível agora" : "Novo pacote à meia-noite"; }
function renderAll() { renderStats(); renderAlbum(); updateDaily(); renderMissions(); renderOwnedOptions(); }
function openModal(id) { byId(id).classList.add("open"); byId(id).querySelector(".close").focus(); document.body.style.overflow = "hidden"; }
function closeModal(id) { if (id === "gameModal") { if (gameTimer) clearInterval(gameTimer); if (targetTimer) clearInterval(targetTimer); } if (id === "deletePostModal") postPendingDelete = null; gameTimer = null; targetTimer = null; byId(id).classList.remove("open"); document.body.style.overflow = ""; }
function showDetail(card) { currentDetailCard = card; const r = rarity(card.rarity), icon = byId("detailIcon"); icon.className = `detail-icon rarity-${card.rarity}`; icon.style.setProperty("--rarity", r.color); icon.innerHTML = `<img src="${card.image}" alt="${card.name}">`; byId("detailRarity").textContent = `#${String(card.id).padStart(3, "0")} · ${r.name}`; byId("detailRarity").style.color = r.color; byId("detailTitle").textContent = card.name; byId("detailText").textContent = card.description + (state.owned[card.id] > 1 ? ` Você possui ${state.owned[card.id]} cópias.` : ""); openModal("detailModal"); }
function burst() { const box = byId("confetti"), colors = rarities.map(r => r.color); box.innerHTML = ""; for (let i = 0; i < 42; i++) { const piece = document.createElement("i"); piece.style.cssText = `left:${Math.random() * 100}%;--x:${(Math.random() - .5) * 300}px;--c:${colors[i % colors.length]};animation-delay:${Math.random() * .4}s`; box.appendChild(piece); } setTimeout(() => box.innerHTML = "", 2500); }
function showPack(data, source) {
  const payload = typeof data === "string" ? JSON.parse(data) : data; Object.assign(state, payload.state); dailyAvailable = payload.daily_available;
  const tier = rarities.findIndex(r => r.id === payload.pack_tier), entries = payload.entries.map(entry => ({ card: cards.find(card => card.id === entry.id), isNew: entry.is_new })).filter(entry => entry.card), newCount = entries.filter(entry => entry.isNew).length;
  const revealModal = byId("revealModal"); revealModal.className = `modal tier-${payload.pack_tier}`; revealModal.style.setProperty("--pack-color", rarities[tier].color);
  byId("revealTier").textContent = source === "theme" ? `Pacote temático · ${payload.pack_rarity}` : `${source === "mystery" ? "Pacote misterioso revelou: " : ""}Pacote ${payload.pack_rarity}`; byId("revealTier").style.color = rarities[tier].color; byId("revealSummary").textContent = `${newCount ? `${newCount} ${newCount === 1 ? "nova figurinha" : "novas figurinhas"}` : "Somente repetidas"}${payload.reward ? ` · +${payload.reward} 🧃` : ""}`; byId("revealGrid").innerHTML = "";
  entries.forEach(({ card, isNew }, index) => { const r = rarity(card.rarity), element = document.createElement("div"); element.className = `reveal-card rarity-${card.rarity}${isNew ? " is-new" : ""}`; element.style.cssText = `--rarity:${r.color};animation-delay:${index * .08}s`; element.innerHTML = `<img class="reveal-image" src="${card.image}" alt="${card.name}"><div class="reveal-info"><b>${card.name}</b><small>${r.name}</small>${isNew ? '<div class="new-tag">NOVA</div>' : ""}</div>`; byId("revealGrid").appendChild(element); });
  openModal("revealModal"); if (tier >= 4 || newCount >= 3) burst(); renderOdds(); renderAll(); return payload;
}
async function openPack(source) { const panel = document.querySelector(".pack-panel"); if (source === "daily") panel?.classList.add("opening"); try { const { data, error } = await supabase.rpc("open_album_pack", { p_source: source }); if (error) throw error; return showPack(data, source); } finally { panel?.classList.remove("opening"); } }
async function openDaily() { if (!dailyAvailable) return; byId("openPack").disabled = true; try { return await openPack("daily"); } catch (error) { alert(error.message); updateDaily(); } }
async function buyMystery() { if (state.juice < 30) return; byId("buyMystery").disabled = true; try { return await openPack("mystery"); } catch (error) { alert(error.message); renderStats(); } }
async function buyTheme(themeId) { if (state.juice < 40) return; const button = document.querySelector(`[data-buy-theme="${themeId}"]`); button.disabled = true; try { const { data, error } = await supabase.rpc("open_themed_album_pack", { p_theme: themeId }); if (error) throw error; return showPack(data, "theme"); } catch (error) { alert(error.message); renderStats(); } }
function renderThemePacks() {
  byId("themePackGrid").innerHTML = packThemes.map(theme => { const previews = theme.cardIds.filter(id => rarityFor(id) !== "secret").slice(0, 3); return `<article class="theme-pack" style="--theme:${theme.color}"><div class="theme-pack-head"><span>${theme.icon}</span><div><h3>Pedro Víctor ${theme.name}</h3><small>${theme.cardIds.length} figurinhas possíveis</small></div></div><div class="theme-preview">${previews.map(id => `<img src="/stickers/cards/${String(id).padStart(3, "0")}.jpg" alt="" loading="lazy">`).join("")}</div><p>${theme.description}</p><button class="primary" type="button" data-buy-theme="${theme.id}">Abrir pacote temático<span class="cost">40 🧃 · 5 figurinhas</span></button></article>`; }).join("");
  document.querySelectorAll("[data-buy-theme]").forEach(button => button.onclick = () => buyTheme(button.dataset.buyTheme));
}
async function completeActivity(id, score) {
  const { data, error } = await supabase.rpc("complete_daily_activity", { p_activity: id, p_score: score }); if (error) throw error;
  state.juice = data.coins; state.activities = data.activities || {}; state.activityDate = data.activity_date; renderStats(); renderMissions(); burst();
  byId("gameContent").innerHTML = `<p class="reward-toast">Missão concluída! +${data.reward} 🧃 Suco de Caju</p><button class="primary" data-close-game style="display:block;margin:22px auto 0">Voltar às missões</button>`; byId("gameContent").querySelector("[data-close-game]").onclick = () => closeModal("gameModal");
}
const escapeHtml = value => String(value || "").replace(/[&<>"']/g, char => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[char]));
function setActiveView(view, updateHash = true) {
  const validView = ["album", "social", "trades", "missions"].includes(view) ? view : "album";
  document.querySelectorAll("[data-view-panel]").forEach(panel => panel.classList.toggle("view-hidden", panel.dataset.viewPanel !== validView));
  document.querySelectorAll("[data-jump]").forEach(button => { const active = button.dataset.jump === validView; button.classList.toggle("active", active); button.setAttribute("aria-selected", String(active)); });
  if (updateHash) history.replaceState(null, "", `#${validView}`);
  window.scrollTo({ top: 0, behavior: "smooth" });
}
const ownedCards = () => cards.filter(card => (state.owned[card.id] || 0) > 0);
const optionForCard = (card, withCount = false) => `<option value="${card.id}">#${String(card.id).padStart(3, "0")} · ${escapeHtml(card.name)}${withCount ? ` (${state.owned[card.id]}x)` : ""}</option>`;
function renderOwnedOptions() {
  const owned = ownedCards();
  if (byId("postCard").value && !state.owned[byId("postCard").value]) byId("postCard").value = "";
  updatePostPickerTrigger();
  if (byId("offeredCard").value && !state.owned[byId("offeredCard").value]) byId("offeredCard").value = "";
  updateTradePickerTrigger("offered");
}
function updatePostPickerTrigger() {
  const input = byId("postCard"), button = byId("postPickerButton"), card = cards.find(item => item.id === Number(input.value)), available = ownedCards().length > 0;
  button.disabled = !available; button.classList.remove("selected");
  if (!available) { button.textContent = "Abra um pacote primeiro"; return; }
  if (!card || !state.owned[card.id]) { input.value = ""; button.textContent = "Escolher figurinha"; return; }
  const r = rarity(card.rarity); button.classList.add("selected"); button.style.setProperty("--rarity", r.color); button.innerHTML = `<img src="${card.image}" alt=""><span><b>#${String(card.id).padStart(3, "0")} · ${escapeHtml(card.name)}</b><small>${r.name} · Você tem ${state.owned[card.id]}x</small></span>`;
}
function tradePickerMeta(type, card) {
  const counterpartCount = type === "offered" ? (friendOwned[card.id] || 0) : (state.owned[card.id] || 0);
  if (type === "offered") return counterpartCount ? `Amigo tem ${counterpartCount}x` : "Amigo não tem";
  return counterpartCount ? `Você tem ${counterpartCount}x` : "Você não tem";
}
function updateTradePickerTrigger(type) {
  const offered = type === "offered", input = byId(offered ? "offeredCard" : "requestedCard"), button = byId(offered ? "offeredPickerButton" : "requestedPickerButton"), friendSelected = Boolean(byId("tradeFriend").value), source = offered ? state.owned : friendOwned, available = cards.some(card => (source[card.id] || 0) > 0), card = cards.find(item => item.id === Number(input.value));
  button.disabled = !friendSelected || !available; button.classList.remove("selected");
  if (!friendSelected) { button.textContent = "Escolha um amigo primeiro"; return; }
  if (!available) { button.textContent = offered ? "Você ainda não tem figurinhas" : "Seu amigo ainda não tem figurinhas"; return; }
  if (!card || !(source[card.id] > 0)) { input.value = ""; button.textContent = offered ? "Escolha a sua figurinha" : "Escolha a figurinha do amigo"; return; }
  const r = rarity(card.rarity); button.classList.add("selected"); button.style.setProperty("--rarity", r.color); button.innerHTML = `<img src="${card.image}" alt=""><span><b>#${String(card.id).padStart(3, "0")} · ${escapeHtml(card.name)}</b><small>${r.name} · ${tradePickerMeta(type, card)}</small></span>`;
}
function openStickerPicker(type) {
  const post = type === "post", offered = type === "offered", source = post || offered ? state.owned : friendOwned, available = cards.filter(card => (source[card.id] || 0) > 0);
  if ((!post && !byId("tradeFriend").value) || !available.length) return;
  byId("tradePickerTitle").textContent = post ? "Qual figurinha você quer publicar?" : offered ? "Qual figurinha você oferece?" : "Qual figurinha você quer receber?";
  byId("tradePickerHelp").textContent = post ? "Escolha uma figurinha da sua coleção para mostrar no Feed." : offered ? "Veja se seu amigo já possui cada opção antes de escolher." : "As opções abaixo pertencem ao seu amigo. Destacamos as que ainda faltam no seu álbum.";
  byId("tradePickerGrid").innerHTML = available.map(card => { const r = rarity(card.rarity), counterpartCount = post ? state.owned[card.id] : offered ? (friendOwned[card.id] || 0) : (state.owned[card.id] || 0), status = post ? `Você tem ${state.owned[card.id]}x` : tradePickerMeta(type, card); return `<button class="trade-picker-option" type="button" data-pick-card="${card.id}" style="--rarity:${r.color}" aria-label="#${String(card.id).padStart(3, "0")} ${escapeHtml(card.name)}, ${r.name}, ${status}"><img src="${card.image}" alt=""><span><b>#${String(card.id).padStart(3, "0")} · ${escapeHtml(card.name)}</b><small>${r.name} · ${source[card.id]}x</small><span class="ownership-tag ${counterpartCount ? "" : "missing"}">${status}</span></span></button>`; }).join("");
  byId("tradePickerGrid").querySelectorAll("[data-pick-card]").forEach(button => button.onclick = () => { byId(post ? "postCard" : offered ? "offeredCard" : "requestedCard").value = button.dataset.pickCard; if (post) updatePostPickerTrigger(); else updateTradePickerTrigger(type); closeModal("tradePickerModal"); });
  openModal("tradePickerModal");
}
function renderSocialProfile() {
  if (!socialProfile) return;
  byId("socialName").textContent = socialProfile.display_name;
  byId("socialHandle").textContent = `@${socialProfile.handle}`;
  const featured = cards.find(card => card.id === socialProfile.featured_card);
  byId("featuredImage").src = featured?.image || ownedCards()[0]?.image || cards[0].image;
  byId("featuredImage").style.opacity = featured ? "1" : ".35";
  byId("featuredName").textContent = featured ? featured.name : "Escolha uma figurinha em destaque";
}
function friendFrom(row) { return row.requester_id === currentUser.id ? row.addressee : row.requester; }
function renderFriends() {
  const selectedFriend = byId("tradeFriend").value;
  const accepted = friendships.filter(row => row.status === "accepted");
  friends = accepted.map(friendFrom).filter(Boolean);
  byId("friendList").innerHTML = friends.length ? friends.map(friend => `<div class="friend-row"><div><b>${escapeHtml(friend.display_name)}</b><small>@${escapeHtml(friend.handle)}</small></div><button class="ghost" data-trade-friend="${friend.user_id}">Trocar</button></div>`).join("") : '<div class="empty-small">Adicione alguém pelo @ para começar.</div>';
  const incoming = friendships.filter(row => row.status === "pending" && row.addressee_id === currentUser.id);
  const outgoing = friendships.filter(row => row.status === "pending" && row.requester_id === currentUser.id);
  byId("requestList").innerHTML = incoming.map(row => `<div class="friend-row"><div><b>${escapeHtml(row.requester.display_name)}</b><small>@${escapeHtml(row.requester.handle)}</small></div><div class="row-actions"><button class="primary" data-friend-response="${row.id}" data-accept="true">Aceitar</button><button class="ghost" data-friend-response="${row.id}" data-accept="false">Recusar</button></div></div>`).join("") + outgoing.map(row => `<div class="friend-row"><div><b>${escapeHtml(row.addressee.display_name)}</b><small>Pedido enviado</small></div></div>`).join("") || '<div class="empty-small">Nenhum pedido pendente.</div>';
  byId("tradeFriend").innerHTML = '<option value="">Escolha um amigo</option>' + friends.map(friend => `<option value="${friend.user_id}">${escapeHtml(friend.display_name)} · @${escapeHtml(friend.handle)}</option>`).join("");
  if (friends.some(friend => friend.user_id === selectedFriend)) byId("tradeFriend").value = selectedFriend;
  document.querySelectorAll("[data-friend-response]").forEach(button => button.onclick = () => respondFriend(Number(button.dataset.friendResponse), button.dataset.accept === "true"));
  document.querySelectorAll("[data-trade-friend]").forEach(button => button.onclick = () => { byId("tradeFriend").value = button.dataset.tradeFriend; byId("tradeFriend").dispatchEvent(new Event("change")); setActiveView("trades"); });
}
function renderFeed(posts) {
  byId("feedList").innerHTML = posts.length ? posts.map(post => { const card = cards.find(item => item.id === post.card_id), r = rarity(card.rarity), ownPost = post.user_id === currentUser.id; return `<article class="feed-post" style="--post-color:${r.color}"><img src="${card.image}" alt="${escapeHtml(card.name)}"><div><div class="post-head"><div class="post-meta"><b>${escapeHtml(post.author.display_name)}</b> · @${escapeHtml(post.author.handle)} · ${new Date(post.created_at).toLocaleDateString("pt-BR")}</div>${ownPost ? `<button class="post-delete" type="button" data-delete-post="${post.id}" aria-label="Excluir esta publicação">Excluir</button>` : ""}</div><p class="post-caption">${escapeHtml(post.caption) || "Compartilhou uma nova favorita."}</p><div class="post-card-name">#${String(card.id).padStart(3, "0")} · ${escapeHtml(card.name)} · ${r.name}</div></div></article>`; }).join("") : '<div class="empty-small">O feed está vazio. Publique uma figurinha ou adicione amigos.</div>';
  document.querySelectorAll("[data-delete-post]").forEach(button => button.onclick = () => { postPendingDelete = Number(button.dataset.deletePost); openModal("deletePostModal"); });
}
function tradeParty(trade) { return trade.proposer_id === currentUser.id ? trade.recipient : trade.proposer; }
function renderTrades() {
  const pending = trades.filter(trade => trade.status === "pending");
  byId("tradeList").innerHTML = pending.length ? pending.map(trade => { const offered = cards.find(card => card.id === trade.offered_card_id), requested = cards.find(card => card.id === trade.requested_card_id), other = tradeParty(trade), incoming = trade.recipient_id === currentUser.id; return `<div class="trade-row"><img src="${offered.image}" alt="${escapeHtml(offered.name)}"><div><b>#${String(offered.id).padStart(3, "0")} · ${escapeHtml(offered.name)}</b><small>${incoming ? `${escapeHtml(other.display_name)} oferece` : "Você oferece"} · ${rarity(offered.rarity).name}</small></div><b>↔</b><img src="${requested.image}" alt="${escapeHtml(requested.name)}"><div><b>#${String(requested.id).padStart(3, "0")} · ${escapeHtml(requested.name)}</b><small>${incoming ? "Em troca da sua" : `De ${escapeHtml(other.display_name)}`} · ${rarity(requested.rarity).name}</small></div><div class="row-actions">${incoming ? `<button class="primary" data-trade-response="${trade.id}" data-accept="true">Aceitar</button><button class="ghost" data-trade-response="${trade.id}" data-accept="false">Recusar</button>` : `<button class="ghost" data-trade-cancel="${trade.id}">Cancelar</button>`}</div></div>`; }).join("") : '<div class="empty-small">Nenhuma troca pendente.</div>';
  document.querySelectorAll("[data-trade-response]").forEach(button => button.onclick = () => respondTrade(Number(button.dataset.tradeResponse), button.dataset.accept === "true"));
  document.querySelectorAll("[data-trade-cancel]").forEach(button => button.onclick = () => cancelTrade(Number(button.dataset.tradeCancel)));
}
async function refreshSocial() {
  const profileQuery = supabase.from("social_profiles").select("user_id,handle,display_name,featured_card").eq("user_id", currentUser.id).single();
  const friendshipQuery = supabase.from("friendships").select("id,requester_id,addressee_id,status,requester:social_profiles!friendships_requester_id_fkey(user_id,handle,display_name,featured_card),addressee:social_profiles!friendships_addressee_id_fkey(user_id,handle,display_name,featured_card)").order("created_at", { ascending: false });
  const feedQuery = supabase.from("feed_posts").select("id,user_id,card_id,caption,created_at,author:social_profiles!feed_posts_user_id_fkey(user_id,handle,display_name)").order("created_at", { ascending: false }).limit(40);
  const tradeQuery = supabase.from("sticker_trades").select("id,proposer_id,recipient_id,offered_card_id,requested_card_id,status,created_at,proposer:social_profiles!sticker_trades_proposer_id_fkey(user_id,handle,display_name),recipient:social_profiles!sticker_trades_recipient_id_fkey(user_id,handle,display_name)").order("created_at", { ascending: false }).limit(50);
  const [profileResult, friendshipResult, feedResult, tradeResult] = await Promise.all([profileQuery, friendshipQuery, feedQuery, tradeQuery]);
  for (const result of [profileResult, friendshipResult, feedResult, tradeResult]) if (result.error) throw result.error;
  socialProfile = profileResult.data; friendships = friendshipResult.data || []; trades = tradeResult.data || [];
  renderSocialProfile(); renderFriends(); renderFeed(feedResult.data || []); renderTrades(); renderOwnedOptions();
}
async function publishSticker(cardId, caption = "") { const { error } = await supabase.rpc("publish_sticker", { p_card_id: Number(cardId), p_caption: caption }); if (error) throw error; await refreshSocial(); }
async function deleteOwnPost() {
  if (!postPendingDelete || !currentUser) return;
  const postId = postPendingDelete, button = byId("confirmDeletePost"); button.disabled = true; button.textContent = "Excluindo…";
  try { const { error } = await supabase.from("feed_posts").delete().eq("id", postId).eq("user_id", currentUser.id); if (error) throw error; closeModal("deletePostModal"); await refreshSocial(); }
  catch (error) { alert(error.message); }
  finally { button.disabled = false; button.textContent = "Excluir publicação"; }
}
async function featureSticker(cardId) { const { error } = await supabase.rpc("set_featured_sticker", { p_card_id: Number(cardId) }); if (error) throw error; await refreshSocial(); }
async function respondFriend(id, accept) { const { error } = await supabase.rpc("respond_friend_request", { p_friendship_id: id, p_accept: accept }); if (error) return alert(error.message); await refreshSocial(); }
async function respondTrade(id, accept) { const { error } = await supabase.rpc("respond_sticker_trade", { p_trade_id: id, p_accept: accept }); if (error) return alert(error.message); await loadProfile(currentUser); }
async function cancelTrade(id) { const { error } = await supabase.rpc("cancel_sticker_trade", { p_trade_id: id }); if (error) return alert(error.message); await refreshSocial(); }
function gameLoss(message, retry) { if (gameTimer) clearInterval(gameTimer); if (targetTimer) clearInterval(targetTimer); gameTimer = null; targetTimer = null; byId("gameContent").innerHTML = `<div class="game-loss"><h3>Rodada perdida</h3><p>${message}</p><button class="primary" data-retry>Tentar novamente</button></div>`; byId("gameContent").querySelector("[data-retry]").onclick = retry; }
function startMemory() {
  const memoryCards = cards.filter(card => card.rarity !== "secret").sort(() => Math.random() - .5).slice(0, 6), deck = [...memoryCards, ...memoryCards].sort(() => Math.random() - .5); let first = null, lock = false, matches = 0, misses = 0, seconds = 40, finished = false;
  byId("gameContent").innerHTML = '<p class="game-copy">Encontre os seis pares antes do tempo acabar. Você perde com 12 erros.</p><div class="game-hud"><span id="memoryTime">⏱ 40s</span><span id="memoryMisses">Erros: 0/12</span></div><div class="memory-grid"></div><div class="game-status">0 / 6 pares</div>';
  const grid = byId("gameContent").querySelector(".memory-grid"), status = byId("gameContent").querySelector(".game-status");
  const lose = message => { if (finished) return; finished = true; gameLoss(message, startMemory); };
  gameTimer = setInterval(() => { seconds--; const clock = byId("memoryTime"); if (clock) clock.textContent = `⏱ ${seconds}s`; if (seconds <= 0) lose("O tempo acabou antes de você encontrar os seis pares."); }, 1000);
  deck.forEach(card => { const r = rarity(card.rarity), button = document.createElement("button"); button.className = `memory-card rarity-${card.rarity}`; button.dataset.cardId = card.id; button.style.setProperty("--rarity", r.color); button.setAttribute("aria-label", "Carta virada"); button.innerHTML = `<span class="memory-back" aria-hidden="true">PV</span><span class="memory-face"><img src="${card.image}" alt=""><small>${r.name}</small></span>`; button.onclick = () => { if (finished || lock || button.classList.contains("matched") || button === first) return; button.classList.add("open"); button.setAttribute("aria-label", `${card.name}, ${r.name}`); if (!first) { first = button; return; } if (first.dataset.cardId === button.dataset.cardId) { first.classList.add("matched"); button.classList.add("matched"); first = null; matches++; status.textContent = `${matches} / 6 pares`; if (matches === 6) { finished = true; clearInterval(gameTimer); gameTimer = null; completeActivity("memory", 6).catch(error => alert(error.message)); } } else { misses++; const missCopy = byId("memoryMisses"); if (missCopy) missCopy.textContent = `Erros: ${misses}/12`; if (misses >= 12) return lose("Você atingiu o limite de 12 erros."); lock = true; const previous = first; first = null; setTimeout(() => { previous.classList.remove("open"); previous.setAttribute("aria-label", "Carta virada"); button.classList.remove("open"); button.setAttribute("aria-label", "Carta virada"); lock = false; }, 620); } }; grid.appendChild(button); });
}
const quizQuestions = [
  { question: "Qual é a moeda do jogo?", options: ["Suco de Caju", "Moeda Lunar", "Arroz e Feijão"], answer: 0 },
  { question: "Quantas figurinhas existem no álbum?", options: ["100", "110", "120"], answer: 1 },
  { question: "Qual raridade fica escondida no catálogo?", options: ["Rara", "Lendária", "Secreta"], answer: 2 },
  { question: "Quanto custa um pacote misterioso?", options: ["10 🧃", "30 🧃", "60 🧃"], answer: 1 },
  { question: "Quantas figurinhas vêm em um pacote secreto?", options: ["7", "10", "12"], answer: 1 },
  { question: "Qual pacote garante uma lendária e uma secreta?", options: ["Mítico", "Lendário", "Secreto"], answer: 2 }
];
function startQuiz() {
  const seed = [...todayKey()].reduce((sum, char) => sum + char.charCodeAt(0), 0), selected = [0, 1, 2].map(offset => quizQuestions[(seed + offset * 2) % quizQuestions.length]); let round = 0;
  const showQuestion = () => { const quiz = selected[round]; byId("gameContent").innerHTML = `<div class="game-hud"><span>Pergunta ${round + 1}/3</span><span>❤️ Uma vida</span></div><p class="game-copy">${quiz.question}</p><div class="quiz-options">${quiz.options.map((option, index) => `<button class="ghost" data-answer="${index}">${option}</button>`).join("")}</div><div class="game-status">Acerte as três sem errar.</div>`; byId("gameContent").querySelectorAll("[data-answer]").forEach(button => button.onclick = () => { if (Number(button.dataset.answer) !== quiz.answer) return gameLoss("Uma resposta errada encerra o desafio de hoje.", startQuiz); round++; if (round === 3) completeActivity("quiz", 3).catch(error => alert(error.message)); else showQuestion(); }); };
  showQuestion();
}
function startCaju() {
  let caught = 0, seconds = 12, finished = false; byId("gameContent").innerHTML = '<p class="game-copy">O caju muda de lugar sozinho. Pegue dez antes do tempo acabar.</p><div class="game-status">10 faltando · 12s</div><div class="caju-arena"><button class="caju-target" aria-label="Pegar Suco de Caju">🧃</button></div>';
  const target = byId("gameContent").querySelector(".caju-target"), status = byId("gameContent").querySelector(".game-status"), move = () => { if (finished) return; target.style.left = `${Math.random() * 88 + 2}%`; target.style.top = `${Math.random() * 80 + 3}%`; };
  target.onclick = () => { if (finished) return; caught++; status.textContent = `${10 - caught} faltando · ${seconds}s`; if (caught >= 10) { finished = true; clearInterval(gameTimer); clearInterval(targetTimer); gameTimer = null; targetTimer = null; target.disabled = true; completeActivity("caju", 10).catch(error => alert(error.message)); } else move(); }; move();
  targetTimer = setInterval(move, 650);
  gameTimer = setInterval(() => { seconds--; status.textContent = `${10 - caught} faltando · ${seconds}s`; if (seconds <= 0) { finished = true; gameLoss(`Você pegou ${caught} de 10 cajus.`, startCaju); } }, 1000);
}
function startRarityChallenge() {
  const challengeCards = [...cards.filter(card => card.rarity !== "secret")].sort(() => Math.random() - .5).slice(0, 5); let round = 0, correct = 0, lives = 2;
  const showRound = () => {
    const card = challengeCards[round], correctRarity = rarity(card.rarity), alternatives = [...rarities.filter(item => item.id !== "secret" && item.id !== card.rarity)].sort(() => Math.random() - .5).slice(0, 2), options = [correctRarity, ...alternatives].sort(() => Math.random() - .5);
    byId("gameContent").innerHTML = `<div class="game-hud"><span>Figurinha ${round + 1}/5</span><span>❤️ ${lives} ${lives === 1 ? "vida" : "vidas"}</span></div><div class="rarity-challenge"><img src="${card.image}" alt="${escapeHtml(card.name)}"><b>#${String(card.id).padStart(3, "0")} · ${escapeHtml(card.name)}</b></div><p class="game-copy">Qual é a raridade desta figurinha?</p><div class="quiz-options">${options.map(option => `<button class="ghost" data-rarity-answer="${option.id}" style="--answer-color:${option.color}">${option.name}</button>`).join("")}</div><div class="game-status">Acertos: ${correct}/5</div>`;
    byId("gameContent").querySelectorAll("[data-rarity-answer]").forEach(button => button.onclick = () => { if (button.dataset.rarityAnswer === card.rarity) correct++; else lives--; round++; if (!lives) return gameLoss("Você errou duas raridades nesta rodada.", startRarityChallenge); if (round === challengeCards.length) return completeActivity("rarity", correct).catch(error => alert(error.message)); showRound(); });
  };
  showRound();
}
function startSequence() {
  const sequence = [...cards.filter(card => card.rarity !== "secret")].sort(() => Math.random() - .5).slice(0, 5); let previewIndex = 0;
  const showPreview = () => { const card = sequence[previewIndex]; byId("gameContent").innerHTML = `<p class="game-copy">Memorize a ordem. Depois, toque nas cinco figurinhas na mesma sequência.</p><div class="sequence-preview"><span>${previewIndex + 1}/5</span><img src="${card.image}" alt="${escapeHtml(card.name)}"><b>#${String(card.id).padStart(3, "0")} · ${escapeHtml(card.name)}</b></div>`; };
  const showChoices = () => {
    let expected = 0; const shuffled = [...sequence].sort(() => Math.random() - .5);
    byId("gameContent").innerHTML = `<p class="game-copy">Agora repita a ordem sem errar.</p><div class="game-status" id="sequenceStatus">0 / 5 corretas</div><div class="sequence-grid">${shuffled.map(card => `<button type="button" data-sequence-card="${card.id}" aria-label="#${String(card.id).padStart(3, "0")} ${escapeHtml(card.name)}"><img src="${card.image}" alt=""><b>#${String(card.id).padStart(3, "0")}</b></button>`).join("")}</div>`;
    byId("gameContent").querySelectorAll("[data-sequence-card]").forEach(button => button.onclick = () => { if (Number(button.dataset.sequenceCard) !== sequence[expected].id) return gameLoss("A ordem escolhida não corresponde à sequência mostrada.", startSequence); button.disabled = true; button.classList.add("correct"); expected++; byId("sequenceStatus").textContent = `${expected} / 5 corretas`; if (expected === sequence.length) completeActivity("sequence", expected).catch(error => alert(error.message)); });
  };
  showPreview(); gameTimer = setInterval(() => { previewIndex++; if (previewIndex >= sequence.length) { clearInterval(gameTimer); gameTimer = null; showChoices(); } else showPreview(); }, 1050);
}
function startOrderChallenge() {
  const selected = [...cards.filter(card => card.rarity !== "secret")].sort(() => Math.random() - .5).slice(0, 8), ordered = [...selected].sort((a, b) => a.id - b.id), shuffled = [...selected].sort(() => Math.random() - .5); let next = 0, seconds = 14, finished = false;
  byId("gameContent").innerHTML = `<p class="game-copy">Toque do menor número para o maior. Um toque errado encerra a rodada.</p><div class="game-hud"><span id="orderTime">⏱ 14s</span><span id="orderProgress">0/8 corretas</span></div><div class="order-grid">${shuffled.map(card => `<button type="button" data-order-card="${card.id}" aria-label="Figurinha número ${card.id}"><img src="${card.image}" alt=""><b>#${String(card.id).padStart(3, "0")}</b></button>`).join("")}</div>`;
  byId("gameContent").querySelectorAll("[data-order-card]").forEach(button => button.onclick = () => { if (finished) return; if (Number(button.dataset.orderCard) !== ordered[next].id) { finished = true; return gameLoss("Você tocou em uma figurinha fora da ordem crescente.", startOrderChallenge); } button.disabled = true; button.classList.add("correct"); next++; byId("orderProgress").textContent = `${next}/8 corretas`; if (next === ordered.length) { finished = true; clearInterval(gameTimer); gameTimer = null; completeActivity("order", next).catch(error => alert(error.message)); } });
  gameTimer = setInterval(() => { seconds--; const clock = byId("orderTime"); if (clock) clock.textContent = `⏱ ${seconds}s`; if (seconds <= 0 && !finished) { finished = true; gameLoss(`O tempo acabou. Você acertou ${next} de 8.`, startOrderChallenge); } }, 1000);
}
function startGame(id) { if (missionDone(id)) return; byId("gameTitle").textContent = missions.find(mission => mission.id === id)?.title || "Minijogo"; openModal("gameModal"); if (id === "memory") startMemory(); if (id === "quiz") startQuiz(); if (id === "caju") startCaju(); if (id === "rarity") startRarityChallenge(); if (id === "sequence") startSequence(); if (id === "order") startOrderChallenge(); }

async function loadProfile(user) {
  currentUser = user;
  const [{ data: profile, error: profileError }, { data: progress, error: progressError }] = await Promise.all([supabase.from("profiles").select("name,email").eq("id", user.id).single(), supabase.from("album_progress").select("owned,coins,last_daily_pack,packs_opened,daily_activities,daily_activity_date").eq("user_id", user.id).single()]);
  if (profileError) throw profileError; if (progressError) throw progressError;
  state.owned = progress.owned || {}; state.juice = progress.coins || 0; state.lastOpened = progress.last_daily_pack; state.packs = progress.packs_opened || 0; state.activities = progress.daily_activity_date === todayKey() ? (progress.daily_activities || {}) : {}; state.activityDate = progress.daily_activity_date; dailyAvailable = progress.last_daily_pack !== todayKey();
  byId("accountEmail").textContent = profile.name || profile.email; byId("authGate").classList.add("ready"); renderOdds(); renderAll();
  try { await refreshSocial(); } catch (error) { byId("feedList").innerHTML = `<div class="empty-small">Não foi possível carregar a área social: ${escapeHtml(error.message)}</div>`; }
}
async function handleAuth(event) {
  event.preventDefault(); const email = byId("authEmail").value.trim(), password = byId("authPassword").value, name = byId("authName").value.trim(), button = byId("authSubmit"); byId("authError").textContent = ""; button.disabled = true; button.textContent = registerMode ? "Criando conta…" : "Entrando…";
  try { if (registerMode) { const { data, error } = await supabase.auth.signUp({ email, password, options: { data: { name } } }); if (error) throw error; if (!data.session) { byId("authError").style.color = "#5fe0a1"; byId("authError").textContent = "Conta criada! Confirme o e-mail para entrar."; return; } } else { const { error } = await supabase.auth.signInWithPassword({ email, password }); if (error) throw error; } } catch (error) { byId("authError").style.color = "#ff9a8b"; byId("authError").textContent = error.message; } finally { button.disabled = false; button.textContent = registerMode ? "Criar conta" : "Entrar"; }
}
function toggleAuth() { registerMode = !registerMode; byId("authTitle").textContent = registerMode ? "Criar sua conta" : "Entrar no álbum"; byId("nameField").style.display = registerMode ? "block" : "none"; byId("authName").required = registerMode; byId("authPassword").autocomplete = registerMode ? "new-password" : "current-password"; byId("authSubmit").textContent = registerMode ? "Criar conta" : "Entrar"; byId("authToggle").textContent = registerMode ? "Já tenho uma conta" : "Ainda não tenho conta"; byId("authError").textContent = ""; }
function showSessionError(error) {
  const message = error?.message || "Não foi possível carregar sua sessão.";
  console.error("Falha ao iniciar o álbum:", message);
  byId("accountEmail").textContent = "Entre para jogar";
  byId("authError").style.color = "#ff9a8b";
  byId("authError").textContent = `${message} Tente entrar novamente.`;
}
async function initialize() {
  if (!configured) {
    byId("authMessage").textContent = "Conecte as variáveis do Supabase para iniciar.";
    byId("authError").textContent = "VITE_SUPABASE_URL e VITE_SUPABASE_PUBLISHABLE_KEY não configuradas.";
    byId("authSubmit").disabled = true;
    return;
  }
  supabase.auth.onAuthStateChange((event, session) => {
    if (event === "SIGNED_IN" && session) setTimeout(() => loadProfile(session.user).catch(showSessionError), 0);
    if (event === "SIGNED_OUT") location.reload();
  });
  try {
    const { data: { session }, error } = await supabase.auth.getSession();
    if (error) throw error;
    if (session) await loadProfile(session.user);
    else byId("accountEmail").textContent = "Entre para jogar";
  } catch (error) {
    showSessionError(error);
  }
}

document.querySelectorAll("[data-jump]").forEach(button => button.onclick = () => setActiveView(button.dataset.jump));
document.querySelectorAll(".filter[data-filter]").forEach(button => button.onclick = () => { currentFilter = button.dataset.filter; document.querySelectorAll(".filter[data-filter]").forEach(item => item.classList.toggle("active", item === button)); renderAlbum(); });
byId("rarityFilter").onchange = event => { currentRarity = event.target.value; renderAlbum(); }; byId("openPack").onclick = openDaily; byId("buyMystery").onclick = buyMystery; byId("showRules").onclick = () => openModal("rulesModal");
document.querySelectorAll("[data-close]").forEach(button => button.onclick = () => closeModal(button.dataset.close)); document.querySelectorAll(".modal").forEach(modal => modal.onclick = event => { if (event.target === modal) closeModal(modal.id); }); document.addEventListener("keydown", event => { if (event.key === "Escape") document.querySelectorAll(".modal.open").forEach(modal => closeModal(modal.id)); });
byId("postForm").addEventListener("submit", async event => { event.preventDefault(); const cardId = byId("postCard").value; if (!cardId) return; const button = event.submitter; button.disabled = true; try { await publishSticker(cardId, byId("postCaption").value); byId("postCaption").value = ""; } catch (error) { alert(error.message); } finally { button.disabled = false; } });
byId("friendForm").addEventListener("submit", async event => { event.preventDefault(); const handle = byId("friendHandle").value.trim().replace(/^@/, "").toLowerCase(); if (!handle) return; const button = event.submitter; button.disabled = true; const { error } = await supabase.rpc("send_friend_request", { p_handle: handle }); button.disabled = false; if (error) return alert(error.message); byId("friendHandle").value = ""; await refreshSocial(); });
byId("postPickerButton").onclick = () => openStickerPicker("post"); byId("offeredPickerButton").onclick = () => openStickerPicker("offered"); byId("requestedPickerButton").onclick = () => openStickerPicker("requested");
byId("confirmDeletePost").onclick = deleteOwnPost;
byId("tradeFriend").addEventListener("change", async event => { const friendId = event.target.value; friendOwned = {}; byId("offeredCard").value = ""; byId("requestedCard").value = ""; updateTradePickerTrigger("offered"); updateTradePickerTrigger("requested"); if (!friendId) return; byId("offeredPickerButton").disabled = true; byId("requestedPickerButton").disabled = true; byId("offeredPickerButton").textContent = "Carregando coleção…"; byId("requestedPickerButton").textContent = "Carregando coleção…"; const { data, error } = await supabase.from("album_progress").select("owned").eq("user_id", friendId).single(); if (error) { event.target.value = ""; updateTradePickerTrigger("offered"); updateTradePickerTrigger("requested"); return alert(error.message); } friendOwned = data.owned || {}; updateTradePickerTrigger("offered"); updateTradePickerTrigger("requested"); });
byId("tradeForm").addEventListener("submit", async event => { event.preventDefault(); const friend = byId("tradeFriend").value, offered = byId("offeredCard").value, requested = byId("requestedCard").value; if (!friend || !offered || !requested) return alert("Escolha o amigo e as duas figurinhas."); const button = event.submitter; button.disabled = true; const { error } = await supabase.rpc("propose_sticker_trade", { p_friend: friend, p_offered: Number(offered), p_requested: Number(requested) }); button.disabled = false; if (error) return alert(error.message); await refreshSocial(); });
byId("detailPost").onclick = async () => { if (!currentDetailCard) return; byId("detailPost").disabled = true; try { await publishSticker(currentDetailCard.id); closeModal("detailModal"); setActiveView("social"); } catch (error) { alert(error.message); } finally { byId("detailPost").disabled = false; } };
byId("detailFeature").onclick = async () => { if (!currentDetailCard) return; byId("detailFeature").disabled = true; try { await featureSticker(currentDetailCard.id); closeModal("detailModal"); } catch (error) { alert(error.message); } finally { byId("detailFeature").disabled = false; } };
byId("authForm").addEventListener("submit", handleAuth); byId("authToggle").onclick = toggleAuth; byId("logoutButton").onclick = async event => { event.preventDefault(); await supabase?.auth.signOut(); };
setActiveView(location.hash.slice(1), false); renderThemePacks(); renderOdds(); renderAll(); initialize();
