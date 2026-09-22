# EPC OJS - Render Free Deploy (with OpenCode access)

This repo (`Thaha-28/EPC-ojs`) is ready for Render Docker free tier. OpenCode manages via `git push`.

## 1. Create free MySQL (Render has no free MySQL)

Pick one (free):

**A. PlanetScale (recommended, 5GB, serverless, no sleep):**
- Go https://planetscale.com → Sign up with GitHub → New Database `epc-ojs` → Create `main` branch → `Connect` → `Create password` → `General` → Copy `Host`, `Username`, `Password`, `Database` (port 3306). Keep `Require SSL`.

**B. FreeSQLDatabase.com (200MB, simple):**
- https://www.freesqldatabase.com → Create DB → copy host/user/pass/db.

**C. db4free.net (200MB)**

You will need: `DATABASE_HOST`, `DATABASE_PORT` (3306), `DATABASE_USER`, `DATABASE_PASSWORD`, `DATABASE_NAME`

## 2. Import seeded data (2 issues, 4 articles, 3 demo users)

Local dump is ready: `F:\WEB Dev\ojs-3.5.0-5\ojs_epc_dump.sql` (626KB, from local MariaDB `ojs_epc`).

Import to your free DB:

```bash
# via mysql client (PlanetScale requires SSL --ssl)
mysql -h <HOST> -P 3306 -u <USER> -p'<PASSWORD>' < ojs_epc_dump.sql --ssl

# or via PlanetScale `pscale` CLI: pscale database import ...
# or via FreeSQLDatabase phpMyAdmin → Import → ojs_epc_dump.sql
```

Seeded users:
- `admin / Admin123!` (admin@epc-journal.org)
- `author_epc / Author123!` (author@epc-journal.org) - Author
- `reviewer_epc / Reviewer123!`
- `editor_epc / Editor123!`

Seeded issues: `Vol.1 No.1 (2026)` (3 articles) + `Vol.1 No.2` (1 article) with DOIs `10.0000/epc...` and affiliations.

If you skip import, OJS will show installer at `https://your-url.onrender.com/index.php/index/install` — run wizard with same DB creds, then re-seed via `php seed_epc.php` (not needed if you imported).

## 3. Deploy to Render

- Render Dashboard → `New +` → `Web Service` → `Connect` `Thaha-28/EPC-ojs` → `Docker` → `Free` → `Add Disk` `ojs-files` `/var/www/ojs-files` `1GB`
- Env (from step 1 + your domain):
  - `DATABASE_HOST` = `aws.connect.psdb.cloud` (PlanetScale) or your host
  - `DATABASE_PORT` = `3306`
  - `DATABASE_USER` = `...`
  - `DATABASE_PASSWORD` = `...`
  - `DATABASE_NAME` = `epc-ojs` (or `ojs_epc`)
  - `OJS_BASE_URL` = `https://epc-ojs.onrender.com` (your Render URL, `https://` + `RENDER_EXTERNAL_HOSTNAME` auto)
  - `OJS_API_SECRET` = `EPC-API-Secret-2026-Secure-Random-Key-!@#12345` (same as local, needed for `OJS_API_TOKEN` JWT)
  - `OJS_SALT` = `YouMustSetASecretKeyHere!!`
  - `OJS_FILES_DIR` = `/var/www/ojs-files`
- `Deploy` → first boot runs `docker-entrypoint.sh:1` (writes `config.inc.php` from env, fixes perms, clears cache). Check logs: `OJS config prepared. base_url=...`

Health: `https://epc-ojs.onrender.com/index.php/epc` should show `Environmental Processes and Chemistry` with 2 issues.

## 4. Wire frontend (Vercel)

Vercel → `EPC-journal` → Settings → Env:

- `NEXT_PUBLIC_OJS_BASE_URL` = `https://epc-ojs.onrender.com/index.php/epc/api/v1`
- `OJS_API_TOKEN` = `eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.WyJlYTcxNTZjZjJjZDFiMWY2MzM1Y2ExMzQ1Mjg3ZDkyNjIwNmJkNTJiNzkzYWI0ZDIwNWYyZGY2ZGMxNGY5MDNiIl0.rjRrsJKHUSMlSjfaJx87PAP2plCBzm0cQJ1K6OflMJI` (from `F:\WEB Dev\EPC\.env.local:2`, valid for `author_epc`? Actually for `admin` old token `6a4c...` replaced by `ea71...` — use current `OJS_API_TOKEN` from local)

Redeploy frontend.

## 5. OpenCode access

OpenCode (Muse Spark) manages via:
- `git push` to `Thaha-28/EPC-ojs` and `Thaha-28/EPC-journal` (already linked via `gh` `Thaha-28`)
- Render auto-deploys on push, Vercel auto-deploys
- `bash` tool can `gh`, `git`, `pscale`, `render` CLI if you `render login`

Local still runs at `http://127.0.0.1:8080` (php -S) + MariaDB 3306 for dev. Cloud is prod.

## Troubleshooting

- `500` → check `RENDER_EXTERNAL_HOSTNAME` vs `OJS_BASE_URL` mismatch, or `allowed_hosts=''` (already fixed to `''` in `config.inc.php:100`).
- `Can't connect to DB` → check `DATABASE_HOST` includes `aws.connect.psdb.cloud` needs SSL, use `DATABASE_URL` with `?sslaccept=strict`.
- `files_dir` not writable → ensure Disk mounted at `/var/www/ojs-files`, `chown www-data`.
- `API token invalid` → `OJS_API_SECRET` must match local `config.inc.php:287` and `OJS_API_TOKEN` must be JWT for that secret (re-generate via `php new_token.php` if needed).

Dump: `ojs_epc_dump.sql` (626KB) is ready in `F:\WEB Dev\ojs-3.5.0-5\` — not committed (contains hashes). Use it for import.

