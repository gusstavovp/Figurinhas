create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 80),
  email text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.album_progress (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  owned jsonb not null default '{}'::jsonb,
  coins integer not null default 0 check (coins >= 0),
  last_daily_pack date,
  packs_opened integer not null default 0 check (packs_opened >= 0),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.album_progress enable row level security;

create policy "Users read own profile" on public.profiles
for select to authenticated using (auth.uid() is not null and auth.uid() = id);

create policy "Users update own profile" on public.profiles
for update to authenticated using (auth.uid() is not null and auth.uid() = id)
with check (auth.uid() is not null and auth.uid() = id);

create policy "Users read own album" on public.album_progress
for select to authenticated using (auth.uid() is not null and auth.uid() = user_id);

create or replace function public.handle_new_album_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, name, email)
  values (new.id, coalesce(nullif(trim(new.raw_user_meta_data ->> 'name'), ''), split_part(new.email, '@', 1)), new.email);
  insert into public.album_progress (user_id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_album_user();

create or replace function public.choose_album_pack_tier()
returns text
language plpgsql volatile
as $$
declare roll numeric := random() * 100;
begin
  return case
    when roll < 65 then 'common'
    when roll < 85 then 'uncommon'
    when roll < 93 then 'rare'
    when roll < 97 then 'epic'
    when roll < 99 then 'mythic'
    when roll < 99.8 then 'legendary'
    else 'secret'
  end;
end;
$$;

create or replace function public.random_album_card(p_rarity text)
returns integer
language plpgsql volatile
as $$
declare first_id integer; last_id integer;
begin
  select range_start, range_end into first_id, last_id
  from (values
    ('common',1,45),('uncommon',46,69),('rare',70,83),('epic',84,91),
    ('mythic',92,95),('legendary',96,97),('secret',98,100)
  ) as ranges(rarity, range_start, range_end)
  where rarity = p_rarity;
  if first_id is null then raise exception 'Raridade inválida'; end if;
  return first_id + floor(random() * (last_id - first_id + 1))::integer;
end;
$$;

create or replace function public.album_card_reward(p_card integer)
returns integer
language sql immutable
as $$
  select case
    when p_card between 1 and 45 then 2
    when p_card between 46 and 69 then 4
    when p_card between 70 and 83 then 7
    when p_card between 84 and 91 then 12
    when p_card between 92 and 95 then 20
    when p_card between 96 and 97 then 35
    when p_card between 98 and 100 then 60
    else 0 end;
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

revoke all on function public.open_album_pack(text) from public, anon;
grant execute on function public.open_album_pack(text) to authenticated;
revoke all on function public.choose_album_pack_tier() from public, anon, authenticated;
revoke all on function public.random_album_card(text) from public, anon, authenticated;
revoke all on function public.album_card_reward(integer) from public, anon, authenticated;
