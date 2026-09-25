import { createClient } from "@supabase/supabase-js";

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY;
const configured = supabaseUrl?.startsWith("https://") && supabaseKey?.startsWith("sb_publishable_");
const supabase = configured ? createClient(supabaseUrl, supabaseKey) : null;
const TOTAL_CARDS = 110;

const rarities = [
  { id: "common", name: "Comum", color: "#9aa0b6", count: 50, packChance: 65, size: "1–2", guarantee: "1 comum ou melhor" },
  { id: "uncommon", name: "Incomum", color: "#5fe0a1", count: 27, packChance: 20, size: "3", guarantee: "1 incomum ou melhor" },
  { id: "rare", name: "Rara", color: "#53b8ff", count: 15, packChance: 8, size: "4–5", guarantee: "1 rara ou melhor" },
  { id: "epic", name: "Épica", color: "#b277ff", count: 9, packChance: 4, size: "6", guarantee: "1 épica ou melhor" },
  { id: "mythic", name: "Mítica", color: "#ff6eb5", count: 4, packChance: 2, size: "7", guarantee: "1 mítica ou melhor" },
  { id: "legendary", name: "Lendária", color: "#ffd75f", count: 2, packChance: .8, size: "10", guarantee: "1 lendária exclusiva" },
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

const uncommonIds = new Set([7, 9, 16, 25, 28, 31, 32, 33, 34, 36, 37, 39, 40, 41, 42, 43, 47, 48, 53, 55, 58, 62, 63, 64, 70, 75, 76]);
const rareIds = new Set([10, 20, 21, 22, 23, 27, 49, 54, 60, 61, 69, 71, 72, 73, 74]);
const epicIds = new Set([1, 11, 17, 18, 19, 24, 26, 38, 95]);
const mythicIds = new Set([13, 67, 96, 97]);
const legendaryIds = new Set([4, 102]);
const secretIds = new Set([5, 12, 110]);
const rarityFor = id => secretIds.has(id) ? "secret" : legendaryIds.has(id) ? "legendary" : mythicIds.has(id) ? "mythic" : epicIds.has(id) ? "epic" : rareIds.has(id) ? "rare" : uncommonIds.has(id) ? "uncommon" : "common";
const icons = ["🐺", "🎨", "6️⃣", "🧃", "🥤", "🍛", "🍚", "🐻", "🐤", "🦊", "🐰", "🎭", "🤖", "🩰", "📐", "🌈", "🦇", "⚔️", "🦸", "⚡", "🃏", "♦️", "🎲", "💚", "🌙", "🎣", "🚗", "🤝", "😎", "🍳", "👮", "🦜", "🩴", "⌚", "🥩", "🎤", "🐴", "🟣", "🎮", "🎬", "💘", "🤡", "⚽", "🔊", "🕹️", "🍔", "🏋️", "⛏️", "🧙", "🧒", "👸", "👴", "💗", "🔥", "🧽", "👨", "✨", "🌵", "💰", "🌊", "🐉", "🏰", "👦", "🧪", "🦑", "⭐", "⚡", "🍓", "🐇", "🏍️", "👣", "🐊", "🧜", "🧢", "🔥", "🌳", "💇", "😎", "🖤", "🎨", "🧔", "🚌", "🚍", "🎙️", "👁️", "🍥", "🌸", "🥷", "📚", "🔧", "💻", "🕴️", "💎", "👶", "⛓️", "🌑", "☀️", "😍", "😡", "😁", "🤤", "🪄", "🥪", "🐕", "💞", "🤪", "🦣", "☝️", "👻", "❓"];
const cards = cardNames.map((name, index) => ({ id: index + 1, name, rarity: rarityFor(index + 1), icon: icons[index], description: `Uma versão única de Pedro Víctor para a coleção. ${rarityFor(index + 1) === "secret" ? "Esta figurinha secreta só aparece depois de ser descoberta." : "Encontre-a abrindo pacotes e cumprindo missões."}` }));

const juiceRewards = { common: 2, uncommon: 4, rare: 7, epic: 12, mythic: 20, legendary: 35, secret: 60 };
const missions = [
  { id: "daily_pack", icon: "🎁", title: "Explorador diário", description: "Abra o pacote grátis do dia.", reward: "Pacote + 5 🧃" },
  { id: "memory", icon: "🧠", title: "Memória cósmica", description: "Encontre quatro pares antes de esquecer.", reward: "+8 🧃" },
  { id: "quiz", icon: "❓", title: "Quiz do Pedro", description: "Acerte a pergunta diária sobre o álbum.", reward: "+6 🧃" },
  { id: "caju", icon: "🧃", title: "Caça ao caju", description: "Pegue cinco cajus antes do tempo acabar.", reward: "+10 🧃" }
];
const state = { owned: {}, juice: 0, lastOpened: null, packs: 0, activities: {}, activityDate: null };
let currentFilter = "all", currentRarity = "all", registerMode = false, dailyAvailable = false, gameTimer = null;
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
  document.querySelector(".progress-fill").style.width = `${s.percent}%`; document.querySelector(".progress-track").setAttribute("aria-valuenow", s.unique);
  byId("collectionCopy").textContent = s.unique === TOTAL_CARDS ? "Coleção completa. Você conquistou todas as versões!" : `${TOTAL_CARDS - s.unique} descobertas faltam — as secretas só aparecem depois de encontradas.`;
}
function renderAlbum() {
  const grid = byId("albumGrid");
  const filtered = cards.filter(card => { const owned = Boolean(state.owned[card.id]); if (card.rarity === "secret" && !owned) return false; return (currentFilter === "all" || (currentFilter === "owned" && owned) || (currentFilter === "missing" && !owned)) && (currentRarity === "all" || card.rarity === currentRarity); });
  grid.innerHTML = filtered.length ? "" : '<div class="empty">Nenhuma figurinha combina com este filtro. As secretas só surgem quando descobertas.</div>';
  filtered.forEach(card => { const r = rarity(card.rarity), owned = Boolean(state.owned[card.id]), button = document.createElement("button"); button.className = `sticker ${owned ? "" : "locked"}`; button.style.setProperty("--rarity", r.color); button.innerHTML = `<span class="sticker-number">#${String(card.id).padStart(3, "0")}</span><span class="sticker-badge">${r.name}</span>${state.owned[card.id] > 1 ? `<span class="dupe">+${state.owned[card.id] - 1}</span>` : ""}<span class="sticker-visual">${owned ? card.icon : "✦"}</span><span class="sticker-info"><span class="sticker-name">${owned ? card.name : "Figurinha oculta"}</span><span class="sticker-rarity">${r.name}</span></span>`; button.disabled = !owned; button.setAttribute("aria-label", owned ? `${card.name}, ${r.name}` : `Figurinha ${card.id} ainda não encontrada`); if (owned) button.onclick = () => showDetail(card); grid.appendChild(button); });
}
function renderOdds() {
  const rows = (metric, max, formatter) => rarities.map(r => `<div class="prob-row"><span class="rarity-key"><i class="dot" style="--c:${r.color}"></i>${r.name}</span><span class="bar"><i style="--c:${r.color};--w:${(r[metric] / max) * 100}%"></i></span><b>${formatter(r[metric])}</b></div>`).join("");
  byId("packOdds").innerHTML = rows("packChance", 65, value => `${value}%`); byId("stickerOdds").innerHTML = rows("count", 50, String);
  byId("packRules").innerHTML = rarities.map(r => `<tr><td><span class="rarity-key"><i class="dot" style="--c:${r.color}"></i>${r.name}</span></td><td>${r.size} figurinhas</td><td>${r.guarantee}</td><td><strong>+${juiceRewards[r.id]} 🧃</strong></td></tr>`).join("");
  byId("rarityFilter").innerHTML = '<option value="all">Toda raridade</option>' + rarities.filter(r => r.id !== "secret" || cards.some(card => card.rarity === "secret" && state.owned[card.id])).map(r => `<option value="${r.id}">${r.name}</option>`).join("");
}
function missionDone(id) { return id === "daily_pack" ? !dailyAvailable : state.activityDate === todayKey() && Boolean(state.activities?.[id]); }
function renderMissions() {
  const completed = missions.filter(mission => missionDone(mission.id)).length;
  byId("missionSummary").textContent = `${completed} / ${missions.length} concluídas`; byId("missionProgress").style.setProperty("--w", `${(completed / missions.length) * 100}%`);
  byId("missionGrid").innerHTML = missions.map(mission => { const done = missionDone(mission.id), action = mission.id === "daily_pack" ? "Ir para o pacote" : "Jogar agora"; return `<article class="mission-card ${done ? "done" : ""}"><div class="mission-icon">${mission.icon}</div><h3>${mission.title}</h3><p>${mission.description}</p><div class="mission-reward">${mission.reward}</div><button class="${done ? "ghost" : "primary"}" data-mission="${mission.id}" ${done ? "disabled" : ""}>${done ? "✓ Concluída" : action}</button></article>`; }).join("");
  document.querySelectorAll("[data-mission]").forEach(button => button.onclick = () => { const id = button.dataset.mission; if (id === "daily_pack") byId("openPack").scrollIntoView({ behavior: "smooth", block: "center" }); else startGame(id); });
}
function updateDaily() { const button = byId("openPack"); button.disabled = !dailyAvailable; button.textContent = dailyAvailable ? "Abrir pacote grátis" : "Pacote de hoje aberto"; byId("packMessage").textContent = dailyAvailable ? "Um pacote está esperando por você." : "Volte amanhã para uma nova surpresa."; byId("countdown").textContent = dailyAvailable ? "Disponível agora" : "Novo pacote à meia-noite"; }
function renderAll() { renderStats(); renderAlbum(); updateDaily(); renderMissions(); }
function openModal(id) { byId(id).classList.add("open"); byId(id).querySelector(".close").focus(); document.body.style.overflow = "hidden"; }
function closeModal(id) { if (id === "gameModal" && gameTimer) clearInterval(gameTimer); gameTimer = null; byId(id).classList.remove("open"); document.body.style.overflow = ""; }
function showDetail(card) { const r = rarity(card.rarity); byId("detailIcon").textContent = card.icon; byId("detailRarity").textContent = `#${String(card.id).padStart(3, "0")} · ${r.name}`; byId("detailRarity").style.color = r.color; byId("detailTitle").textContent = card.name; byId("detailText").textContent = card.description + (state.owned[card.id] > 1 ? ` Você possui ${state.owned[card.id]} cópias.` : ""); openModal("detailModal"); }
function burst() { const box = byId("confetti"), colors = rarities.map(r => r.color); box.innerHTML = ""; for (let i = 0; i < 42; i++) { const piece = document.createElement("i"); piece.style.cssText = `left:${Math.random() * 100}%;--x:${(Math.random() - .5) * 300}px;--c:${colors[i % colors.length]};animation-delay:${Math.random() * .4}s`; box.appendChild(piece); } setTimeout(() => box.innerHTML = "", 2500); }
function showPack(data, source) {
  const payload = typeof data === "string" ? JSON.parse(data) : data; Object.assign(state, payload.state); dailyAvailable = payload.daily_available;
  const tier = rarities.findIndex(r => r.id === payload.pack_tier), entries = payload.entries.map(entry => ({ card: cards.find(card => card.id === entry.id), isNew: entry.is_new })).filter(entry => entry.card), newCount = entries.filter(entry => entry.isNew).length;
  byId("revealTier").textContent = `${source === "mystery" ? "Pacote misterioso revelou: " : ""}Pacote ${payload.pack_rarity}`; byId("revealTier").style.color = rarities[tier].color; byId("revealSummary").textContent = `${newCount ? `${newCount} ${newCount === 1 ? "nova figurinha" : "novas figurinhas"}` : "Somente repetidas"}${payload.reward ? ` · +${payload.reward} 🧃` : ""}`; byId("revealGrid").innerHTML = "";
  entries.forEach(({ card, isNew }, index) => { const r = rarity(card.rarity), element = document.createElement("div"); element.className = "reveal-card"; element.style.cssText = `--rarity:${r.color};animation-delay:${index * .08}s`; element.innerHTML = `<div><div class="icon">${card.icon}</div><b>${card.name}</b><small>${r.name}</small>${isNew ? '<div class="new-tag">NOVA</div>' : ""}</div>`; byId("revealGrid").appendChild(element); });
  openModal("revealModal"); if (tier >= 4 || newCount >= 3) burst(); renderOdds(); renderAll(); return payload;
}
async function openPack(source) { const { data, error } = await supabase.rpc("open_album_pack", { p_source: source }); if (error) throw error; return showPack(data, source); }
async function openDaily() { if (!dailyAvailable) return; byId("openPack").disabled = true; try { return await openPack("daily"); } catch (error) { alert(error.message); updateDaily(); } }
async function buyMystery() { if (state.juice < 30) return; byId("buyMystery").disabled = true; try { return await openPack("mystery"); } catch (error) { alert(error.message); renderStats(); } }
async function completeActivity(id, score) {
  const { data, error } = await supabase.rpc("complete_daily_activity", { p_activity: id, p_score: score }); if (error) throw error;
  state.juice = data.coins; state.activities = data.activities || {}; state.activityDate = data.activity_date; renderStats(); renderMissions(); burst();
  byId("gameContent").innerHTML = `<p class="reward-toast">Missão concluída! +${data.reward} 🧃 Suco de Caju</p><button class="primary" data-close-game style="display:block;margin:22px auto 0">Voltar às missões</button>`; byId("gameContent").querySelector("[data-close-game]").onclick = () => closeModal("gameModal");
}
function startMemory() {
  const deck = ["🧃", "🌟", "🎮", "🐺", "🧃", "🌟", "🎮", "🐺"].sort(() => Math.random() - .5); let first = null, lock = false, matches = 0;
  byId("gameContent").innerHTML = '<p class="game-copy">Encontre os quatro pares.</p><div class="memory-grid"></div><div class="game-status">0 / 4 pares</div>';
  const grid = byId("gameContent").querySelector(".memory-grid"), status = byId("gameContent").querySelector(".game-status");
  deck.forEach(icon => { const button = document.createElement("button"); button.className = "memory-card"; button.textContent = icon; button.onclick = () => { if (lock || button.classList.contains("matched") || button === first) return; button.classList.add("open"); if (!first) { first = button; return; } if (first.textContent === button.textContent) { first.classList.add("matched"); button.classList.add("matched"); first = null; matches++; status.textContent = `${matches} / 4 pares`; if (matches === 4) completeActivity("memory", 4).catch(error => alert(error.message)); } else { lock = true; const previous = first; first = null; setTimeout(() => { previous.classList.remove("open"); button.classList.remove("open"); lock = false; }, 650); } }; grid.appendChild(button); });
}
const quizQuestions = [
  { question: "Qual é a moeda do jogo?", options: ["Suco de Caju", "Moeda Lunar", "Arroz e Feijão"], answer: 0 },
  { question: "Quantas figurinhas existem no álbum?", options: ["100", "110", "120"], answer: 1 },
  { question: "Qual raridade fica escondida no catálogo?", options: ["Rara", "Lendária", "Secreta"], answer: 2 },
  { question: "Quanto custa um pacote misterioso?", options: ["10 🧃", "30 🧃", "60 🧃"], answer: 1 }
];
function startQuiz() {
  const seed = [...todayKey()].reduce((sum, char) => sum + char.charCodeAt(0), 0), quiz = quizQuestions[seed % quizQuestions.length];
  byId("gameContent").innerHTML = `<p class="game-copy">${quiz.question}</p><div class="quiz-options">${quiz.options.map((option, index) => `<button class="ghost" data-answer="${index}">${option}</button>`).join("")}</div><div class="game-status"></div>`;
  const status = byId("gameContent").querySelector(".game-status"); byId("gameContent").querySelectorAll("[data-answer]").forEach(button => button.onclick = () => { if (Number(button.dataset.answer) === quiz.answer) { status.textContent = "Resposta certa!"; byId("gameContent").querySelectorAll("button").forEach(item => item.disabled = true); completeActivity("quiz", 1).catch(error => alert(error.message)); } else { status.textContent = "Quase! Tente outra resposta."; button.disabled = true; } });
}
function startCaju() {
  let caught = 0, seconds = 20; byId("gameContent").innerHTML = '<p class="game-copy">Clique no caju cinco vezes antes do tempo acabar.</p><div class="game-status">5 faltando · 20s</div><div class="caju-arena"><button class="caju-target" aria-label="Pegar Suco de Caju">🧃</button></div>';
  const target = byId("gameContent").querySelector(".caju-target"), status = byId("gameContent").querySelector(".game-status"), move = () => { target.style.left = `${Math.random() * 82 + 2}%`; target.style.top = `${Math.random() * 72 + 4}%`; };
  target.onclick = () => { caught++; status.textContent = `${5 - caught} faltando · ${seconds}s`; if (caught >= 5) { clearInterval(gameTimer); gameTimer = null; target.disabled = true; completeActivity("caju", 5).catch(error => alert(error.message)); } else move(); }; move();
  gameTimer = setInterval(() => { seconds--; status.textContent = `${5 - caught} faltando · ${seconds}s`; if (seconds <= 0) { clearInterval(gameTimer); gameTimer = null; target.disabled = true; status.innerHTML = 'O tempo acabou. <button class="ghost" data-retry>Tentar novamente</button>'; status.querySelector("[data-retry]").onclick = startCaju; } }, 1000);
}
function startGame(id) { if (missionDone(id)) return; byId("gameTitle").textContent = missions.find(mission => mission.id === id)?.title || "Minijogo"; openModal("gameModal"); if (id === "memory") startMemory(); if (id === "quiz") startQuiz(); if (id === "caju") startCaju(); }

