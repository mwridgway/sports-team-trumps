---
name: urc-player-ingest
description: Use when fetching, refreshing or querying the United Rugby Championship (URC) player pool, player stats or player headshots for this project, when data/urc.db is missing or stale, or when the user mentions URC squads, URC stats, unitedrugby.com, or the trump-card player data.
---

# URC player ingest

Pulls every current URC squad (16 clubs), each player's bio, every stat the URC exposes per season, and each player's headshot into `data/urc.db` (SQLite) and `data/images/players/`.

## Run it

```bash
mkdir -p data && python3 -u scripts/ingest_urc.py > data/ingest.log 2>&1
```

- Run it with the harness's background mode. It takes a few minutes, so don't hand-roll a wait loop.
- It is safe to re-run: `clubs` and `players` are rebuilt, `player_season_stats` is dropped and recreated, and images already on disk are skipped.
- Progress is written to `data/ingest-progress.json` per team: squad count, stat rows per season, and images done/total/failed. The `urc-progress` mod draws it as a side pane. Open it with `/urc-progress`; it also opens by itself when a run starts.
- Stdlib Python only. No API key needed.

## Verify after a run (don't trust the log alone)

```bash
sqlite3 data/urc.db "SELECT c.short_name, COUNT(p.id) FROM clubs c LEFT JOIN players p ON p.club_id=c.id GROUP BY c.id;"
sqlite3 data/urc.db "SELECT season_name, COUNT(*) FROM player_season_stats GROUP BY 1;"
sqlite3 data/urc.db "SELECT COUNT(*), SUM(image_path IS NOT NULL) FROM players;"
ls data/images/players | wc -l
```

Expect 16 clubs at roughly 45–65 players each. Compare one player against their profile page at `https://stats.unitedrugby.com/clubs/<club-slug>/<player-slug>` (for example jack-conan: 9 tackles and 82% for 2026/27).

## Data source

The URC site (`stats.unitedrugby.com`, which the www site redirects to) is a SPA backed by **WPGraphQL at `https://www.unitedrugby.com/graphql`**.

- HTML pages are behind Cloudflare and block curl. The GraphQL endpoint accepts plain POSTs with a browser User-Agent.
- Introspection is open, and so are arbitrary (non-persisted) queries. The site's persisted queries select only a subset of fields, so query the full set yourself; the script builds its selection from introspection.

| Query | Gives |
| --- | --- |
| `clubThemeSettings { clubs { id fullName shortName ... } }` | the 16 clubs with IDs, colours and logos |
| `playerThemeSettings(currentClub: ["<clubId>"]) { squads { squad { ... } } }` | the current squad with bio: DOB, age, height cm/ft, weight, birth country, national team, URC debut, headshot URL |
| `playerseasonstats(team_id: [id], season_id: [202601], limit: 1000)` | one row per player per team per season; `player_stats.playerStats` has the attack, defence, discipline, kicking, lineout, scrum, restart, ballReception and scoring groups (about 150 fields) |
| `seasonsConfiguration { seasons { key label } }` | season keys from `202601` (2026/27) back to `202101` (2021/22) |

## Gotchas

- The top-level `matches_played` and `minutes_played` on `playerseasonstats` are always 0. Use `scoring.appearances` and `scoring.minutesPlayed`.
- Stat fields with no events come back `null`, not 0. The views COALESCE them.
- `player_season_stats` also holds players who have since left the URC; there is no bio for them. "The player pool" means the `players` table (current squads).
- The current season is in progress, so its numbers change week to week. Re-run to refresh.
- National caps aren't in this API. If you need them, find them with web search (Exa).

## Schema

- `clubs`: id, names, country, ground, colours, logo URLs.
- `players`: current squad member, bio, `position_group` (forward/back), `headshot_url`, `image_path` (relative to the repo root).
- `player_season_stats`: every stat as a column named `<group>_<field>` (for example `attack_metresMade`, `defence_percentTackleMade`); PK is (player_id, season_id, team_id).
- View `player_key_stats`: readable key stats per player-season.
- View `player_cards`: one row per current player, with bio plus URC totals over every season held (tries, carries, metres, clean breaks, defenders beaten, offloads, tackles, tackle %, turnovers, lineouts, goal-kick %, kick metres, cards...). This is the trump-card source.

The views live in `scripts/views.sql` and are re-applied on every run.
