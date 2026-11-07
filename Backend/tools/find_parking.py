import json
import urllib.parse
import urllib.request

q = (
    '[out:json][timeout:40];'
    '(node["amenity"="parking"](34.4175,35.8355,34.4190,35.8375);'
    'way["amenity"="parking"](34.4175,35.8355,34.4190,35.8375););'
    "out center tags;"
)
data = urllib.parse.urlencode({"data": q}).encode()
for url in [
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
]:
    try:
        req = urllib.request.Request(url, data=data, headers={"User-Agent": "SmartUni"})
        r = json.load(urllib.request.urlopen(req, timeout=40))
        print("OK", url, len(r["elements"]))
        for e in r["elements"]:
            tags = e.get("tags", {})
            if e["type"] == "node":
                print("node", e["lat"], e["lon"], tags.get("name", ""), tags)
            else:
                c = e.get("center", {})
                print(
                    "way",
                    c.get("lat"),
                    c.get("lon"),
                    tags.get("name", ""),
                    tags.get("parking", ""),
                )
        break
    except Exception as ex:  # noqa: BLE001
        print("FAIL", url, ex)
