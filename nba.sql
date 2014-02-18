---
--- Relational model design for NBA data set.
---

drop schema if exists nba;
create schema nba;

alter database nba set search_path to nba; -- WARNING: hardcoded database name!

create table nba.team (
  id        serial primary key,
  name      text unique,
  abbrev    text
);

create table nba.player (
  id          serial primary key,
  name        text
);

create table nba.game (
  id          serial primary key,
  date        timestamptz,
  host        int references nba.team(id),
  guest       int references nba.team(id),
  host_score  int,
  guest_score int
);

create view nba.winners as
  select id,
         date,
         case when host_score > guest_score
              then host
              else guest
          end as winner
    from nba.game;

create view nba.winlose as
   select id, date,
         case when host_score > guest_score
              then host
              else guest
          end as winner,
         case when host_score > guest_score
              then host_score
              else guest_score
          end as winner_score,
         case when host_score > guest_score
              then guest
              else host
          end as loser,
         case when host_score > guest_score
              then guest_score
              else host_score
          end as loser_score
     from nba.game;


create table nba.player_stats (
  game        int references nba.game(id),
  player      int references nba.player(id),
  ast         int,
  blk         int,
  drb         int,
  fg          int,
  fg3         int,
  fg3_pct     numeric,
  fg3a        int,
  fg_pct      numeric,
  fga         int,
  ft          int,
  ft_pct      numeric,
  fta         int,
  mp          text,
  orb         int,
  pf          int,
  pts         int ,
  stl         int,
  tov         int,
  trb         int,
  primary key(game, player)
);

create table nba.team_stats (
  game        int references nba.game(id),
  team        int references nba.team(id),
  ast         int,
  blk         int,
  drb         int,
  fg          int,
  fg3         int,
  fg3_pct     numeric,
  fg3a        int,
  fg_pct      numeric,
  fga         int,
  ft          int,
  ft_pct      numeric,
  fta         int,
  mp          text,
  orb         int,
  pf          int,
  pts         int ,
  stl         int,
  tov         int,
  trb         int,
  primary key(game, team)
);
