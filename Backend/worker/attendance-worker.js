/**
 * Author / Project Supervisor : Omar Terro
 * GitHub                      : https://github.com/IOTERRO
 * Website                     : https://omarterro.fr
 * Student (FYP)               : Khaled Othman
 * Date                        : 14 October 2026
 * Project                     : SmartUni - Smart University CityU
 */
/**
 * Smart University Worker — Attendance API
 *
 * Cloudflare bindings required:
 *   - D1 Database: env.DB  →  smart-university-db
 *   - Secret:      env.API_KEY
 *
 * Paste into: Workers → smart-university → Edit code
 * (because you bound DB → smart-university-db on this Worker)
 *
 * Tables used (lowercase):
 *   courses, course_enrollments, attendance_sessions, attendance_records
 */

export default {
  async fetch(request, env) {
    try {
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
            error:
              "D1 binding DB is missing. Bind smart-university-db as variable DB.",
          },
          500
        );
      }

      const url = new URL(request.url);
      const path = normalizePath(url.pathname);
      const method = request.method.toUpperCase();

      // -------- Health --------
      if (method === "GET" && (path === "/" || path === "/api/health")) {
        return json({
          success: true,
          service: "attendance",
          database: "smart-university-db",
          endpoints: [
            "GET /api/courses",
            "POST /api/courses",
            "GET /api/courses/:id/enrollments",
            "POST /api/courses/:id/enrollments",
            "DELETE /api/courses/:id/enrollments/:studentId",
            "GET /api/attendance/sessions",
            "POST /api/attendance/sessions",
            "GET /api/attendance/records?session_id=",
            "GET /api/attendance/sheet?session_id=",
            "POST /api/attendance/scan",
            "PUT /api/attendance/records/:id",
            "DELETE /api/attendance/records/:id",
          ],
        });
      }

      // -------- Courses --------
      if (method === "GET" && path === "/api/courses") {
        return cors(await listCourses(env.DB));
      }

      if (method === "POST" && path === "/api/courses") {
        const body = await readJson(request);
        return cors(await createCourse(env.DB, body));
      }

      // -------- Course enrollments (class roster) --------
      let enrollListMatch = path.match(/^\/api\/courses\/([^/]+)\/enrollments$/);
      if (method === "GET" && enrollListMatch) {
        return cors(
          await listEnrollments(env.DB, decodeURIComponent(enrollListMatch[1]))
        );
      }
      if (method === "POST" && enrollListMatch) {
        const body = await readJson(request);
        return cors(
          await addEnrollment(
            env.DB,
            decodeURIComponent(enrollListMatch[1]),
            body
          )
        );
      }

      let enrollOneMatch = path.match(
        /^\/api\/courses\/([^/]+)\/enrollments\/([^/]+)$/
      );
      if (method === "DELETE" && enrollOneMatch) {
        return cors(
          await removeEnrollment(
            env.DB,
            decodeURIComponent(enrollOneMatch[1]),
            decodeURIComponent(enrollOneMatch[2])
          )
        );
      }

      // -------- Sessions --------
      if (method === "GET" && path === "/api/attendance/sessions") {
        const courseId = url.searchParams.get("course_id");
        return cors(await listSessions(env.DB, courseId));
      }

      if (method === "POST" && path === "/api/attendance/sessions") {
        const body = await readJson(request);
        return cors(await createSession(env.DB, body));
      }

      let sessionMatch = path.match(/^\/api\/attendance\/sessions\/(.+)$/);
      if (method === "GET" && sessionMatch) {
        return cors(await getSession(env.DB, decodeURIComponent(sessionMatch[1])));
      }

      if (method === "PUT" && sessionMatch) {
        const body = await readJson(request);
        return cors(
          await updateSession(env.DB, decodeURIComponent(sessionMatch[1]), body)
        );
      }

      // -------- Records --------
      if (method === "GET" && path === "/api/attendance/records") {
        const sessionId = url.searchParams.get("session_id");
        return cors(await listRecords(env.DB, sessionId));
      }

      // Roster + present/absent for a session (needs course_enrollments)
      if (method === "GET" && path === "/api/attendance/sheet") {
        const sessionId = url.searchParams.get("session_id");
        return cors(await attendanceSheet(env.DB, sessionId));
      }

      if (method === "POST" && path === "/api/attendance/records") {
        const body = await readJson(request);
        return cors(await upsertRecord(env.DB, body));
      }

      let recordMatch = path.match(/^\/api\/attendance\/records\/(\d+)$/);
      if (method === "PUT" && recordMatch) {
        const body = await readJson(request);
        return cors(await updateRecord(env.DB, Number(recordMatch[1]), body));
      }

      if (method === "DELETE" && recordMatch) {
        return cors(await deleteRecord(env.DB, Number(recordMatch[1])));
      }

      // -------- Classroom scanner --------
      // Body can be structured JSON OR { qr_raw: "SMARTUNI|SID:...|TOK:...|EXP:..." }
      if (method === "POST" && path === "/api/attendance/scan") {
        const body = await readJson(request);
        return cors(await scanAttendance(env.DB, body));
      }

      return json({ success: false, error: "Not found", path }, 404);
    } catch (err) {
      return json({ success: false, error: err?.message || String(err) }, 500);
    }
  },
};

