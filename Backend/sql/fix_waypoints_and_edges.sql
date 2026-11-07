-- Fix for: NOT NULL constraint failed: location_edges.to_location_id
-- Cause: duplicate / broken WP_* rows with NULL id (WP_SE, WP_NW, WP_SW).
-- Run in D1 Console → cityu → one statement group at a time if needed.

-- =============================================================================
-- STEP 1 — Remove ALL path waypoints (good + broken duplicates)
-- =============================================================================
DELETE FROM location_edges;
DELETE FROM locations WHERE code LIKE 'WP_%';

-- =============================================================================
-- STEP 2 — Re-insert waypoints (must get real autoincrement ids)
-- =============================================================================
INSERT INTO locations (code, name, description, latitude, longitude) VALUES
  ('WP_S',  'Path · South',      'South walkway',           34.41765, 35.83535),
  ('WP_SE', 'Path · South-East', 'SE corner walkway',       34.41785, 35.83610),
  ('WP_E',  'Path · East',       'East road by library',    34.41845, 35.83655),
  ('WP_NE', 'Path · North-East', 'NE corner walkway',       34.41915, 35.83615),
  ('WP_N',  'Path · North',      'North walkway',           34.41935, 35.83545),
  ('WP_NW', 'Path · North-West', 'NW corner walkway',       34.41910, 35.83470),
  ('WP_W',  'Path · West',       'West road by KABA',       34.41840, 35.83435),
  ('WP_SW', 'Path · South-West', 'SW corner walkway',       34.41775, 35.83475);

-- Check: every WP_* must show a non-null id before STEP 3
-- SELECT id, code FROM locations WHERE code LIKE 'WP_%' ORDER BY code;

-- =============================================================================
-- STEP 3 — Rebuild edges (only after STEP 2 ids look good)
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
