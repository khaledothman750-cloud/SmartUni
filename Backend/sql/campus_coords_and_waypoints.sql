-- Author / Project Supervisor : Omar Terro
-- GitHub                      : https://github.com/IOTERRO
-- Website                     : https://omarterro.fr
-- Student (FYP)               : Khaled Othman
-- Date                        : 19 October 2026
-- Project                     : SmartUni - Smart University CityU
--
-- Better Abi Samra coords + walkway waypoints.
-- Run EACH STEP separately in D1 Console (cityu).
-- Your locations table currently has only:
--   id, code, name, description, latitude, longitude

-- =============================================================================
-- STEP 1 — Add optional columns (run one ALTER at a time; ignore "duplicate column")
-- =============================================================================
ALTER TABLE locations ADD COLUMN type TEXT;
-- then:
ALTER TABLE locations ADD COLUMN floor INTEGER DEFAULT 0;
-- then:
ALTER TABLE locations ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1;

-- =============================================================================
-- STEP 2 — Update building coordinates (works even if STEP 1 was skipped)
-- Prefer this if ALTER failed — no type/is_active:
-- =============================================================================
UPDATE locations SET latitude = 34.41845, longitude = 35.83540 WHERE code = 'CITYU';
UPDATE locations SET latitude = 34.41750, longitude = 35.83505 WHERE code = 'ADMIN';
UPDATE locations SET latitude = 34.41855, longitude = 35.83635 WHERE code = 'LIB';
UPDATE locations SET latitude = 34.41815, longitude = 35.83425 WHERE code = 'KABA';
UPDATE locations SET latitude = 34.41955, longitude = 35.83555 WHERE code = 'SHOUMAN';

-- If STEP 1 succeeded, you may also set types:
-- UPDATE locations SET type = 'campus',   is_active = 1 WHERE code = 'CITYU';
-- UPDATE locations SET type = 'admin',    is_active = 1 WHERE code = 'ADMIN';
-- UPDATE locations SET type = 'library',  is_active = 1 WHERE code = 'LIB';
-- UPDATE locations SET type = 'building', is_active = 1 WHERE code = 'KABA';
-- UPDATE locations SET type = 'building', is_active = 1 WHERE code = 'SHOUMAN';

-- =============================================================================
-- STEP 3 — Path waypoints (codes WP_* → Worker infers type = waypoint)
-- =============================================================================
INSERT OR IGNORE INTO locations (code, name, description, latitude, longitude) VALUES
  ('WP_S',  'Path · South',      'Walkway south of plaza',  34.41795, 35.83525),
  ('WP_E',  'Path · East',       'Walkway toward library',  34.41850, 35.83585),
  ('WP_W',  'Path · West',       'Walkway toward KABA',     34.41830, 35.83480),
  ('WP_N',  'Path · North',      'Walkway toward SHOUMAN',  34.41900, 35.83548),
  ('WP_NE', 'Path · North-East', 'Connector LIB–SHOUMAN',   34.41895, 35.83600);

-- If type column exists:
-- UPDATE locations SET type = 'waypoint', is_active = 1 WHERE code LIKE 'WP_%';

-- =============================================================================
-- STEP 4 — Rebuild walk graph through waypoints
-- =============================================================================
DELETE FROM location_edges;

INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 53, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'ADMIN'  AND b.code = 'WP_S';

INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 57, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'WP_S'   AND b.code = 'CITYU';

INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 42, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'CITYU'  AND b.code = 'WP_E';

INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 46, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'WP_E'   AND b.code = 'LIB';

INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 58, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'CITYU'  AND b.code = 'WP_W';

INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 53, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'WP_W'   AND b.code = 'KABA';

INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 62, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'CITYU'  AND b.code = 'WP_N';

INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 61, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'WP_N'   AND b.code = 'SHOUMAN';

INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 55, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'LIB'    AND b.code = 'WP_NE';

INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 78, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'WP_NE'  AND b.code = 'SHOUMAN';

INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 52, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'WP_E'   AND b.code = 'WP_NE';

INSERT INTO location_edges (from_location_id, to_location_id, distance_meters, path_type, is_bidirectional)
SELECT a.id, b.id, 94, 'walk', 1 FROM locations a JOIN locations b ON a.code = 'KABA'   AND b.code = 'WP_S';
