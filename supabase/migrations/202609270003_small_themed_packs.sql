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

  while array_length(cards, 1) < pack_size loop
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
    'pack_size', pack_size,
    'entries', entries,
    'reward', duplicate_reward,
    'daily_available', last_opened is distinct from today_local,
    'state', jsonb_build_object('owned', owned_state, 'juice', coin_balance, 'lastOpened', last_opened, 'packs', opened_count)
  );
end;
$$;

revoke all on function public.open_themed_album_pack(text) from public, anon;
grant execute on function public.open_themed_album_pack(text) to authenticated;
