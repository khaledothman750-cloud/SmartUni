/**
 * Author / Project Supervisor : Omar Terro
 * GitHub                      : https://github.com/IOTERRO
 * Website                     : https://omarterro.fr
 * Student (FYP)               : Khaled Othman
 * Date                        : 14 October 2026
 * Project                     : SmartUni - Smart University CityU
 */
/**
 * Smart University Worker — Locations / Navigation API
 *
 * Cloudflare bindings required:
 *   - D1 Database: env.DB  →  cityu
 *   - Secret:      env.API_KEY
 *
 * URL: https://navigation.khaledothman750.workers.dev
 * Matches docs/05_CLOUDFLARE_LOCATIONS_DB.md
 *
 * Paste this file into: Workers → navigation → Edit code
 */

export default {
  async fetch(request, env) {
    try {
      // CORS preflight (Flutter web)
      if (request.method === "OPTIONS") {
        return cors(new Response(null, { status: 204 }));
      }

      if (!authorize(request, env)) {
        return json({ success: false, error: "Unauthorized access" }, 401);
      }

      if (!env.DB) {
        return json(
          {
            success: false,
            error: "D1 binding DB is missing. Bind database cityu as variable DB.",
          },
          500
        );
      }

      const url = new URL(request.url);
      const path = normalizePath(url.pathname);
      const method = request.method.toUpperCase();

      // -------- Locations --------
      if (method === "GET" && path === "/api/locations") {
        return cors(await listLocations(env.DB));
      }

      if (method === "GET" && path === "/api/locations/search") {
        return cors(await searchLocations(env.DB, url.searchParams.get("q") || ""));
      }

      if (method === "POST" && path === "/api/locations") {
        const body = await readJson(request);
        return cors(await createLocation(env.DB, body));
      }

      // PUT /api/locations/:id
      let match = path.match(/^\/api\/locations\/(\d+)$/);
      if (method === "PUT" && match) {
        const body = await readJson(request);
        return cors(await updateLocation(env.DB, Number(match[1]), body));
      }

      // DELETE /api/locations/:id
      if (method === "DELETE" && match) {
        return cors(await deleteLocation(env.DB, Number(match[1])));
      }

      // -------- Navigation --------
      if (method === "GET" && path === "/api/navigation") {
        const from = url.searchParams.get("from");
        const to = url.searchParams.get("to");
        return cors(await findRoute(env.DB, from, to));
      }

      // Rebuild walkway ring + edges (blue line follows campus roads)
      if (method === "POST" && path === "/api/admin/seed-walkways") {
        return cors(await seedWalkwayGraph(env.DB));
      }

      // -------- Health (still requires API key) --------
      if (method === "GET" && (path === "/" || path === "/api/health")) {
        return json({
          success: true,
          service: "navigation",
          database: "cityu",
          endpoints: [
            "GET /api/locations",
            "GET /api/locations/search?q=",
            "GET /api/navigation?from=&to=",
            "POST /api/locations",
            "PUT /api/locations/:id",
            "DELETE /api/locations/:id",
            "POST /api/admin/seed-walkways",
          ],
        });
      }

      return json({ success: false, error: "Not found", path }, 404);
    } catch (err) {
      return json(
        {
          success: false,
          error: err?.message || String(err),
        },
        500
      );
    }
  },
};

// =============================================================================
// Auth / HTTP helpers
// =============================================================================

function authorize(request, env) {
  const expectedKey = env.API_KEY;
  const providedKey = request.headers.get("X-API-Key");
  return Boolean(expectedKey && providedKey && providedKey === expectedKey);
}

function normalizePath(pathname) {
  if (!pathname) return "/";
  // remove trailing slash except root
  return pathname.length > 1 && pathname.endsWith("/")
    ? pathname.slice(0, -1)
    : pathname;
}

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, X-API-Key, Authorization",
    "Access-Control-Max-Age": "86400",
  };
}

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders(),
    },
  });
}

function cors(response) {
  const headers = new Headers(response.headers);
  for (const [k, v] of Object.entries(corsHeaders())) {
    headers.set(k, v);
  }
  return new Response(response.body, {
    status: response.status,
    headers,
  });
}

async function readJson(request) {
  try {
    return await request.json();
  } catch {
    throw new Error("Invalid JSON body");
  }
}

// =============================================================================
// Locations CRUD
// =============================================================================