// =============================================================================
// Helpers
// =============================================================================

function authorize(request, env) {
  const expectedKey = env.API_KEY;
  const providedKey = request.headers.get("X-API-Key");
  return Boolean(expectedKey && providedKey && providedKey === expectedKey);
}

function normalizePath(pathname) {
  if (!pathname) return "/";
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
  return new Response(response.body, { status: response.status, headers });
}

async function readJson(request) {
  try {
    return await request.json();
  } catch {
    throw new Error("Invalid JSON body");
  }
}

function nowIso() {
  return new Date().toISOString();
}

/** Parse: SMARTUNI|SID:STU-xxx|TOK:ABC|EXP:1739... */
function parseQrRaw(raw) {
  const text = String(raw || "").trim();
  if (!text.startsWith("SMARTUNI|")) return null;

  const parts = {};
  for (const chunk of text.split("|").slice(1)) {
    const i = chunk.indexOf(":");
    if (i === -1) continue;
    parts[chunk.slice(0, i)] = chunk.slice(i + 1);
  }

  if (!parts.SID || !parts.TOK) return null;

  return {
    student_id: parts.SID,
    qr_token: parts.TOK,
    token_expires_at: parts.EXP ? Number(parts.EXP) : null,
  };
}

// =============================================================================
// Courses
// =============================================================================

async function listCourses(db) {
  const { results } = await db
    .prepare("SELECT * FROM courses ORDER BY id ASC")
    .all();
  return json({ success: true, data: results || [] });
}

async function createCourse(db, body) {
  const id = String(body?.id || body?.code || "").trim().toUpperCase();
  const name = String(body?.name || "").trim();
  const instructorId = body?.instructor_id ?? null;

  if (!id || !name) {
    return json({ success: false, error: "id and name are required" }, 400);
  }

  try {
    await db
      .prepare(
        "INSERT INTO courses (id, name, instructor_id, created_at) VALUES (?, ?, ?, ?)"
      )
      .bind(id, name, instructorId, nowIso())
      .run();
  } catch (e) {
    if (String(e.message || e).includes("UNIQUE")) {
      return json({ success: false, error: "Course id already exists" }, 409);
    }
    throw e;
  }

  const row = await db.prepare("SELECT * FROM courses WHERE id = ?").bind(id).first();
  return json({ success: true, data: row }, 201);
}

// =============================================================================
// Course enrollments (who belongs to the class)
// =============================================================================

