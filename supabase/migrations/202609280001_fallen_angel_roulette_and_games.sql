alter table public.album_progress
  add column if not exists last_roulette_spin date;

alter table public.social_profiles drop constraint if exists social_profiles_featured_card_check;
alter table public.social_profiles add constraint social_profiles_featured_card_check check (featured_card between 1 and 111);
alter table public.feed_posts drop constraint if exists feed_posts_card_id_check;
alter table public.feed_posts add constraint feed_posts_card_id_check check (card_id between 1 and 111);
alter table public.sticker_trades drop constraint if exists sticker_trades_offered_card_id_check;
alter table public.sticker_trades add constraint sticker_trades_offered_card_id_check check (offered_card_id between 1 and 111);
alter table public.sticker_trades drop constraint if exists sticker_trades_requested_card_id_check;
alter table public.sticker_trades add constraint sticker_trades_requested_card_id_check check (requested_card_id between 1 and 111);

create or replace function public.album_card_rarity(p_card integer)
returns text
language sql
immutable
as $$
  select case
    when p_card = 111 then 'supersecret'
    when p_card = any(array[5,12,110]) then 'secret'
    when p_card = any(array[4,67,102,109]) then 'legendary'
    when p_card = any(array[13,38,54,69,95,96,97]) then 'mythic'
    when p_card = any(array[1,11,17,18,19,24,26,27,49,60,61,84,85,88]) then 'epic'
    when p_card = any(array[10,20,21,22,23,41,43,48,53,62,63,64,70,71,72,73,74,76,86,87,94]) then 'rare'
    when p_card = any(array[7,9,16,25,28,31,32,33,34,36,37,39,40,42,47,55,58,66,68,75,77,78,79,80,81,83]) then 'uncommon'
    when p_card between 1 and 110 then 'common'
    else null
  end;
$$;

create or replace function public.album_card_reward(p_card integer)
returns integer
language sql
immutable
as $$
  select case public.album_card_rarity(p_card)
    when 'common' then 2 when 'uncommon' then 4 when 'rare' then 7
    when 'epic' then 12 when 'mythic' then 20 when 'legendary' then 35
    when 'secret' then 60 when 'supersecret' then 250 else 0
  end;
$$;

create or replace function public.open_album_pack(p_source text)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
  today_local date := (now() at time zone 'America/Fortaleza')::date;
  pack_tier text;
  pack_name text;
  pack_size integer;
  cards integer[] := '{}';
  card_id integer;
  owned_state jsonb;
  coin_balance integer;
  last_opened date;
  opened_count integer;
  duplicate_reward integer := 0;
  display_reward integer := 0;
  previous_count integer;
  entries jsonb := '[]'::jsonb;
begin
  if uid is null then raise exception 'Faça login para continuar'; end if;
  if p_source not in ('daily','mystery') then raise exception 'Origem de pacote inválida'; end if;

  select owned, coins, last_daily_pack, packs_opened
  into owned_state, coin_balance, last_opened, opened_count
  from public.album_progress where user_id = uid for update;
  if not found then raise exception 'Álbum do usuário não encontrado'; end if;
  if p_source = 'daily' and last_opened = today_local then raise exception 'O pacote diário já foi aberto'; end if;
  if p_source = 'mystery' and coin_balance < 30 then raise exception 'Você precisa de 30 Suco de Caju'; end if;

  pack_tier := public.choose_album_pack_tier();
  pack_name := case pack_tier when 'common' then 'Comum' when 'uncommon' then 'Incomum' when 'rare' then 'Rara' when 'epic' then 'Épica' when 'mythic' then 'Mítica' when 'legendary' then 'Lendária' else 'Secreta' end;
  pack_size := case pack_tier when 'common' then 1 + floor(random()*2)::integer when 'uncommon' then 3 when 'rare' then 4 + floor(random()*2)::integer when 'epic' then 6 when 'mythic' then 7 else 10 end;

  if pack_tier = 'secret' then
    cards := array_append(cards, public.random_album_card('legendary'));
    cards := array_append(cards, public.random_album_card('secret'));
  else
    cards := array_append(cards, public.random_album_card(pack_tier));
  end if;
  while coalesce(array_length(cards,1),0) < pack_size loop
    cards := array_append(cards, public.random_album_card(public.choose_album_pack_tier()));
  end loop;

  -- Uma chance por pacote: 0,01% (1 em 10.000). A carta entra como bônus.
  if random() < 0.0001 then cards := array_append(cards, 111); end if;

  foreach card_id in array cards loop
    previous_count := coalesce((owned_state ->> card_id::text)::integer, 0);
    if previous_count > 0 then duplicate_reward := duplicate_reward + public.album_card_reward(card_id); end if;
    owned_state := jsonb_set(owned_state, array[card_id::text], to_jsonb(previous_count + 1), true);
    entries := entries || jsonb_build_array(jsonb_build_object('id',card_id,'is_new',previous_count=0));
  end loop;

  if p_source = 'daily' then
    coin_balance := coin_balance + duplicate_reward + 5;
    display_reward := duplicate_reward + 5;
    last_opened := today_local;
  else
    coin_balance := coin_balance - 30 + duplicate_reward;
    display_reward := duplicate_reward;
  end if;
  opened_count := opened_count + 1;

  update public.album_progress set owned=owned_state, coins=coin_balance, last_daily_pack=last_opened,
    packs_opened=opened_count, updated_at=now() where user_id=uid;

  return jsonb_build_object(
    'pack_rarity',pack_name,'pack_tier',pack_tier,'entries',entries,'reward',display_reward,
    'daily_available',last_opened is distinct from today_local,
    'state',jsonb_build_object('owned',owned_state,'juice',coin_balance,'lastOpened',last_opened,'packs',opened_count)
  );
