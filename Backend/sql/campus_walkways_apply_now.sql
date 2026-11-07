-- Paste into Cloudflare D1 Console → database cityu → Execute.
-- Rebuilds walkway ring so blue routes follow white campus roads.

UPDATE locations SET latitude = 34.418309, longitude = 35.837060 WHERE code = 'CITYU';
UPDATE locations SET latitude = 34.4183793754257, longitude = 35.83619852075846 WHERE code = 'ADMIN';
UPDATE locations SET latitude = 34.418622712441646, longitude = 35.835470367579084 WHERE code = 'LIB';
UPDATE locations SET latitude = 34.41944873068435, longitude = 35.835349382076224 WHERE code = 'KABA';
UPDATE locations SET latitude = 34.41819170558045, longitude = 35.83645294930101 WHERE code = 'SHOUMAN';

-- Drop broken waypoint rows (null id) then re-insert cleanly
DELETE FROM locations WHERE code IN ('WP_SE', 'WP_NW', 'WP_SW');

INSERT OR IGNORE INTO locations (code, name, description, latitude, longitude) VALUES
  ('WP_S',  'Path · South',      'South walkway',           34.41765, 35.83535),
  ('WP_SE', 'Path · South-East', 'SE corner walkway',       34.41785, 35.83610),
  ('WP_E',  'Path · East',       'East road by library',    34.41845, 35.83655),
  ('WP_NE', 'Path · North-East', 'NE corner walkway',       34.41915, 35.83615),
  ('WP_N',  'Path · North',      'North walkway',           34.41935, 35.83545),
  ('WP_NW', 'Path · North-West', 'NW corner walkway',       34.41910, 35.83470),
  ('WP_W',  'Path · West',       'West road by KABA',       34.41840, 35.83435),
  ('WP_SW', 'Path · South-West', 'SW corner walkway',       34.41775, 35.83475);

UPDATE locations SET latitude = 34.41765, longitude = 35.83535 WHERE code = 'WP_S';
UPDATE locations SET latitude = 34.41785, longitude = 35.83610 WHERE code = 'WP_SE';
UPDATE locations SET latitude = 34.41845, longitude = 35.83655 WHERE code = 'WP_E';
UPDATE locations SET latitude = 34.41915, longitude = 35.83615 WHERE code = 'WP_NE';
UPDATE locations SET latitude = 34.41935, longitude = 35.83545 WHERE code = 'WP_N';
UPDATE locations SET latitude = 34.41910, longitude = 35.83470 WHERE code = 'WP_NW';
UPDATE locations SET latitude = 34.41840, longitude = 35.83435 WHERE code = 'WP_W';
UPDATE locations SET latitude = 34.41775, longitude = 35.83475 WHERE code = 'WP_SW';

DELETE FROM location_edges;

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