async function listEnrollments(db, courseId) {
  const id = String(courseId || "").trim().toUpperCase();
  if (!id) {
    return json({ success: false, error: "course id is required" }, 400);
  }

  const course = await db
    .prepare("SELECT id FROM courses WHERE id = ?")
    .bind(id)
    .first();
  if (!course) {
    return json({ success: false, error: "Course not found" }, 404);
  }

  const { results } = await db
    .prepare(
      `SELECT * FROM course_enrollments
       WHERE course_id = ?
       ORDER BY student_name ASC`
    )
    .bind(id)
    .all();

  return json({ success: true, course_id: id, data: results || [] });
}

async function addEnrollment(db, courseId, body) {
  const id = String(courseId || "").trim().toUpperCase();
  const studentId = String(body?.student_id || "").trim();
  const studentName = String(body?.student_name || "").trim();

  if (!id || !studentId || !studentName) {
    return json(
      { success: false, error: "course id, student_id, student_name are required" },
      400
    );
  }

  const course = await db
    .prepare("SELECT id FROM courses WHERE id = ?")
    .bind(id)
    .first();
  if (!course) {
    return json({ success: false, error: "Course not found" }, 404);
  }

  try {
    await db
      .prepare(
        `INSERT INTO course_enrollments (course_id, student_id, student_name, created_at)
         VALUES (?, ?, ?, ?)`
      )
      .bind(id, studentId, studentName, nowIso())
      .run();
  } catch (e) {
    if (String(e.message || e).includes("UNIQUE")) {
      return json(
        { success: false, error: "Student already enrolled in this course" },
        409
      );
    }
    throw e;
  }

  const row = await db
    .prepare(
      `SELECT * FROM course_enrollments
       WHERE course_id = ? AND student_id = ?`
    )
    .bind(id, studentId)
    .first();

  return json({ success: true, data: row }, 201);
}

async function removeEnrollment(db, courseId, studentId) {
  const id = String(courseId || "").trim().toUpperCase();
  const sid = String(studentId || "").trim();
  if (!id || !sid) {
    return json(
      { success: false, error: "course id and student_id are required" },
      400
    );
  }

  const existing = await db
    .prepare(
      `SELECT * FROM course_enrollments
       WHERE course_id = ? AND student_id = ?`
    )
    .bind(id, sid)
    .first();
  if (!existing) {
    return json({ success: false, error: "Enrollment not found" }, 404);
  }

  await db
    .prepare(
      `DELETE FROM course_enrollments WHERE course_id = ? AND student_id = ?`
    )
    .bind(id, sid)
    .run();

  return json({ success: true, message: `Removed ${sid} from ${id}` });
}

/**
 * Merges course roster with scan records for one session.
 * Present = scanned; Absent = enrolled but not scanned.
 */
