"""Export the iOS app's bundled game data from data/urc.db plus this season's URC match stats.

Writes ios/URCTrumps/Resources/GameData/urc.json and ios/URCTrumps/Resources/GameData/headshots/<id>.jpg.
Run after scripts/ingest_urc.py. Stdlib only, plus macOS `sips` for image resizing.
"""
import json
import os
import sqlite3
import subprocess
import sys
import urllib.request
from datetime import datetime, timezone

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB = os.path.join(ROOT, "data", "urc.db")
OUT = os.path.join(ROOT, "ios", "URCTrumps", "Resources", "GameData")
SEASON_ID = 202601
SEASON_NAME = "2026/27"
MIN_APPEARANCES = 10
IMAGE_PX = 480

GQL = "https://www.unitedrugby.com/graphql"
UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36"

CLUB_COLORS = {
    "LEI": "#1d4f9e", "MUN": "#b11226", "ULS": "#9e1b32", "CON": "#00703c", "GLA": "#1c2b48", "EDI": "#7a1f3d",
    "SCA": "#a3122a", "OSP": "#24272b", "DRA": "#b8341f", "CAR": "#1f6fa6", "BEN": "#0b6b3a", "ZEB": "#3b3d45",
    "BUL": "#1f4691", "STO": "#2a7fc2", "SHA": "#141414", "LIO": "#d41f2a",
}

CATEGORIES = [
    {"key": "height_cm", "label": "Height", "unit": "cm"},
    {"key": "weight_kg", "label": "Weight", "unit": "kg"},
    {"key": "tackles", "label": "Tackles", "unit": None},
    {"key": "tries", "label": "Tries", "unit": None},
    {"key": "metres_made", "label": "Metres made", "unit": "m"},
    {"key": "points", "label": "Points", "unit": None},
]

MATCH_PLAYER_FIELDS = (
    "players{ id stats{ scoring{minutesPlayed tryScored points} "
    "defence{tackle missedTackle turnoverWon} "
    "attack{carries metresMade cleanBreak defenderBeaten offload tryAssist} } }"
)


def gql(query):
    req = urllib.request.Request(
        GQL,
        data=json.dumps({"query": query}).encode(),
        headers={"Content-Type": "application/json", "User-Agent": UA},
    )
    body = json.load(urllib.request.urlopen(req, timeout=90))
    if body.get("errors"):
        raise RuntimeError(body["errors"])
    return body["data"]


def num(v):
    return int(v) if v is not None else 0


def fetch_club_matches(club_id):
    q = (
        "{matchstats(team_id:[%d], season_id:[%d]){match_id match_datetime match_status venue "
        "home_team_id away_team_id home_team_name away_team_name home_score away_score "
        "stats_data{ round homeTeam{ %s } awayTeam{ %s } } }}"
    ) % (club_id, SEASON_ID, MATCH_PLAYER_FIELDS, MATCH_PLAYER_FIELDS)
    return gql(q)["matchstats"] or []