function mapLocation(row) {
  const code = row.code ?? null;
  // Prefer real D1 id; if missing, expose code so clients can still key the node.
  const id = row.id !== undefined && row.id !== null ? row.id : code;
  return {
    id,
    code,
    name: row.name,
    description: row.description ?? null,
    type: inferType(code) === "waypoint" ? "waypoint" : (row.type ?? inferType(code)),
    floor: row.floor ?? 0,
    latitude: row.latitude ?? null,
    longitude: row.longitude ?? null,
    is_active: row.is_active === undefined || row.is_active === null ? 1 : row.is_active,
  };
}

function inferType(code) {
  const c = String(code || "").toUpperCase();
  if (c.startsWith("WP_")) return "waypoint";
  if (c === "CITYU") return "campus";
  if (c === "ADMIN") return "admin";
  if (c === "LIB") return "library";
  return "building";
}

async function tableHasColumn(db, table, column) {
  const info = await db.prepare(`PRAGMA table_info(${table})`).all();
  return (info.results || []).some((c) => c.name === column);
}

async function listLocations(db) {
  const hasActive = await tableHasColumn(db, "locations", "is_active");
  const sql = hasActive
    ? "SELECT * FROM locations WHERE is_active = 1 ORDER BY id ASC"
    : "SELECT * FROM locations ORDER BY id ASC";

  const result = await db.prepare(sql).all();
  return json({
    success: true,
    data: (result.results || []).map(mapLocation),
  });
}

async function searchLocations(db, query) {
  const q = query.trim();
  if (!q) return listLocations(db);

  const hasActive = await tableHasColumn(db, "locations", "is_active");
  const like = `%${q}%`;

  const sql = hasActive
    ? `SELECT * FROM locations
       WHERE is_active = 1
         AND (name LIKE ? OR code LIKE ? OR IFNULL(description, '') LIKE ?)
       ORDER BY id ASC`
    : `SELECT * FROM locations
       WHERE name LIKE ? OR code LIKE ? OR IFNULL(description, '') LIKE ?
       ORDER BY id ASC`;

  const result = await db.prepare(sql).bind(like, like, like).all();
  return json({
    success: true,
    data: (result.results || []).map(mapLocation),
  });
}

async function createLocation(db, body) {
  if (!body?.code || !body?.name) {
    return json(
      { success: false, error: "code and name are required" },
      400
    );
  }

  const hasType = await tableHasColumn(db, "locations", "type");
  const hasFloor = await tableHasColumn(db, "locations", "floor");
  const hasActive = await tableHasColumn(db, "locations", "is_active");

  const code = String(body.code).trim().toUpperCase();
  const name = String(body.name).trim();
  const description = body.description ?? null;
  const latitude = body.latitude ?? null;
  const longitude = body.longitude ?? null;
  const type = body.type ?? inferType(code);
  const floor = Number.isFinite(Number(body.floor)) ? Number(body.floor) : 0;

  let sql = "INSERT INTO locations (code, name, description, latitude, longitude";
  const cols = [];
  const vals = [code, name, description, latitude, longitude];

  if (hasType) {
    sql += ", type";
    vals.push(type);
  }
  if (hasFloor) {
    sql += ", floor";
    vals.push(floor);
  }
  if (hasActive) {
    sql += ", is_active";
    vals.push(1);
  }

  sql += ") VALUES (" + vals.map(() => "?").join(", ") + ")";

  await db.prepare(sql).bind(...vals).run();

  // D1 last_row_id can be unreliable — reload by unique code.
  const row = await db
    .prepare("SELECT * FROM locations WHERE UPPER(code) = UPPER(?)")
    .bind(code)
    .first();

  if (!row) {
    return json(
      { success: false, error: "Insert succeeded but location could not be reloaded" },
      500
    );
  }

  return json({ success: true, data: mapLocation(row) }, 201);
}

async function updateLocation(db, id, body) {
  const existing = await db
    .prepare("SELECT * FROM locations WHERE id = ?")
    .bind(id)
    .first();

  if (!existing) {
    return json({ success: false, error: "Location not found" }, 404);
  }

  const hasType = await tableHasColumn(db, "locations", "type");
  const hasFloor = await tableHasColumn(db, "locations", "floor");
  const hasActive = await tableHasColumn(db, "locations", "is_active");

  const code = body.code !== undefined ? String(body.code).trim().toUpperCase() : existing.code;
  const name = body.name !== undefined ? String(body.name).trim() : existing.name;
  const description =
    body.description !== undefined ? body.description : existing.description;
  const latitude = body.latitude !== undefined ? body.latitude : existing.latitude;
  const longitude = body.longitude !== undefined ? body.longitude : existing.longitude;

  let sql =
    "UPDATE locations SET code = ?, name = ?, description = ?, latitude = ?, longitude = ?";
  const vals = [code, name, description, latitude, longitude];

  if (hasType && body.type !== undefined) {
    sql += ", type = ?";
    vals.push(body.type);
  }
  if (hasFloor && body.floor !== undefined) {
    sql += ", floor = ?";
    vals.push(Number(body.floor));
  }
  if (hasActive && body.is_active !== undefined) {
    sql += ", is_active = ?";
    vals.push(Number(body.is_active));
  }

  sql += " WHERE id = ?";
  vals.push(id);

  await db.prepare(sql).bind(...vals).run();

  const row = await db
    .prepare("SELECT * FROM locations WHERE id = ?")
    .bind(id)
    .first();

  return json({ success: true, data: mapLocation(row) });
}