async function attendanceSheet(db, sessionId) {
  if (!sessionId) {
    return json(
      { success: false, error: "Query param session_id is required" },
      400
    );
  }

  const session = await db
    .prepare("SELECT * FROM attendance_sessions WHERE id = ?")
    .bind(sessionId)
    .first();
  if (!session) {
    return json({ success: false, error: "Session not found" }, 404);
  }

  const courseId = session.course_id;
  const { results: enrolled } = await db
    .prepare(
      `SELECT student_id, student_name FROM course_enrollments
       WHERE course_id = ?
       ORDER BY student_name ASC`
    )
    .bind(courseId)
    .all();

  const { results: records } = await db
    .prepare(
      `SELECT student_id, student_name, status, scanned_at, qr_token, device_id, id
       FROM attendance_records WHERE session_id = ?`
    )
    .bind(sessionId)
    .all();

  const byId = new Map();
  for (const r of records || []) {
    byId.set(String(r.student_id), r);
  }

  const sheet = (enrolled || []).map((e) => {
    const hit = byId.get(String(e.student_id));
    const present =
      hit && String(hit.status || "").toLowerCase() === "present";
    return {
      student_id: e.student_id,
      student_name: e.student_name,
      status: present ? "Present" : "Absent",
      scanned_at: present ? hit.scanned_at ?? null : null,
      record_id: hit?.id ?? null,
      enrolled: true,
    };
  });

  // Scans for students not on the roster (still show them)
  for (const r of records || []) {
    const onRoster = (enrolled || []).some(
      (e) => String(e.student_id) === String(r.student_id)
    );
    if (onRoster) continue;
    sheet.push({
      student_id: r.student_id,
      student_name: r.student_name,
      status: r.status,
      scanned_at: r.scanned_at,
      record_id: r.id,
      enrolled: false,
    });
  }

  sheet.sort((a, b) => {
    const ap = a.status === "Present" ? 0 : 1;
    const bp = b.status === "Present" ? 0 : 1;
    if (ap !== bp) return ap - bp;
    return String(a.student_name).localeCompare(String(b.student_name));
  });

  const presentCount = sheet.filter((s) => s.status === "Present").length;
  const absentCount = sheet.filter((s) => s.status === "Absent").length;

  return json({
    success: true,
    session_id: sessionId,
    course_id: courseId,
    summary: {
      enrolled: (enrolled || []).length,
      present: presentCount,
      absent: absentCount,
    },
    data: sheet,
  });
}

// =============================================================================
// Sessions
// =============================================================================

async function listSessions(db, courseId) {
  let result;
  if (courseId) {
    result = await db
      .prepare(
        "SELECT * FROM attendance_sessions WHERE course_id = ? ORDER BY session_date DESC, start_time DESC"
      )
      .bind(courseId)
      .all();
  } else {
    result = await db
      .prepare(
        "SELECT * FROM attendance_sessions ORDER BY session_date DESC, start_time DESC"
      )
      .all();
  }

  return json({ success: true, data: result.results || [] });
}

async function getSession(db, sessionId) {
  const row = await db
    .prepare("SELECT * FROM attendance_sessions WHERE id = ?")
    .bind(sessionId)
    .first();

  if (!row) return json({ success: false, error: "Session not found" }, 404);
  return json({ success: true, data: row });
}

