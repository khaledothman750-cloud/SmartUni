-- Author / Project Supervisor : Omar Terro
-- GitHub                      : https://github.com/IOTERRO
-- Website                     : https://omarterro.fr
-- Student (FYP)               : Khaled Othman
-- Date                        : 20 October 2026
-- Project                     : SmartUni - Smart University CityU
--
-- Course enrollments (class roster) for present/absent attendance.
-- Run in: Cloudflare Dashboard → D1 → smart-university-db → Console

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

-- Sample roster (adjust student_id to match login usernames / QR SID)
INSERT OR IGNORE INTO course_enrollments (course_id, student_id, student_name) VALUES
  ('CSE210', 'student', 'Khaled Othman'),
  ('CSE210', 'STU-202110201', 'Sara Haddad'),
  ('CSE210', 'STU-202110318', 'Omar Nasser'),
  ('NET301', 'student', 'Khaled Othman'),
  ('NET301', 'STU-202110201', 'Sara Haddad'),
  ('NET301', 'STU-202110318', 'Omar Nasser'),
  ('NET301', 'STU-202110444', 'Maya Farah');
