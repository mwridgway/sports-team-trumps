"""Ingest the URC player pool, season stats and headshots into data/urc.db.

Source: the public GraphQL API behind unitedrugby.com (WPGraphQL).
Re-runnable: rows are upserted and existing images are skipped.

    python3 scripts/ingest_urc.py
"""
import json
import os
import sqlite3
import threading
import time
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DB_PATH = ROOT / "data" / "urc.db"
IMG_DIR = ROOT / "data" / "images" / "players"
PROGRESS_PATH = ROOT / "data" / "ingest-progress.json"
API = "https://www.unitedrugby.com/graphql"
UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36"
FORWARD_POSITIONS = {"prop", "hooker", "lock", "flanker", "no. 8"}


class Progress:
    """Per-team progress, written to data/ingest-progress.json for the urc-progress pane."""

    def __init__(self):
        self.lock = threading.Lock()
        self.state = {"status": "running", "phase": "starting", "started_at": now(), "updated_at": now(),
                      "seasons": [], "teams": {}, "error": None}
        self.write()

    def write(self):
        with self.lock:
            self.state["updated_at"] = now()
            tmp = PROGRESS_PATH.with_suffix(".tmp")
            tmp.write_text(json.dumps(self.state, indent=1))
            os.replace(tmp, PROGRESS_PATH)

    def set(self, **kw):
        with self.lock:
            self.state.update(kw)
        self.write()

    def team(self, tid, **kw):
        with self.lock:
            self.state["teams"].setdefault(str(tid), {}).update(kw)
        self.write()


def now():
    return time.strftime("%Y-%m-%d %H:%M:%S")


def gql(query, variables=None, retries=3):
    body = json.dumps({"query": query, "variables": variables or {}}).encode()
    req = urllib.request.Request(API, data=body, headers={"Content-Type": "application/json", "User-Agent": UA})
    for attempt in range(retries):
        try:
            resp = json.load(urllib.request.urlopen(req, timeout=60))
            if resp.get("errors"):
                raise RuntimeError(resp["errors"])
            return resp["data"]
        except (OSError, json.JSONDecodeError):
            if attempt == retries - 1:
                raise
            time.sleep(2 ** attempt)


def base_type(t):
    while t["kind"] in ("NON_NULL", "LIST"):
        t = t["ofType"]
    return t


def stat_fields():
    """Return {category: [field, ...]} for every stat the API exposes."""
    q = "query($n:String!){__type(name:$n){fields{name type{name kind ofType{name kind ofType{name kind}}}}}}"
    cats = {}
    for f in gql(q, {"n": "Player_statsPlayerStatsType"})["__type"]["fields"]:
        sub = gql(q, {"n": base_type(f["type"])["name"]})["__type"]["fields"]
        cats[f["name"]] = [s["name"] for s in sub if base_type(s["type"])["kind"] == "SCALAR"]
    return cats


def create_schema(db, cats):
    stat_cols = ",\n  ".join(f"{c}_{f} NUMERIC" for c, fs in cats.items() for f in fs)
    db.executescript(f"""
CREATE TABLE IF NOT EXISTS clubs (
  id INTEGER PRIMARY KEY,
  full_name TEXT, short_name TEXT, country TEXT, home_ground TEXT, founded_year TEXT,
  color_primary TEXT, color_secondary TEXT, logo_light_url TEXT, logo_dark_url TEXT, club_site TEXT
);
CREATE TABLE IF NOT EXISTS players (
  id INTEGER PRIMARY KEY,
  club_id INTEGER REFERENCES clubs(id),
  first_name TEXT, last_name TEXT, slug TEXT,
  position TEXT, position_group TEXT,
  date_of_birth TEXT, age INTEGER,
  height_cm INTEGER, height_ft TEXT, weight_kg INTEGER,
  birth_country TEXT, birthplace TEXT, national_team TEXT,
  urc_debut TEXT, games_started INTEGER,
  headshot_url TEXT, image_path TEXT,
  updated_at TEXT
);
DROP TABLE IF EXISTS player_season_stats;
CREATE TABLE player_season_stats (
  player_id INTEGER,
  season_id TEXT,
  team_id INTEGER,
  season_name TEXT, team_name TEXT, player_name TEXT, position TEXT, last_updated TEXT,
  {stat_cols},
  PRIMARY KEY (player_id, season_id, team_id)
);
CREATE INDEX IF NOT EXISTS idx_pss_season ON player_season_stats(season_id);
""")


def ingest_clubs(db, progress):
    clubs = gql("""{clubThemeSettings{clubs{id fullName shortName foundedYear clubSite
        countryDetails{countryName} homeGrounds{homeGround}
        color{clubColorPrimary clubColorSecondary} logo{clubLogoLight clubLogoDark}}}}""")["clubThemeSettings"]["clubs"]
    for c in clubs:
        db.execute("INSERT OR REPLACE INTO clubs VALUES (?,?,?,?,?,?,?,?,?,?,?)", (
            c["id"], c["fullName"], c["shortName"], (c["countryDetails"] or {}).get("countryName"),
            ((c["homeGrounds"] or [{}])[0] or {}).get("homeGround"), c["foundedYear"],
            (c["color"] or {}).get("clubColorPrimary"), (c["color"] or {}).get("clubColorSecondary"),
            (c["logo"] or {}).get("clubLogoLight"), (c["logo"] or {}).get("clubLogoDark"), c["clubSite"]))
        progress.team(c["id"], name=c["fullName"], short=c["shortName"], squad=None, stats={},
                      images={"done": 0, "total": None, "failed": 0})
    return [c["id"] for c in clubs]


def to_int(v):
    try:
        return int(float(v))
    except (TypeError, ValueError):
        return None