async function createSession(db, body) {
  const courseId = String(body?.course_id || "").trim().toUpperCase();
  const sessionDate = String(body?.session_date || "").trim();
  const startTime = String(body?.start_time || "").trim();
  const endTime = body?.end_time ?? null;
  const room = body?.room ?? null;
  const isActive = body?.is_active === undefined ? 1 : Number(body.is_active);

  if (!courseId || !sessionDate || !startTime) {
    return json(
      {
        success: false,
        error: "course_id, session_date, start_time are required",
      },
      400
    );
  }

  const course = await db
    .prepare("SELECT id FROM courses WHERE id = ?")
    .bind(courseId)
    .first();
  if (!course) {
    return json({ success: false, error: "course_id not found in courses" }, 400);
  }

  const id =
    body?.id ||
    `SES-${courseId}-${sessionDate.replace(/-/g, "")}-${startTime.replace(":", "")}`;

  try {
    await db
      .prepare(
        `INSERT INTO attendance_sessions
          (id, course_id, session_date, start_time, end_time, room, is_active, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
      )
      .bind(id, courseId, sessionDate, startTime, endTime, room, isActive, nowIso())
      .run();
  } catch (e) {
    if (String(e.message || e).includes("UNIQUE")) {
      return json({ success: false, error: "Session id already exists" }, 409);
    }
    throw e;
  }

  const row = await db
    .prepare("SELECT * FROM attendance_sessions WHERE id = ?")
    .bind(id)
    .first();
  return json({ success: true, data: row }, 201);
}

async function updateSession(db, sessionId, body) {
  const existing = await db
    .prepare("SELECT * FROM attendance_sessions WHERE id = ?")
    .bind(sessionId)
    .first();
  if (!existing) return json({ success: false, error: "Session not found" }, 404);

  const courseId = body.course_id ?? existing.course_id;
  const sessionDate = body.session_date ?? existing.session_date;
  const startTime = body.start_time ?? existing.start_time;
  const endTime = body.end_time !== undefined ? body.end_time : existing.end_time;
  const room = body.room !== undefined ? body.room : existing.room;
  const isActive =
    body.is_active !== undefined ? Number(body.is_active) : existing.is_active;

  await db
    .prepare(
      `UPDATE attendance_sessions
       SET course_id = ?, session_date = ?, start_time = ?, end_time = ?, room = ?, is_active = ?
       WHERE id = ?`
    )
    .bind(courseId, sessionDate, startTime, endTime, room, isActive, sessionId)
    .run();

  const row = await db
    .prepare("SELECT * FROM attendance_sessions WHERE id = ?")
    .bind(sessionId)
    .first();
  return json({ success: true, data: row });
}

// =============================================================================
// Records
// =============================================================================

async function listRecords(db, sessionId) {
  if (!sessionId) {
    return json(
      { success: false, error: "Query param session_id is required" },
      400
    );
  }

  const { results } = await db
    .prepare(
      `SELECT * FROM attendance_records
       WHERE session_id = ?
       ORDER BY
         CASE status WHEN 'Present' THEN 0 ELSE 1 END,
         scanned_at ASC,
         student_name ASC`
    )
    .bind(sessionId)
    .all();

  return json({ success: true, session_id: sessionId, data: results || [] });
}

async function upsertRecord(db, body) {
  const sessionId = String(body?.session_id || "").trim();
  const studentId = String(body?.student_id || "").trim();
  const studentName = String(body?.student_name || "").trim();
  const status = String(body?.status || "Absent");
  const scannedAt = body?.scanned_at ?? null;
  const qrToken = body?.qr_token ?? null;
  const deviceId = body?.device_id ?? null;

  if (!sessionId || !studentId || !studentName) {
    return json(
      {
        success: false,
        error: "session_id, student_id, student_name are required",
      },
      400
    );
  }

  if (status !== "Present" && status !== "Absent") {
    return json(
      { success: false, error: "status must be Present or Absent" },
      400
    );
  }

  const session = await db
    .prepare("SELECT id FROM attendance_sessions WHERE id = ?")
    .bind(sessionId)
    .first();
  if (!session) {
    return json({ success: false, error: "session_id not found" }, 400);
  }

  const existing = await db
    .prepare(
      "SELECT * FROM attendance_records WHERE session_id = ? AND student_id = ?"
    )
    .bind(sessionId, studentId)
    .first();

  if (existing) {
    await db
      .prepare(
        `UPDATE attendance_records
         SET student_name = ?, status = ?, scanned_at = ?, qr_token = ?, device_id = ?
         WHERE id = ?`
      )
      .bind(studentName, status, scannedAt, qrToken, deviceId, existing.id)
      .run();

    const row = await db
      .prepare("SELECT * FROM attendance_records WHERE id = ?")
      .bind(existing.id)
      .first();
    return json({ success: true, updated: true, data: row });
  }

  const info = await db
    .prepare(
      `INSERT INTO attendance_records
        (session_id, student_id, student_name, status, scanned_at, qr_token, device_id, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .bind(
      sessionId,
      studentId,
      studentName,
      status,
      scannedAt,
      qrToken,
      deviceId,
      nowIso()
    )
    .run();

  const row = await db
    .prepare("SELECT * FROM attendance_records WHERE id = ?")
    .bind(info.meta?.last_row_id)
    .first();

  return json({ success: true, created: true, data: row }, 201);
}

async function updateRecord(db, id, body) {
  const existing = await db
    .prepare("SELECT * FROM attendance_records WHERE id = ?")
    .bind(id)
    .first();
  if (!existing) return json({ success: false, error: "Record not found" }, 404);

  const status = body.status ?? existing.status;
  if (status !== "Present" && status !== "Absent") {
    return json(
      { success: false, error: "status must be Present or Absent" },
      400
    );
  }

  const studentName = body.student_name ?? existing.student_name;
  const scannedAt =
    body.scanned_at !== undefined ? body.scanned_at : existing.scanned_at;
  const qrToken =
    body.qr_token !== undefined ? body.qr_token : existing.qr_token;
  const deviceId =
    body.device_id !== undefined ? body.device_id : existing.device_id;

  await db
    .prepare(
      `UPDATE attendance_records
       SET student_name = ?, status = ?, scanned_at = ?, qr_token = ?, device_id = ?
       WHERE id = ?`
    )
    .bind(studentName, status, scannedAt, qrToken, deviceId, id)
    .run();

  const row = await db
    .prepare("SELECT * FROM attendance_records WHERE id = ?")
    .bind(id)
    .first();
  return json({ success: true, data: row });
}

async function deleteRecord(db, id) {
  const existing = await db
    .prepare("SELECT * FROM attendance_records WHERE id = ?")
    .bind(id)
    .first();
  if (!existing) return json({ success: false, error: "Record not found" }, 404);

  await db.prepare("DELETE FROM attendance_records WHERE id = ?").bind(id).run();
  return json({ success: true, message: `Record ${id} deleted` });
}

// =============================================================================
// Scan (classroom device)
// =============================================================================

async function scanAttendance(db, body) {
  // Accept either structured fields or qr_raw from Flutter QR
  let studentId = body?.student_id;
  let studentName = body?.student_name || null;
  let qrToken = body?.qr_token;
  let tokenExpiresAt = body?.token_expires_at ?? null;

  if (body?.qr_raw) {
    const parsed = parseQrRaw(body.qr_raw);
    if (!parsed) {
      return json({ success: false, error: "Invalid qr_raw format" }, 400);
    }
    studentId = parsed.student_id;
    qrToken = parsed.qr_token;
    tokenExpiresAt = parsed.token_expires_at;
  }

  const sessionId = String(body?.session_id || "").trim();
  const deviceId = body?.device_id || "CLASSROOM-CAM-01";

  if (!sessionId || !studentId || !qrToken) {
    return json(
      {
        success: false,
        error: "session_id, student_id, qr_token are required (or provide qr_raw)",
      },
      400
    );
  }

  const session = await db
    .prepare("SELECT * FROM attendance_sessions WHERE id = ?")
    .bind(sessionId)
    .first();

  if (!session) {
    return json({ success: false, error: "Session not found" }, 404);
  }

  if (Number(session.is_active) !== 1) {
    return json({ success: false, error: "Session is closed" }, 403);
  }

  if (tokenExpiresAt && Date.now() > Number(tokenExpiresAt)) {
    return json({ success: false, error: "QR token expired" }, 400);
  }

  // Optional: reject reused token in same session
  const tokenUsed = await db
    .prepare(
      `SELECT id FROM attendance_records
       WHERE session_id = ? AND qr_token = ? AND student_id != ?`
    )
    .bind(sessionId, qrToken, studentId)
    .first();

  if (tokenUsed) {
    return json({ success: false, error: "QR token already used" }, 409);
  }

  if (!studentName) {
    const enrolledName = await db
      .prepare(
        `SELECT student_name FROM course_enrollments
         WHERE course_id = ? AND student_id = ?`
      )
      .bind(session.course_id, studentId)
      .first();
    const existingName = await db
      .prepare(
        "SELECT student_name FROM attendance_records WHERE session_id = ? AND student_id = ?"
      )
      .bind(sessionId, studentId)
      .first();
    studentName =
      enrolledName?.student_name || existingName?.student_name || studentId;
  }

  return upsertRecord(db, {
    session_id: sessionId,
    student_id: studentId,
    student_name: studentName,
    status: "Present",
    scanned_at: nowIso(),
    qr_token: qrToken,
    device_id: deviceId,
  });
}
