--
-- Top 5 of teams who won the most games.
--
  SELECT abbrev, name, count(*)
    FROM winners JOIN team ON team.id = winners.winner
   WHERE     date > '1999-08-01T00:00:00Z'
         AND date < '2000-08-01T00:00:00Z'
GROUP BY winner, abbrev, name
ORDER BY count(*) DESC;
   limit 5;

--
-- Compute how often a team wins when they record more defensive rebounds
-- than their opponent across the entire data set.
--
select count(*) as games,
       sum(case when ws.drb > ls.drb then 1 else 0 end) as drb,
       sum(case when ws.drb > ls.drb then 1 else 0 end)::float / count(*) * 100 as pct
  from winlose wl
       join team w on wl.winner = w.id
       join team l on wl.loser = l.id
       join team_stats ws on ws.game = wl.id and ws.team = wl.winner
       join team_stats ls on ls.game = wl.id and ls.team = wl.loser;


--
-- Compute what percentage of the time a team wins as a function of the
-- number of defensive rebounds they recorded.
--
with game_stats as (
    select t.id, count(*)
      from team t join game on game.host = t.id or game.guest = t.id
   group by t.id
)
select ts.team, round(avg(drb), 2) as drb,
       round(count(*) / gs.count::numeric * 100, 2) as winpct,
       count(*) as wins, gs.count as games
  from team_stats ts
       join game on game.id = ts.game
                and game.host = ts.team
                and game.host_score > game.guest_score
       join game_stats gs on gs.id = ts.team
group by ts.team, gs.count;

--
-- The team that recorded the fewest defensive rebounds in a win.
--
with stats(game, team, drb, min) as (
    select ts.game, ts.team, drb, min(drb) over ()
      from team_stats ts
           join winners w on w.id = ts.game and w.winner = ts.team
)
select game.date::date,
       host.name || ' -- ' || host_score as host,
       guest.name || ' -- ' || guest_score as guest,
       stats.drb as winner_drb
  from stats
       join game on game.id = stats.game
       join team host on host.id = game.host
       join team guest on guest.id = game.guest
 where drb = min;

--
-- Winning with least total rebounds, loosing with greatest total rebounds
--
with stats as (
    select ts.game, ts.team, trb,
           min(trb) over () as min,
           max(trb) over () as max
      from team_stats ts
           join winners w on w.id = ts.game and w.winner = ts.team
)
select game.date::date,
       host.name || ' -- ' || host_score as host,
       guest.name || ' -- ' || guest_score as guest,
       stats.trb as winner_trb
  from stats
       join game on game.id = stats.game
       join team host on host.id = game.host
       join team guest on guest.id = game.guest
 where trb = min or trb = max;

--
-- Compute rebounds histogram
--
with drb_stats as (
    select min(drb) as min,
           max(drb) as max
      from team_stats
),
     histogram as (
   select width_bucket(drb, min, max, 9) as bucket,
          int4range(min(drb), max(drb), '[]') as range,
          count(*) as freq
     from team_stats, drb_stats
 group by bucket
 order by bucket
)
 select bucket, range, freq,
        repeat('*', (freq::float / max(freq) over() * 30)::int) as bar
   from histogram;