async function loadProfile(user) {
  const [{ data: profile, error: profileError }, { data: progress, error: progressError }] = await Promise.all([supabase.from("profiles").select("name,email").eq("id", user.id).single(), supabase.from("album_progress").select("owned,coins,last_daily_pack,packs_opened,daily_activities,daily_activity_date").eq("user_id", user.id).single()]);
  if (profileError) throw profileError; if (progressError) throw progressError;
  state.owned = progress.owned || {}; state.juice = progress.coins || 0; state.lastOpened = progress.last_daily_pack; state.packs = progress.packs_opened || 0; state.activities = progress.daily_activity_date === todayKey() ? (progress.daily_activities || {}) : {}; state.activityDate = progress.daily_activity_date; dailyAvailable = progress.last_daily_pack !== todayKey();
  byId("accountEmail").textContent = profile.name || profile.email; byId("authGate").classList.add("ready"); renderOdds(); renderAll();
}
async function handleAuth(event) {
  event.preventDefault(); const email = byId("authEmail").value.trim(), password = byId("authPassword").value, name = byId("authName").value.trim(), button = byId("authSubmit"); byId("authError").textContent = ""; button.disabled = true; button.textContent = registerMode ? "Criando conta…" : "Entrando…";
  try { if (registerMode) { const { data, error } = await supabase.auth.signUp({ email, password, options: { data: { name } } }); if (error) throw error; if (!data.session) { byId("authError").style.color = "#5fe0a1"; byId("authError").textContent = "Conta criada! Confirme o e-mail para entrar."; return; } } else { const { error } = await supabase.auth.signInWithPassword({ email, password }); if (error) throw error; } } catch (error) { byId("authError").style.color = "#ff9a8b"; byId("authError").textContent = error.message; } finally { button.disabled = false; button.textContent = registerMode ? "Criar conta" : "Entrar"; }
}
function toggleAuth() { registerMode = !registerMode; byId("authTitle").textContent = registerMode ? "Criar sua conta" : "Entrar no álbum"; byId("nameField").style.display = registerMode ? "block" : "none"; byId("authName").required = registerMode; byId("authPassword").autocomplete = registerMode ? "new-password" : "current-password"; byId("authSubmit").textContent = registerMode ? "Criar conta" : "Entrar"; byId("authToggle").textContent = registerMode ? "Já tenho uma conta" : "Ainda não tenho conta"; byId("authError").textContent = ""; }
async function initialize() { if (!configured) { byId("authMessage").textContent = "Conecte as variáveis do Supabase para iniciar."; byId("authError").textContent = "VITE_SUPABASE_URL e VITE_SUPABASE_PUBLISHABLE_KEY não configuradas."; byId("authSubmit").disabled = true; return; } const { data: { session } } = await supabase.auth.getSession(); if (session) await loadProfile(session.user); supabase.auth.onAuthStateChange((event, session) => { if (event === "SIGNED_IN" && session) setTimeout(() => loadProfile(session.user), 0); if (event === "SIGNED_OUT") location.reload(); }); }