end;
$$;

create or replace function public.open_themed_album_pack(p_theme text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  today_local date := (now() at time zone 'America/Fortaleza')::date;
  theme_cards integer[] := public.album_theme_cards(p_theme);
  theme_name text;
  pack_size integer;
  preferred_rarity text;
  pack_tier text := 'common';
  cards integer[] := '{}';
  card_id integer;
  owned_state jsonb;
  coin_balance integer;
  last_opened date;
  opened_count integer;
  duplicate_reward integer := 0;
  previous_count integer;
  entries jsonb := '[]'::jsonb;
begin
  if uid is null then raise exception 'Faça login para continuar'; end if;
  if theme_cards is null then raise exception 'Tema de pacote inválido'; end if;

  pack_size := case when cardinality(theme_cards) <= 10 then 3 else 5 end;
  theme_name := case p_theme
    when 'animatronics' then 'Animatronics' when 'food' then 'Comidas & bebidas'
    when 'heroes' then 'Heróis & vilões' when 'games' then 'Anime & games'
    when 'folklore' then 'Folclore & magia' when 'routine' then 'Profissões & rotina'
    else 'Estilos & especiais'
  end;

  select owned, coins, last_daily_pack, packs_opened
  into owned_state, coin_balance, last_opened, opened_count
  from public.album_progress where user_id = uid for update;
  if not found then raise exception 'Álbum do usuário não encontrado'; end if;
  if coin_balance < 40 then raise exception 'Você precisa de 40 Suco de Caju'; end if;

  select candidate into card_id from unnest(theme_cards) as candidate
  where public.album_card_rarity(candidate) <> 'common' order by random() limit 1;
  cards := array_append(cards, coalesce(card_id, public.random_themed_album_card(p_theme)));
  while array_length(cards, 1) < pack_size loop
    preferred_rarity := public.choose_album_pack_tier();
    cards := array_append(cards, public.random_themed_album_card(p_theme, preferred_rarity));
  end loop;

  select public.album_card_rarity(candidate) into pack_tier from unnest(cards) as candidate
  order by case public.album_card_rarity(candidate)
    when 'secret' then 7 when 'legendary' then 6 when 'mythic' then 5
    when 'epic' then 4 when 'rare' then 3 when 'uncommon' then 2 else 1 end desc limit 1;

  if random() < 0.0001 then cards := array_append(cards, 111); end if;

  foreach card_id in array cards loop
    previous_count := coalesce((owned_state ->> card_id::text)::integer, 0);
    if previous_count > 0 then duplicate_reward := duplicate_reward + public.album_card_reward(card_id); end if;
    owned_state := jsonb_set(owned_state, array[card_id::text], to_jsonb(previous_count + 1), true);
    entries := entries || jsonb_build_array(jsonb_build_object('id', card_id, 'is_new', previous_count = 0));
  end loop;

  coin_balance := coin_balance - 40 + duplicate_reward;
  opened_count := opened_count + 1;
  update public.album_progress set owned=owned_state, coins=coin_balance, packs_opened=opened_count, updated_at=now() where user_id=uid;

  return jsonb_build_object(
    'pack_rarity',theme_name,'pack_tier',pack_tier,'pack_theme',p_theme,'pack_size',pack_size,
    'entries',entries,'reward',duplicate_reward,'daily_available',last_opened is distinct from today_local,
    'state',jsonb_build_object('owned',owned_state,'juice',coin_balance,'lastOpened',last_opened,'packs',opened_count)
  );
end;
$$;

create or replace function public.spin_fallen_angel_roulette()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  today_local date := (now() at time zone 'America/Fortaleza')::date;
  last_spin date;
  owned_state jsonb;
  coin_balance integer;
  roll double precision := random();
  previous_count integer;
  prize text;
  amount integer := 0;
  is_new boolean := false;
begin
  if uid is null then raise exception 'Faça login para continuar'; end if;
  select last_roulette_spin, owned, coins into last_spin, owned_state, coin_balance
  from public.album_progress where user_id = uid for update;
  if not found then raise exception 'Álbum do usuário não encontrado'; end if;
  if last_spin = today_local then raise exception 'A roleta já foi usada hoje'; end if;

  if roll < 0.0001 then
    prize := 'fallen_angel';
    previous_count := coalesce((owned_state ->> '111')::integer, 0);
    is_new := previous_count = 0;
    owned_state := jsonb_set(owned_state, array['111'], to_jsonb(previous_count + 1), true);
    if previous_count > 0 then amount := 250; coin_balance := coin_balance + amount; end if;
  elsif roll < 0.50005 then
    prize := 'juice_1'; amount := 1; coin_balance := coin_balance + 1;
  else
    prize := 'juice_2'; amount := 2; coin_balance := coin_balance + 2;
  end if;

  update public.album_progress set owned=owned_state, coins=coin_balance,
    last_roulette_spin=today_local, updated_at=now() where user_id=uid;

  return jsonb_build_object(
    'prize',prize,'amount',amount,'is_new',is_new,'coins',coin_balance,'owned',owned_state,
    'last_spin',today_local,'daily_available',false
  );
end;
$$;

create or replace function public.complete_daily_activity(p_activity text, p_score integer)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  today_local date := (now() at time zone 'America/Fortaleza')::date;
  activities jsonb;
  activity_date date;
  coin_balance integer;
  reward integer;
  minimum_score integer;
begin
  if uid is null then raise exception 'Faça login para continuar'; end if;
  reward := case p_activity
    when 'memory' then 8 when 'quiz' then 6 when 'caju' then 10 when 'rarity' then 7
    when 'sequence' then 9 when 'order' then 11 when 'reflex' then 8 when 'duel' then 9 else 0 end;
  minimum_score := case p_activity
    when 'memory' then 6 when 'quiz' then 3 when 'caju' then 10 when 'rarity' then 4
    when 'sequence' then 5 when 'order' then 8 when 'reflex' then 1 when 'duel' then 5 else 999 end;
  if reward = 0 then raise exception 'Missão inválida'; end if;
  if p_score < minimum_score then raise exception 'Complete o desafio antes de resgatar a recompensa'; end if;

  select daily_activities, daily_activity_date, coins into activities, activity_date, coin_balance
  from public.album_progress where user_id = uid for update;
  if activity_date is distinct from today_local then activities := '{}'::jsonb; activity_date := today_local; end if;
  if coalesce((activities ->> p_activity)::boolean, false) then raise exception 'Esta missão já foi concluída hoje'; end if;

  activities := jsonb_set(activities, array[p_activity], 'true'::jsonb, true);
  coin_balance := coin_balance + reward;
  update public.album_progress set daily_activities=activities,daily_activity_date=activity_date,
    coins=coin_balance,updated_at=now() where user_id=uid;
  return jsonb_build_object('activity',p_activity,'reward',reward,'coins',coin_balance,'activities',activities,'activity_date',activity_date);
end;
$$;

revoke all on function public.spin_fallen_angel_roulette() from public, anon;
grant execute on function public.spin_fallen_angel_roulette() to authenticated;
revoke all on function public.complete_daily_activity(text, integer) from public, anon;
grant execute on function public.complete_daily_activity(text, integer) to authenticated;
revoke all on function public.open_album_pack(text) from public, anon;
grant execute on function public.open_album_pack(text) to authenticated;
revoke all on function public.open_themed_album_pack(text) from public, anon;
grant execute on function public.open_themed_album_pack(text) to authenticated;
