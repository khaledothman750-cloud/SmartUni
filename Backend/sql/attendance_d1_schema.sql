-- Author / Project Supervisor : Omar Terro
-- GitHub                      : https://github.com/IOTERRO
-- Website                     : https://omarterro.fr
-- Student (FYP)               : Khaled Othman
-- Date                        : 14 October 2026
-- Project                     : SmartUni - Smart University CityU
-- SmartUni Attendance — Cloudflare D1
-- Run in: Cloudflare Dashboard → D1 → your database → Console

CREATE TABLE IF NOT EXISTS courses (
  id            TEXT PRIMARY KEY,
  name          TEXT NOT NULL,
  instructor_id TEXT,
  created_at    TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS attendance_sessions (
  id            TEXT PRIMARY KEY,
  course_id     TEXT NOT NULL,
  session_date  TEXT NOT NULL,
  start_time    TEXT NOT NULL,
  end_time      TEXT,
  room          TEXT,
  is_active     INTEGER NOT NULL DEFAULT 1,
  created_at    TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (course_id) REFERENCES courses(id)
);

CREATE TABLE IF NOT EXISTS attendance_records (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id      TEXT NOT NULL,
  student_id      TEXT NOT NULL,
  student_name    TEXT NOT NULL,
  status          TEXT NOT NULL,
  scanned_at      TEXT,
  qr_token        TEXT,
  device_id       TEXT,
  created_at      TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE (session_id, student_id),
  FOREIGN KEY (session_id) REFERENCES attendance_sessions(id)
);

CREATE INDEX IF NOT EXISTS idx_att_records_session ON attendance_records(session_id);
CREATE INDEX IF NOT EXISTS idx_att_records_student ON attendance_records(student_id);

-- Class roster per course (who should attend). Used for Absent vs Present sheet.
CREATE TABLE IF NOT EXISTS course_enrollments (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  course_id     TEXT NOT NULL,
  student_id    TEXT NOT NULL,
  student_name  TEXT NOT NULL,
  created_at    TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE (course_id, student_id),
  FOREIGN KEY (course_id) REFERENCES courses(id)
);

CREATE INDEX IF NOT EXISTS idx_enroll_course ON course_enrollments(course_id);
CREATE INDEX IF NOT EXISTS idx_enroll_student ON course_enrollments(student_id);

INSERT INTO courses (id, name, instructor_id) VALUES
  ('NET301', 'Smart Networks', 'INS001'),
  ('CSE210', 'Programming II', 'INS002');

INSERT INTO attendance_sessions (
  id, course_id, session_date, start_time, end_time, room, is_active
) VALUES (
  'SES-NET301-20261013-0900', 'NET301', '2026-10-13', '09:00', '10:30', 'ENG-Lab2', 1
);

INSERT INTO attendance_records (
  session_id, student_id, student_name, status, scanned_at, qr_token, device_id
) VALUES
  ('SES-NET301-20261013-0900', 'STU-202110142', 'Khaled Othman', 'Present', '2026-10-13T09:05:00Z', 'TOK111', 'CLASSROOM-CAM-01'),
  ('SES-NET301-20261013-0900', 'STU-202110201', 'Sara Haddad',   'Present', '2026-10-13T09:06:00Z', 'TOK222', 'CLASSROOM-CAM-01'),
  ('SES-NET301-20261013-0900', 'STU-202110318', 'Omar Nasser',   'Absent',  NULL,                   NULL,    NULL),
  ('SES-NET301-20261013-0900', 'STU-202110444', 'Maya Farah',    'Present', '2026-10-13T09:08:00Z', 'TOK333', 'CLASSROOM-CAM-01');
