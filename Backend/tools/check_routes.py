import json, math, heapq, os
d = json.load(open(os.path.join(os.path.dirname(__file__), "..", "..", "Frontend", "assets", "maps", "campus_paths.json")))
idx, nodes, adj, segs = {}, [], [], []
def hav(a, b):
    R = 6371000; p1, p2 = math.radians(a[0]), math.radians(b[0])
    dp = p2 - p1; dl = math.radians(b[1] - a[1])
    x = math.sin(dp/2)**2 + math.cos(p1)*math.cos(p2)*math.sin(dl/2)**2
    return 2*R*math.asin(math.sqrt(x))
def nf(p):
    k = tuple(p)
    if k not in idx:
        idx[k] = len(nodes); nodes.append(k); adj.append([])
    return idx[k]
for w in d["ways"]:
    prev = None
    for p in w["p"]:
        c = nf(p)
        if prev is not None and prev != c:
            wt = hav(nodes[prev], nodes[c]); adj[prev].append((c, wt)); adj[c].append((prev, wt)); segs.append((prev, c))
        prev = c
# components
seen, comps = set(), []
for i in range(len(nodes)):
    if i in seen: continue
    st, n = [i], 0
    while st:
        u = st.pop()
        if u in seen: continue
        seen.add(u); n += 1
        st += [v for v, _ in adj[u]]
    comps.append(n)
print("nodes", len(nodes), "segments", len(segs), "components", sorted(comps, reverse=True))
from collections import Counter
print(Counter(w["h"] for w in d["ways"]))

def snap(p):
    best = (1e9, None)
    for a, b in segs:
        A, B = nodes[a], nodes[b]
        cl = math.cos(math.radians(p[0]))
        ax, ay = (A[1]-p[1])*111320*cl, (A[0]-p[0])*110540
        bx, by = (B[1]-p[1])*111320*cl, (B[0]-p[0])*110540
        dx, dy = bx-ax, by-ay; l2 = dx*dx+dy*dy
        t = 0 if l2 == 0 else max(0, min(1, (-ax*dx-ay*dy)/l2))
        dist = math.hypot(ax+t*dx, ay+t*dy)
        if dist < best[0]: best = (dist, (a, b))
    return best
B = {"CITYU": (34.41845, 35.8354), "ADMIN": (34.41755, 35.8351), "LIB": (34.4185, 35.8364), "KABA": (34.4182, 35.8343), "SHOUMAN": (34.4195, 35.8355)}
for k, v in B.items():
    print(k, "snap dist m:", round(snap(v)[0], 1))
