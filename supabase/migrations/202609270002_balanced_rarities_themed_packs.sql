create or replace function public.album_card_rarity(p_card integer)
returns text
language sql
immutable
as $$
  select case
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

create or replace function public.album_theme_cards(p_theme text)
returns integer[]
language sql
immutable
as $$
  select case p_theme
    when 'animatronics' then array[8,9,10,11,12,13,14,69]
    when 'food' then array[4,5,6,7,35,55,65,66,68,103,104]
    when 'heroes' then array[17,18,19,20,21,22,23,24,53]
    when 'games' then array[26,27,38,39,45,48,54,60,61,62,63,64,84,85,86,87,88,95]
    when 'folklore' then array[49,67,71,72,73,74,75,76,102,109]
    when 'routine' then array[15,25,30,31,34,43,47,52,70,82,83,89,90,91]
    when 'special' then array[1,2,3,16,28,29,32,33,36,37,40,41,42,44,46,50,51,56,57,58,59,77,78,79,80,81,92,93,94,96,97,98,99,100,101,105,106,107,108,110]
    else null
  end;
$$;

create or replace function public.random_themed_album_card(p_theme text, p_rarity text default null)
returns integer
language plpgsql
volatile
as $$
declare
  theme_cards integer[] := public.album_theme_cards(p_theme);
  chosen integer;
begin
  if theme_cards is null then
    raise exception 'Tema de pacote inválido';
  end if;
  select card_id into chosen
  from unnest(theme_cards) as card_id
  where p_rarity is null or public.album_card_rarity(card_id) = p_rarity
  order by random()
  limit 1;
  if chosen is null then
    select card_id into chosen from unnest(theme_cards) as card_id order by random() limit 1;
  end if;
  return chosen;
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

  theme_name := case p_theme
    when 'animatronics' then 'Animatronics'
    when 'food' then 'Comidas & bebidas'
    when 'heroes' then 'Heróis & vilões'
    when 'games' then 'Anime & games'
    when 'folklore' then 'Folclore & magia'
    when 'routine' then 'Profissões & rotina'
    else 'Estilos & especiais'
  end;

  select owned, coins, last_daily_pack, packs_opened
  into owned_state, coin_balance, last_opened, opened_count
  from public.album_progress
  where user_id = uid
  for update;
  if not found then raise exception 'Álbum do usuário não encontrado'; end if;
  if coin_balance < 40 then raise exception 'Você precisa de 40 Suco de Caju'; end if;

  select candidate into card_id
  from unnest(theme_cards) as candidate
  where public.album_card_rarity(candidate) <> 'common'
  order by random()
  limit 1;
  cards := array_append(cards, coalesce(card_id, public.random_themed_album_card(p_theme)));

  while array_length(cards, 1) < 5 loop
    preferred_rarity := public.choose_album_pack_tier();
    cards := array_append(cards, public.random_themed_album_card(p_theme, preferred_rarity));
  end loop;

  select public.album_card_rarity(candidate) into pack_tier
  from unnest(cards) as candidate
  order by case public.album_card_rarity(candidate)
    when 'secret' then 7 when 'legendary' then 6 when 'mythic' then 5
    when 'epic' then 4 when 'rare' then 3 when 'uncommon' then 2 else 1 end desc
  limit 1;

  foreach card_id in array cards loop
    previous_count := coalesce((owned_state ->> card_id::text)::integer, 0);
    if previous_count > 0 then duplicate_reward := duplicate_reward + public.album_card_reward(card_id); end if;
    owned_state := jsonb_set(owned_state, array[card_id::text], to_jsonb(previous_count + 1), true);
    entries := entries || jsonb_build_array(jsonb_build_object('id', card_id, 'is_new', previous_count = 0));
  end loop;

  coin_balance := coin_balance - 40 + duplicate_reward;
  opened_count := opened_count + 1;
  update public.album_progress
  set owned = owned_state, coins = coin_balance, packs_opened = opened_count, updated_at = now()
  where user_id = uid;

  return jsonb_build_object(
    'pack_rarity', theme_name,
    'pack_tier', pack_tier,
    'pack_theme', p_theme,
    'entries', entries,
    'reward', duplicate_reward,
    'daily_available', last_opened is distinct from today_local,
    'state', jsonb_build_object('owned', owned_state, 'juice', coin_balance, 'lastOpened', last_opened, 'packs', opened_count)
  );
end;
$$;

revoke all on function public.album_theme_cards(text) from public, anon, authenticated;
revoke all on function public.random_themed_album_card(text, text) from public, anon, authenticated;
revoke all on function public.open_themed_album_pack(text) from public, anon;
grant execute on function public.open_themed_album_pack(text) to authenticated;