document.querySelectorAll("[data-jump]").forEach(button => button.onclick = () => { document.querySelectorAll("[data-jump]").forEach(item => item.classList.toggle("active", item === button)); byId(button.dataset.jump).scrollIntoView({ behavior: "smooth" }); });
document.querySelectorAll(".filter[data-filter]").forEach(button => button.onclick = () => { currentFilter = button.dataset.filter; document.querySelectorAll(".filter[data-filter]").forEach(item => item.classList.toggle("active", item === button)); renderAlbum(); });
byId("rarityFilter").onchange = event => { currentRarity = event.target.value; renderAlbum(); }; byId("openPack").onclick = openDaily; byId("buyMystery").onclick = buyMystery; byId("showRules").onclick = () => openModal("rulesModal");
document.querySelectorAll("[data-close]").forEach(button => button.onclick = () => closeModal(button.dataset.close)); document.querySelectorAll(".modal").forEach(modal => modal.onclick = event => { if (event.target === modal) closeModal(modal.id); }); document.addEventListener("keydown", event => { if (event.key === "Escape") document.querySelectorAll(".modal.open").forEach(modal => closeModal(modal.id)); });
byId("authForm").addEventListener("submit", handleAuth); byId("authToggle").onclick = toggleAuth; byId("logoutButton").onclick = async event => { event.preventDefault(); await supabase?.auth.signOut(); };
renderOdds(); renderAll(); initialize();