def ingest_players(db, club_ids, progress):
    q = """query($c:[String]){playerThemeSettings(currentClub:$c){squads{currentClub squad{
        playerId playerFirstName playerLastName knownName playerPosition dateOfBirth playerAge
        playerHeight playerHeightCm playerWeight birthcountry birthplace nationalTeam urcDebut
        gamesStarted headshots}}}}"""
    db.execute("DELETE FROM players")
    for cid in club_ids:
        count = 0
        for squad in gql(q, {"c": [str(cid)]})["playerThemeSettings"]["squads"]:
            for p in squad["squad"]:
                pos = (p["playerPosition"] or "").lower() or None
                db.execute("INSERT OR REPLACE INTO players VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", (
                    p["playerId"], int(squad["currentClub"]), p["playerFirstName"], p["playerLastName"], p["knownName"],
                    pos, None if pos is None else ("forward" if pos in FORWARD_POSITIONS else "back"),
                    p["dateOfBirth"], p["playerAge"], p["playerHeightCm"], p["playerHeight"], to_int(p["playerWeight"]),
                    p["birthcountry"], p["birthplace"], p["nationalTeam"], p["urcDebut"], p["gamesStarted"],
                    p["headshots"] or None, None, now()))
                count += 1
        progress.team(cid, squad=count)
        time.sleep(0.3)


def ingest_stats(db, club_ids, cats, progress):
    seasons = gql("{seasonsConfiguration{seasons{key label}}}")["seasonsConfiguration"]["seasons"]
    progress.set(seasons=[x["label"] for x in seasons])
    sel = " ".join(f"{c}{{{' '.join(fs)}}}" for c, fs in cats.items())
    q = f"""query($t:[Int],$s:[Int]){{playerseasonstats(team_id:$t, season_id:$s, limit:1000){{
        player_id player_name season_id season_name team_id team_name last_updated
        player_stats{{normalPosition{{name}} playerStats{{{sel}}}}}}}}}"""
    cols = [f"{c}_{f}" for c, fs in cats.items() for f in fs]
    sql = (f"INSERT OR REPLACE INTO player_season_stats (player_id, season_id, team_id, season_name, team_name, "
           f"player_name, position, last_updated, {', '.join(cols)}) VALUES ({', '.join('?' * (8 + len(cols)))})")
    for season in seasons:
        s, n = season["key"], 0
        for cid in club_ids:
            rows = 0
            for r in gql(q, {"t": [cid], "s": [int(s)]})["playerseasonstats"] or []:
                ps = r["player_stats"] or {}
                st = ps.get("playerStats") or {}
                vals = [(st.get(c) or {}).get(f) for c, fs in cats.items() for f in fs]
                db.execute(sql, [r["player_id"], r["season_id"], r["team_id"], r["season_name"], r["team_name"],
                                 r["player_name"], (ps.get("normalPosition") or {}).get("name"), r["last_updated"], *vals])
                n += 1
                rows += 1
            progress.state["teams"][str(cid)]["stats"][season["label"]] = rows
            progress.write()
            time.sleep(0.3)
        print(f"  season {s}: {n} player-season rows")


def download_images(db, progress):
    IMG_DIR.mkdir(parents=True, exist_ok=True)
    rows = db.execute("SELECT id, headshot_url, club_id FROM players WHERE headshot_url IS NOT NULL").fetchall()
    for (cid,) in db.execute("SELECT id FROM clubs"):
        progress.state["teams"][str(cid)]["images"]["total"] = sum(1 for r in rows if r[2] == cid)
    progress.write()

    def fetch(row):
        pid, url, cid = row
        result = _fetch(pid, url)
        with progress.lock:
            img = progress.state["teams"][str(cid)]["images"]
            img["done" if result[2] is None else "failed"] += 1
        progress.write()
        return result

    def _fetch(pid, url):
        ext = Path(urllib.parse.urlparse(url).path).suffix or ".webp"
        dest = IMG_DIR / f"{pid}{ext}"
        if not dest.exists() or dest.stat().st_size == 0:
            try:
                req = urllib.request.Request(urllib.parse.quote(url, safe=":/%?=&"), headers={"User-Agent": UA})
                dest.write_bytes(urllib.request.urlopen(req, timeout=60).read())
            except OSError as e:
                return pid, None, str(e)
        return pid, str(dest.relative_to(ROOT)), None

    with ThreadPoolExecutor(8) as pool:
        results = list(pool.map(fetch, rows))
    for pid, path, _ in results:
        db.execute("UPDATE players SET image_path = ? WHERE id = ?", (path, pid))
    failed = [(pid, err) for pid, path, err in results if err]
    print(f"  images: {len(results) - len(failed)} saved, {len(failed)} failed")
    for pid, err in failed:
        print(f"    player {pid}: {err}")


def create_views(db):
    db.executescript(open(ROOT / "scripts" / "views.sql").read())


def main():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    progress = Progress()
    db = sqlite3.connect(DB_PATH)
    try:
        print("introspecting stat fields...")
        progress.set(phase="schema")
        cats = stat_fields()
        create_schema(db, cats)
        print("clubs...")
        progress.set(phase="clubs")
        club_ids = ingest_clubs(db, progress)
        print("players...")
        progress.set(phase="players")
        ingest_players(db, club_ids, progress)
        print("stats...")
        progress.set(phase="stats")
        ingest_stats(db, club_ids, cats, progress)
        db.commit()
        print("images...")
        progress.set(phase="images")
        download_images(db, progress)
        create_views(db)
        db.commit()
        totals = {t: db.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0]
                  for t in ("clubs", "players", "player_season_stats")}
        for t, n in totals.items():
            print(f"{t}: {n}")
        progress.set(status="done", phase="done", totals=totals)
    except Exception as e:
        progress.set(status="error", error=repr(e))
        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()
