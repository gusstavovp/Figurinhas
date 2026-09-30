create or replace function pv_economy.adjust_market() returns void language plpgsql set search_path='' as $$
declare m pv_economy.market;idx numeric;cnt integer;target numeric;next_rate numeric;
begin select * into m from pv_economy.market where id=true;if clock_timestamp()<m.last_adjustment+interval '24 hours' then return;end if;select * into m from pv_economy.market where id=true for update;
if clock_timestamp()<m.last_adjustment+interval '24 hours' then return;end if;
-- Median of capped log wealth: one account cannot dominate the index.
select count(*),exp(percentile_cont(.5) within group(order by ln(1+least(1000000000000000::numeric,greatest(0,coalesce((c.state->>'juice')::numeric,0))))))-1 into cnt,idx
from public.clicker_progress c join public.profiles p on p.id=c.user_id where p.created_at<now()-interval '7 days' and c.updated_at>now()-interval '30 days';
if cnt<5 then update pv_economy.market set last_adjustment=clock_timestamp(),participants=cnt where id=true;return;end if;
if m.baseline is null then update pv_economy.market set baseline=greatest(idx,1000000000),current_index=idx,participants=cnt,last_adjustment=clock_timestamp() where id=true;return;end if;
target:=least(100000000000,greatest(1000000000,1000000000*sqrt(greatest(1,idx)/m.baseline)));
next_rate:=round(greatest(m.rate*.95,least(m.rate*1.05,m.rate*.9+target*.1)));
update pv_economy.market set rate=next_rate,version=version+1,current_index=idx,participants=cnt,last_adjustment=clock_timestamp() where id=true;
insert into pv_economy.market_history(rate,wealth_index,participants) values(next_rate,idx,cnt);
end $$;
create or replace function pv_economy.snapshot(uid uuid) returns jsonb language plpgsql set search_path='' as $$
declare w pv_economy.wallets;m pv_economy.market;r pv_economy.rounds;lots jsonb;hist jsonb;rates jsonb;
begin select * into w from pv_economy.wallets where user_id=uid;select * into m from pv_economy.market where id=true;
select * into r from pv_economy.rounds where user_id=uid order by (status='active') desc,started_at desc limit 1;
if found and r.status='active' and r.game='crash' and exp(extract(epoch from clock_timestamp()-r.started_at)*.14)>=r.crash_point then perform pv_economy.finish_round(r.id,0,r.crash_point);select * into w from pv_economy.wallets where user_id=uid;end if;
select coalesce(jsonb_agg(x),'[]') into lots from (select id,source,remaining,rate::text rate,created_at from pv_economy.lots where user_id=uid and remaining>0 order by id limit 100) x;
select coalesce(jsonb_agg(x),'[]') into hist from (select kind,bean_delta,balance_after,details,created_at from pv_economy.ledger where user_id=uid order by created_at desc,id limit 30) x;
select coalesce(jsonb_agg(x),'[]') into rates from (select rate::text rate,wealth_index::text wealth_index,participants,created_at from pv_economy.market_history order by id desc limit 14) x;
return jsonb_build_object('balance',w.balance,'principal',w.principal,'cycle',w.cycle,'revision',w.revision,'required',ceil(w.principal*1.35),'missing',greatest(0,ceil(w.principal*1.35)-w.balance),'album_unlocked',w.principal>0 and w.balance>=ceil(w.principal*1.35),'rate',m.rate::text,'market_version',m.version,'market',jsonb_build_object('baseline',m.baseline::text,'wealth_index',m.current_index::text,'participants',m.participants,'last_adjustment',m.last_adjustment,'history',rates),'lots',lots,'history',hist,'round',case when r.id is not null then pv_economy.round_view(r.id) else null end,'owned',(select owned from public.album_progress where user_id=uid),'album_coins',(select coins from public.album_progress where user_id=uid),'clicker_coins',(select (state->>'juice') from public.clicker_progress where user_id=uid));end $$;