async function deleteLocation(db, id) {
  const existing = await db
    .prepare("SELECT * FROM locations WHERE id = ?")
    .bind(id)
    .first();

  if (!existing) {
    return json({ success: false, error: "Location not found" }, 404);
  }

  const hasActive = await tableHasColumn(db, "locations", "is_active");

  if (hasActive) {
    // soft delete
    await db
      .prepare("UPDATE locations SET is_active = 0 WHERE id = ?")
      .bind(id)
      .run();
    return json({ success: true, message: "Location deactivated", id });
  }

  // hard delete (+ cleanup edges if table exists)
  const edgesExist = await tableExists(db, "location_edges");
  if (edgesExist) {
    const cols = await getEdgeColumnMap(db);
    await db
      .prepare(
        `DELETE FROM location_edges WHERE ${qid(cols.from)} = ? OR ${qid(cols.to)} = ?`
      )
      .bind(id, id)
      .run();
  }

  await db.prepare("DELETE FROM locations WHERE id = ?").bind(id).run();
  return json({ success: true, message: "Location deleted", id });
}

// =============================================================================
// Navigation / routing
// =============================================================================

async function tableExists(db, table) {
  const row = await db
    .prepare(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?"
    )
    .bind(table)
    .first();
  return Boolean(row);
}

function pick(row, key) {
  if (!row || !key) return undefined;
  if (row[key] !== undefined) return row[key];
  const want = String(key).trim().toLowerCase();
  const found = Object.keys(row).find(
    (k) => String(k).trim().toLowerCase() === want
  );
  return found ? row[found] : undefined;
}

/** Quote SQLite identifier (needed when column names have trailing spaces). */
function qid(name) {
  return `"${String(name).replace(/"/g, '""')}"`;
}

/** Resolve real column names from D1 (handles Id/id casing + trailing spaces). */
async function getEdgeColumnMap(db) {
  const info = await db.prepare("PRAGMA table_info(location_edges)").all();
  const names = (info.results || []).map((c) => c.name);

  const find = (...candidates) => {
    for (const cand of candidates) {
      const want = cand.trim().toLowerCase();
      const hit = names.find((n) => String(n).trim().toLowerCase() === want);
      if (hit) return hit; // keep exact DB name (may include trailing spaces)
    }
    return null;
  };

  const from = find("from_location_id", "from_location", "from_id");
  const to = find("to_location_id", "to_location", "to_id");
  const distance = find("distance_meters", "distance", "meters");
  const bidirectional = find("is_bidirectional", "is_bidirect", "bidirectional");

  if (!from || !to || !distance) {
    throw new Error(
      `location_edges columns mismatch. Found: [${names
        .map((n) => JSON.stringify(n))
        .join(", ")}]. Need from/to/distance.`
    );
  }

  return {
    from,
    to,
    distance,
    bidirectional: bidirectional || "is_bidirectional",
  };
}

/**
 * Places waypoints on the outer campus walkways and rebuilds edges as a ring
 * so Dijkstra routes follow white roads instead of cutting across the plaza.
 */
