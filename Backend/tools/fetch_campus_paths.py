"""
Fetch walkable OSM ways around CityU Abi Samra and write a compact JSON asset
for the Flutter app (offline routing along the real white paths).

Usage:  python Backend/tools/fetch_campus_paths.py
Output: Frontend/assets/maps/campus_paths.json
"""
import json
import os
import urllib.parse
import urllib.request

BBOX = (34.4160, 35.8322, 34.4205, 35.8382)  # south, west, north, east
OUT = os.path.join(
    os.path.dirname(__file__), "..", "..", "Frontend", "assets", "maps", "campus_paths.json"
)

QUERY = (
    '[out:json][timeout:60];'
    '(way["highway"]["highway"!~"motorway|trunk|motorway_link|trunk_link|construction|proposed|raceway"]'
    "(%s,%s,%s,%s););out geom;" % BBOX
)

SERVERS = [
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
    "https://overpass.private.coffee/api/interpreter",
]


def main():
    data = urllib.parse.urlencode({"data": QUERY}).encode()
    result = None
    for attempt in range(3):
        for url in SERVERS:
            try:
                req = urllib.request.Request(url, data=data, headers={"User-Agent": "SmartUni-FYP"})
                result = json.load(urllib.request.urlopen(req, timeout=40))
                print("OK", url, len(result["elements"]), "ways", flush=True)
                break
            except Exception as e:  # noqa: BLE001
                print("FAIL", attempt, url, e, flush=True)
        if result is not None:
            break
    if result is None:
        raise SystemExit("All Overpass servers failed")

    ways = []
    for el in result["elements"]:
        if el.get("type") != "way" or "geometry" not in el:
            continue
        ways.append(
            {
                "id": el["id"],
                "h": el.get("tags", {}).get("highway", ""),
                "n": el["nodes"],
                "p": [[round(g["lat"], 6), round(g["lon"], 6)] for g in el["geometry"]],
            }
        )
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w") as f:
        json.dump({"ways": ways}, f, separators=(",", ":"))
    print("wrote", os.path.normpath(OUT), len(ways), "ways")


if __name__ == "__main__":
    main()
