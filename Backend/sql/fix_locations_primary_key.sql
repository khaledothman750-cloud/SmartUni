-- Root cause: locations.id is INTEGER with pk=0 (NOT a primary key),
-- so INSERT never auto-assigns ids → WP_* rows get id=NULL → edges fail.
--
-- Run in D1 Console (cityu), STEP BY STEP.

-- =============================================================================
-- STEP 1 — See current buildings (keep these coords)
-- =============================================================================
-- SELECT id, code, name, latitude, longitude, type, floor, is_active FROM locations WHERE code NOT LIKE 'WP_%';

-- =============================================================================
-- STEP 2 — Rebuild locations WITH a real primary key
-- =============================================================================
CREATE TABLE locations_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  latitude REAL,
  longitude REAL,
  type TEXT,
  floor INTEGER DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1
);

-- Copy buildings only (skip broken WP_* with null ids)
INSERT INTO locations_new (code, name, description, latitude, longitude, type, floor, is_active)
SELECT
  code,
  name,
  description,
  latitude,
  longitude,
  type,
  COALESCE(floor, 0),
  COALESCE(is_active, 1)
FROM locations
WHERE code NOT LIKE 'WP_%'
  AND code IS NOT NULL
  AND name IS NOT NULL;

DROP TABLE locations;
ALTER TABLE locations_new RENAME TO locations;

-- =============================================================================
-- STEP 3 — Confirm buildings have real ids now
-- =============================================================================
-- SELECT id, code FROM locations ORDER BY id;

-- =============================================================================
-- STEP 4 — Clear edges, add waypoints (ids will auto-assign)
-- =============================================================================
DELETE FROM location_edges;

INSERT INTO locations (code, name, description, latitude, longitude, type, is_active) VALUES
  ('WP_S',  'Path · South',      'South walkway',           34.41765, 35.83535, 'waypoint', 1),
  ('WP_SE', 'Path · South-East', 'SE corner walkway',       34.41785, 35.83610, 'waypoint', 1),
  ('WP_E',  'Path · East',       'East road by library',    34.41845, 35.83655, 'waypoint', 1),
  ('WP_NE', 'Path · North-East', 'NE corner walkway',       34.41915, 35.83615, 'waypoint', 1),
  ('WP_N',  'Path · North',      'North walkway',           34.41935, 35.83545, 'waypoint', 1),
  ('WP_NW', 'Path · North-West', 'NW corner walkway',       34.41910, 35.83470, 'waypoint', 1),
  ('WP_W',  'Path · West',       'West road by KABA',       34.41840, 35.83435, 'waypoint', 1),
  ('WP_SW', 'Path · South-West', 'SW corner walkway',       34.41775, 35.83475, 'waypoint', 1);

-- Must show non-null ids:
-- SELECT id, code FROM locations WHERE code LIKE 'WP_%' ORDER BY code;

-- =============================================================================
-- STEP 5 — Rebuild walk edges
-- =============================================================================
INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 72, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'WP_S'  AND b.code = 'WP_SE';

INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 78, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'WP_SE' AND b.code = 'WP_E';

INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 86, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'WP_E'  AND b.code = 'WP_NE';

INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 68, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'WP_NE' AND b.code = 'WP_N';

INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 74, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'WP_N'  AND b.code = 'WP_NW';

INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 84, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'WP_NW' AND b.code = 'WP_W';

INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 81, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'WP_W'  AND b.code = 'WP_SW';

INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 56, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'WP_SW' AND b.code = 'WP_S';

INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 25, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'ADMIN'   AND b.code = 'WP_S';

INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 15, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'LIB'     AND b.code = 'WP_E';

INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 17, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'SHOUMAN' AND b.code = 'WP_N';

INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 23, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'KABA'    AND b.code = 'WP_W';

INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 89, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'CITYU' AND b.code = 'WP_S';

INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 105, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'CITYU' AND b.code = 'WP_E';

INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 100, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'CITYU' AND b.code = 'WP_N';

INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 96, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'CITYU' AND b.code = 'WP_W';

-- Optional check:
-- SELECT COUNT(*) AS edges FROM location_edges;
-- PRAGMA table_info(locations);  -- id should show pk = 1