async function seedWalkwayGraph(db) {
  const buildings = [
    ["CITYU", 34.41845, 35.8354],
    ["ADMIN", 34.41755, 35.8351],
    ["LIB", 34.4185, 35.8364],
    ["KABA", 34.4182, 35.8343],
    ["SHOUMAN", 34.4195, 35.8355],
  ];
  for (const [code, lat, lng] of buildings) {
    await db
      .prepare(
        "UPDATE locations SET latitude = ?, longitude = ? WHERE UPPER(code) = ?"
      )
      .bind(lat, lng, code)
      .run();
  }

  const waypoints = [
    ["WP_S", "Path · South", "South walkway", 34.41765, 35.83535],
    ["WP_SE", "Path · South-East", "SE corner walkway", 34.41785, 35.8361],
    ["WP_E", "Path · East", "East road by library", 34.41845, 35.83655],
    ["WP_NE", "Path · North-East", "NE corner walkway", 34.41915, 35.83615],
    ["WP_N", "Path · North", "North walkway", 34.41935, 35.83545],
    ["WP_NW", "Path · North-West", "NW corner walkway", 34.4191, 35.8347],
    ["WP_W", "Path · West", "West road by KABA", 34.4184, 35.83435],
    ["WP_SW", "Path · South-West", "SW corner walkway", 34.41775, 35.83475],
  ];

  const hasType = await tableHasColumn(db, "locations", "type");
  const hasActive = await tableHasColumn(db, "locations", "is_active");

  for (const [code, name, description, lat, lng] of waypoints) {
    const existing = await db
      .prepare("SELECT id FROM locations WHERE UPPER(code) = ?")
      .bind(code)
      .first();

    // Broken rows (null id) cannot be updated reliably — replace them.
    if (existing && (existing.id === null || existing.id === undefined)) {
      await db
        .prepare("DELETE FROM locations WHERE UPPER(code) = ?")
        .bind(code)
        .run();
    }

    const stillThere = await db
      .prepare("SELECT id FROM locations WHERE UPPER(code) = ?")
      .bind(code)
      .first();

    if (stillThere) {
      let sql =
        "UPDATE locations SET name = ?, description = ?, latitude = ?, longitude = ?";
      const vals = [name, description, lat, lng];
      if (hasType) {
        sql += ", type = ?";
        vals.push("waypoint");
      }
      if (hasActive) {
        sql += ", is_active = ?";
        vals.push(1);
      }
      sql += " WHERE UPPER(code) = ?";
      vals.push(code);
      await db.prepare(sql).bind(...vals).run();
    } else {
      let sql =
        "INSERT INTO locations (code, name, description, latitude, longitude";
      const vals = [code, name, description, lat, lng];
      if (hasType) {
        sql += ", type";
        vals.push("waypoint");
      }
      if (hasActive) {
        sql += ", is_active";
        vals.push(1);
      }
      sql += ") VALUES (" + vals.map(() => "?").join(", ") + ")";
      await db.prepare(sql).bind(...vals).run();
    }
  }

  const edgesExist = await tableExists(db, "location_edges");
  if (!edgesExist) {
    return json(
      {
        success: false,
        error: "location_edges table missing — create it first",
      },
      503
    );
  }

  await db.prepare("DELETE FROM location_edges").run();

  const link = async (fromCode, toCode, meters) => {
    await db
      .prepare(
        `INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
         SELECT a.id, b.id, ?, 'walk', 1
         FROM locations a JOIN locations b ON a.code = ? AND b.code = ?`
      )
      .bind(meters, fromCode, toCode)
      .run();
  };

  // Outer walkway ring
  await link("WP_S", "WP_SE", 72);
  await link("WP_SE", "WP_E", 78);
  await link("WP_E", "WP_NE", 86);
  await link("WP_NE", "WP_N", 68);
  await link("WP_N", "WP_NW", 74);
  await link("WP_NW", "WP_W", 84);
  await link("WP_W", "WP_SW", 81);
  await link("WP_SW", "WP_S", 56);

  // Buildings ↔ nearest walkway
  await link("ADMIN", "WP_S", 25);
  await link("LIB", "WP_E", 15);
  await link("SHOUMAN", "WP_N", 17);
  await link("KABA", "WP_W", 23);
  await link("CITYU", "WP_S", 89);
  await link("CITYU", "WP_E", 105);
  await link("CITYU", "WP_N", 100);
  await link("CITYU", "WP_W", 96);

  const edgeCount = await db
    .prepare("SELECT COUNT(*) AS n FROM location_edges")
    .first();
  const wpCount = await db
    .prepare("SELECT COUNT(*) AS n FROM locations WHERE code LIKE 'WP_%'")
    .first();

  return json({
    success: true,
    message: "Walkway ring seeded — routes follow campus roads",
    waypoints: wpCount?.n ?? 0,
    edges: edgeCount?.n ?? 0,
  });
}