def main():
    db = sqlite3.connect(DB)
    db.row_factory = sqlite3.Row
    clubs = {r["id"]: r for r in db.execute("SELECT id, full_name, short_name FROM clubs")}
    short_to_id = {r["short_name"]: r["id"] for r in clubs.values()}
    pool = [dict(r) for r in db.execute("SELECT * FROM player_cards")]

    # Leaders across the whole current player pool; ties all lead.
    leaders = {}
    for cat in CATEGORIES:
        k = cat["key"]
        best = max((p[k] or 0) for p in pool)
        leaders[k] = sorted(p["player_id"] for p in pool if (p[k] or 0) == best and best > 0)
    leader_ids = {pid for ids in leaders.values() for pid in ids}

    chosen = [
        p for p in pool
        if p["player_id"] in leader_ids or ((p["appearances"] or 0) >= MIN_APPEARANCES and p["image_path"])
    ]
    chosen_ids = {p["player_id"] for p in chosen}

    career = {}
    for r in db.execute(
        "SELECT player_id, season_id, season_name, team_name, appearances, minutes_played, points, tries, "
        "tackles, metres_made, carries, turnovers_won FROM player_key_stats ORDER BY season_id DESC"
    ):
        if r["player_id"] in chosen_ids:
            career.setdefault(r["player_id"], []).append({
                "season": r["season_name"], "team": r["team_name"], "appearances": num(r["appearances"]),
                "minutes": num(r["minutes_played"]), "points": num(r["points"]), "tries": num(r["tries"]),
                "tackles": num(r["tackles"]), "metres": num(r["metres_made"]), "carries": num(r["carries"]),
                "turnovers_won": num(r["turnovers_won"]),
            })

    # Per-match rows this season, keyed by player, for every fixture of the player's current club.
    season = {pid: [] for pid in chosen_ids}
    club_of = {p["player_id"]: short_to_id.get(p["club_short"]) for p in chosen}
    for club_id, club in clubs.items():
        matches = sorted(fetch_club_matches(club_id), key=lambda m: m["match_datetime"] or "")
        print(f"{club['short_name']}: {len(matches)} fixtures", flush=True)
        for m in matches:
            home = m["home_team_id"] == club_id
            sd = m["stats_data"] or {}
            lines = {}
            for side in ("homeTeam", "awayTeam"):
                for pl in ((sd.get(side) or {}).get("players") or []):
                    lines[pl["id"]] = pl["stats"] or {}
            base = {
                "match_id": m["match_id"], "round": sd.get("round"), "kickoff": m["match_datetime"],
                "status": m["match_status"], "home": home, "venue": m["venue"],
                "opponent": m["away_team_name"] if home else m["home_team_name"],
                "score_for": m["home_score"] if home else m["away_score"],
                "score_against": m["away_score"] if home else m["home_score"],
            }
            for pid, cid in club_of.items():
                if cid != club_id:
                    continue
                s = lines.get(pid)
                row = dict(base, played=s is not None)
                if s:
                    sc, de, at = s.get("scoring") or {}, s.get("defence") or {}, s.get("attack") or {}
                    row.update({
                        "minutes": num(sc.get("minutesPlayed")), "tries": num(sc.get("tryScored")),
                        "points": num(sc.get("points")), "tackles": num(de.get("tackle")),
                        "missed_tackles": num(de.get("missedTackle")), "turnovers_won": num(de.get("turnoverWon")),
                        "carries": num(at.get("carries")), "metres": num(at.get("metresMade")),
                        "clean_breaks": num(at.get("cleanBreak")), "defenders_beaten": num(at.get("defenderBeaten")),
                        "offloads": num(at.get("offload")), "try_assists": num(at.get("tryAssist")),
                    })
                season[pid].append(row)

    img_dir = os.path.join(OUT, "headshots")
    os.makedirs(img_dir, exist_ok=True)
    players = []
    for p in chosen:
        pid = p["player_id"]
        image = None
        if p["image_path"]:
            src = os.path.join(ROOT, p["image_path"])
            dst = os.path.join(img_dir, f"{pid}.jpg")
            if not os.path.exists(dst):
                subprocess.run(
                    ["sips", "-s", "format", "jpeg", "-s", "formatOptions", "70", "-Z", str(IMAGE_PX), src, "--out", dst],
                    check=True, capture_output=True,
                )
            image = f"{pid}.jpg"
        players.append({
            "id": pid, "first_name": p["first_name"], "last_name": p["last_name"],
            "club": p["club"], "club_short": p["club_short"], "club_color": CLUB_COLORS.get(p["club_short"], "#2b4436"),
            "position": p["position"], "position_group": p["position_group"], "age": p["age"],
            "date_of_birth": p["date_of_birth"], "birth_country": p["birth_country"],
            "national_team": p["national_team"] or None, "appearances": num(p["appearances"]),
            "stats": {c["key"]: num(p[c["key"]]) for c in CATEGORIES},
            "image": image, "career": career.get(pid, []), "season_matches": season.get(pid, []),
        })

    played_rounds = [
        r["round"] for rows in season.values() for r in rows if r["status"] == "result" and r["round"] is not None
    ]
    doc = {
        "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "season": SEASON_NAME, "latest_round": max(played_rounds) if played_rounds else 0,
        "pool_size": len(pool), "categories": CATEGORIES, "leaders": leaders,
        "players": sorted(players, key=lambda x: x["id"]),
    }
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "urc.json"), "w") as f:
        json.dump(doc, f, separators=(",", ":"))
    print(f"wrote {len(players)} players, leaders {leaders}, latest round {doc['latest_round']}")


if __name__ == "__main__":
    sys.exit(main())
