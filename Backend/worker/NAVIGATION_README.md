<!--
  Author / Project Supervisor : Omar Terro
  GitHub                      : https://github.com/IOTERRO
  Website                     : https://omarterro.fr
  Student (FYP)               : Khaled Othman
  Date                        : 14 October 2026
  Project                     : SmartUni - Smart University CityU
-->
# Navigation Worker (Locations)

Paste into Worker **`navigation`**

**File:** `navigation-worker.js`

| Item | Value |
|------|--------|
| Worker | `navigation` |
| URL | `https://navigation.khaledothman750.workers.dev` |
| D1 binding | `DB` â†’ `cityu` |
| Secret | `API_KEY` = `YOUR_CLOUDFLARE_API_KEY` |

## Deploy

1. Open Worker **navigation** â†’ **Edit code**
2. Delete old code
3. Paste full contents of `navigation-worker.js`
4. **Save and Deploy**
5. Confirm binding: `DB` â†’ `cityu`
6. Confirm Secret `API_KEY` exists
7. Ensure `location_edges` table exists in `cityu` (for `/api/navigation`)

## Test (PowerShell â€” no curl)

```powershell
$headers = @{ "X-API-Key" = "YOUR_CLOUDFLARE_API_KEY" }
$base = "https://navigation.khaledothman750.workers.dev"

Invoke-RestMethod -Uri "$base/api/health" -Headers $headers
Invoke-RestMethod -Uri "$base/api/locations" -Headers $headers
Invoke-RestMethod -Uri "$base/api/locations/search?q=lib" -Headers $headers
Invoke-RestMethod -Uri "$base/api/navigation?from=2&to=4" -Headers $headers
```

## Endpoints

| Method | Path |
|--------|------|
| GET | `/api/health` |
| GET | `/api/locations` |
| GET | `/api/locations/search?q=` |
| GET | `/api/navigation?from=&to=` |
| POST | `/api/locations` |
| PUT | `/api/locations/:id` |
| DELETE | `/api/locations/:id` |
| POST | `/api/admin/seed-walkways` |

After deploying the Worker, seed the walkway ring once:

```powershell
Invoke-RestMethod -Method POST -Uri "$base/api/admin/seed-walkways" -Headers $headers
```

Or paste `Backend/sql/campus_walkways_apply_now.sql` into D1 Console (`cityu`).
