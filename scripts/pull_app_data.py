"""Download the published game data from Vercel Blob into the iOS app's GameData folder.

The data job (.github/workflows/data.yml) publishes it; TestFlight builds bundle whatever is there.
"""
import json
import os
import urllib.request
from concurrent.futures import ThreadPoolExecutor

BASE = "https://6etdo42jowwnvfxi.public.blob.vercel-storage.com/urc"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "ios", "URCTrumps", "Resources", "GameData")


def fetch(url):
    with urllib.request.urlopen(url, timeout=60) as r:
        return r.read()


def main():
    os.makedirs(os.path.join(OUT, "headshots"), exist_ok=True)
    raw = fetch(f"{BASE}/latest.json")
    doc = json.loads(raw)
    with open(os.path.join(OUT, "urc.json"), "wb") as f:
        f.write(raw)

    def save(image):
        with open(os.path.join(OUT, "headshots", image), "wb") as f:
            f.write(fetch(f"{BASE}/headshots/{image}"))

    images = [p["image"] for p in doc["players"] if p["image"]]
    with ThreadPoolExecutor(16) as pool:
        list(pool.map(save, images))
    print(f"pulled {len(doc['players'])} players and {len(images)} headshots (data from {doc['generated_at']})")


if __name__ == "__main__":
    main()