async function resolveLocationId(db, value) {
  if (value === null || value === undefined || value === "") return null;

  // numeric id
  if (/^\d+$/.test(String(value))) {
    const byId = await db
      .prepare("SELECT id FROM locations WHERE id = ?")
      .bind(Number(value))
      .first();
    return byId ? byId.id : null;
  }

  // code
  const byCode = await db
    .prepare("SELECT id FROM locations WHERE UPPER(code) = UPPER(?)")
    .bind(String(value).trim())
    .first();

  return byCode ? byCode.id : null;
}

async function findRoute(db, fromRaw, toRaw) {
  if (!fromRaw || !toRaw) {
    return json(
      { success: false, error: "Query params from and to are required" },
      400
    );
  }

  const fromId = await resolveLocationId(db, fromRaw);
  const toId = await resolveLocationId(db, toRaw);

  if (!fromId || !toId) {
    return json(
      {
        success: false,
        error: "Unknown from/to location. Use location id or code (e.g. 2 or ADMIN).",
      },
      404
    );
  }

  if (fromId === toId) {
    const loc = await db
      .prepare("SELECT * FROM locations WHERE id = ?")
      .bind(fromId)
      .first();
    return json({
      success: true,
      total_distance: 0,
      path: [mapLocation(loc)],
    });
  }

  const edgesExist = await tableExists(db, "location_edges");
  if (!edgesExist) {
    return json(
      {
        success: false,
        error:
          "Table location_edges not found. Create it using Backend/sql/locations_d1_schema.sql",
      },
      503
    );
  }

  const cols = await getEdgeColumnMap(db);
  const edgeResult = await db.prepare("SELECT * FROM location_edges").all();

  const edges = (edgeResult.results || []).map((row) => ({
    from_location_id: Number(pick(row, cols.from)),
    to_location_id: Number(pick(row, cols.to)),
    distance_meters: Number(pick(row, cols.distance)),
    is_bidirectional: Number(pick(row, cols.bidirectional) ?? 1),
  }));

  if (edges.length === 0) {
    return json(
      {
        success: false,
        error: "No edges in location_edges. Insert campus walk links first.",
      },
      404
    );
  }

  const graph = buildGraph(edges);
  const route = dijkstra(graph, fromId, toId);

  if (!route) {
    return json(
      {
        success: false,
        error: "No route found between these locations",
        from: fromId,
        to: toId,
      },
      404
    );
  }

  const pathLocations = [];
  for (const nodeId of route.path) {
    const loc = await db
      .prepare("SELECT * FROM locations WHERE id = ?")
      .bind(nodeId)
      .first();
    if (loc) pathLocations.push(mapLocation(loc));
  }

  return json({
    success: true,
    total_distance: route.distance,
    path: pathLocations,
  });
}

function buildGraph(edges) {
  const graph = new Map();

  const add = (a, b, w) => {
    if (!graph.has(a)) graph.set(a, []);
    graph.get(a).push({ to: b, weight: Number(w) });
  };

  for (const e of edges) {
    const from = Number(e.from_location_id);
    const to = Number(e.to_location_id);
    const dist = Number(e.distance_meters);
    const bidirectional =
      e.is_bidirectional === undefined ||
      e.is_bidirectional === null ||
      Number(e.is_bidirectional) === 1;

    add(from, to, dist);
    if (bidirectional) add(to, from, dist);
  }

  return graph;
}

/** Classic Dijkstra for small campus graphs */
function dijkstra(graph, start, goal) {
  const dist = new Map();
  const prev = new Map();
  const visited = new Set();

  for (const node of graph.keys()) {
    dist.set(node, Infinity);
  }
  dist.set(start, 0);

  // ensure goal exists in dist even if isolated in keys
  if (!dist.has(goal)) dist.set(goal, Infinity);
  if (!dist.has(start)) dist.set(start, 0);

  while (true) {
    let u = null;
    let best = Infinity;

    for (const [node, d] of dist.entries()) {
      if (!visited.has(node) && d < best) {
        best = d;
        u = node;
      }
    }

    if (u === null || best === Infinity) break;
    if (u === goal) break;

    visited.add(u);
    const neighbors = graph.get(u) || [];
    for (const { to, weight } of neighbors) {
      if (!dist.has(to)) dist.set(to, Infinity);
      const alt = dist.get(u) + weight;
      if (alt < dist.get(to)) {
        dist.set(to, alt);
        prev.set(to, u);
      }
    }
  }

  if (!Number.isFinite(dist.get(goal))) return null;

  const path = [];
  let cur = goal;
  while (cur !== undefined) {
    path.unshift(cur);
    if (cur === start) break;
    cur = prev.get(cur);
  }

  if (path[0] !== start) return null;

  return {
    distance: dist.get(goal),
    path,
  };
}
