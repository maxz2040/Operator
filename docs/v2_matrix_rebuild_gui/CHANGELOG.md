# Operator GUI — Matrix Rebuild Changelog

Tracks our fork's deviations from upstream `web3dev1337/gastown-gui`.
Mirror of the changelog discipline used in the Nebuchadnezzar core fork.

When a rebase conflict surfaces, this file tells you what styling/labels/routing
to re-apply if upstream's changes wipe out our matrix layer.

## Phase 0 — Fork & sync infrastructure (2026-04-27)

- `scripts/sync-upstream.sh` — generalized upstream sync script.
  Tracks `upstream/master`, mirrors to local `master`, rebases
  `feature/matrix-theme` on top.
- `docs/v2_matrix_rebuild_gui/` — sync logs, CHANGELOG, fork-specific docs.

## Phase 1 — Reskin (2026-04-27)

### CSS palette swap (`css/variables.css`)

`:root` (dark theme) tokens replaced with Matrix neon-on-black palette,
mirroring Nebuchadnezzar Phase 1:

| Token group | Before (GitHub-dark) | After (Matrix) |
|---|---|---|
| `--bg-primary` | `#0d1117` | `#0D0208` |
| `--bg-secondary` | `#161b22` | `#0a1a0a` |
| `--text-primary` | `#e6edf3` | `#00FF41` |
| `--text-secondary` | `#8b949e` | `#008F11` |
| `--accent-primary` | `#58a6ff` | `#00FF41` |
| `--accent-warning` | `#d29922` | `#39FF14` |
| `--accent-danger` | `#f85149` | `#FF003C` |
| `--shadow-glow` | blue rgba | green rgba |

Light theme rebuilt as a "console daylight" tint (kept for upstream
data-theme compatibility; matrix-only by default).

### Animations / overlays (`css/animations.css`)

- Added `body::before` CRT scanline overlay (repeating 2px linear-gradient,
  `mix-blend-mode: screen`, `pointer-events: none`).
- Added `@keyframes matrixGlow` and `.matrix-glow` class. Logo gets it.

### HTML nomenclature sweep (`index.html`)

Safe-tier vocab map (visible strings only — IDs, classes, JS identifiers
preserved; protocol identifiers like `mayor/`, `polecat/`, `convoy_id`
intact). Map applied:

| Before | After |
|---|---|
| Gas Town | Operator (self) / Nebuchadnezzar (backend) |
| Mayor | Architect |
| Polecat / Polecats | Agent / Agents |
| Convoy / Convoys | Mission / Missions |
| Hook / Hooks | Hardline / Hardlines |
| Crew / Crews | Operators |
| Rig / Rigs | Construct / Constructs |
| Sling | Jack In |
| Town | Zion |

### JS user-facing strings

- `js/shared/agent-types.js` — `AGENT_TYPES.label` values updated to
  matrix vocab; protocol KEYS untouched. Colors swapped to matrix palette.
- `js/app.js` — toast: "Connected to Nebuchadnezzar"; agent action
  toasts say "agent" not "polecat"; init log mentions Operator.
- `js/components/tutorial.js` — full vocab pass through tutorial steps.
- `js/components/sidebar.js`, `dashboard.js`, `onboarding.js`,
  `rig-list.js`, `agent-grid.js`, `mail-list.js`, `modals.js` —
  visible labels swapped per map.

### Branding (`package.json`)

- `name`: `gastown-gui` → `operator`
- `version`: `0.9.5` → `0.9.5-matrix.0`
- `bin`: `gastown-gui` → `operator`
- `repository.url`: upstream → `maxz2040/Operator`
- `description`: rewritten as "Operator — Matrix-themed console GUI for
  Nebuchadnezzar"
- `keywords`: added `nebuchadnezzar`, `matrix`, `operator`
- `author`: marks the matrix theme; preserves upstream attribution

### Out of scope for Phase 1 (deferred)

- README.md rewrite — defer to Phase 3 (with proper running instructions
  once Phase 2 rerouting is done).
- Favicon assets — keep upstream favicons until we generate matrix-themed
  ones; logo TEXT is matrix-glowing already.
- Component CSS micro-tweaks (button hover states, etc.) — palette
  cascades through `var(--*)` so most components inherit correctly. Visual
  QA pass scheduled for Phase 3 when running in browser.

## Phase 2 — Reroute to Nebuchadnezzar (2026-04-27)

**Outcome:** Operator boots against our running Nebuchadnezzar with
zero code adapters. The upstream architecture was already env-var driven
through `GT_ROOT`, `GT_BIN`, `BD_BIN`, `GASTOWN_PORT`. Phase 2 was a
small wiring pass plus a startup wrapper.

### Smoke-test result (live, against /gt town as of 2026-04-27)

`GET /api/status` returned full state:
- `name`: `"gt"`, `dolt.port`: 3307, `daemon.running`: true
- 5 rigs detected: `audit_form_setup, cyber_baseline, datamask, neb, vss`
- 10 polecats, mayor + deacon active
- Title tag served: `"Operator — Matrix Console for Nebuchadnezzar"`

`GET /api/doctor`, `/api/convoys`, `/api/mail` all returned 200. No
adapter code required.

### Changes to `server.js`

```diff
-const PORT = process.env.GASTOWN_PORT || 7667;
-const HOST = process.env.HOST || '127.0.0.1';
-const GT_ROOT = process.env.GT_ROOT || path.join(HOME, 'gt');
+const PORT = process.env.OPERATOR_PORT || process.env.GASTOWN_PORT || 7667;
+const HOST = process.env.OPERATOR_HOST || process.env.HOST || '127.0.0.1';
+const GT_ROOT = process.env.GT_ROOT
+  || (fs.existsSync('/gt') ? '/gt' : path.join(HOME, 'gt'));
```

Boot banner replaced "GAS TOWN GUI SERVER" with "OPERATOR // MATRIX CONSOLE
— ONLINE / Driving Nebuchadnezzar".

### Changes to `bin/cli.js`

Full rewrite of the CLI surface:
- `operator [start|doctor|version|help]` (was `gastown-gui ...`)
- New env vars `OPERATOR_PORT` and `OPERATOR_HOST` honored as primary,
  with `GASTOWN_PORT` / `HOST` kept as legacy aliases.
- Doctor output mentions Nebuchadnezzar build path
  (`/gt/neb/mayor/rig`).
- `GT_ROOT` doctor probe falls back to `/gt` before `~/gt`.

### New: `scripts/start-operator.sh`

Boot wrapper that:
1. Sets `GT_ROOT=/gt` (our system) unless overridden.
2. Defaults port to 7667; honors `PORT=`, `OPERATOR_PORT=`.
3. Validates `GT_ROOT` exists and `gt` is in PATH.
4. Auto-runs `npm install` if `node_modules` missing.
5. Echoes resolved env (port, gt path, bd path) before launch.

### New: `docs/v2_matrix_rebuild_gui/RUNNING.md`

Full operator manual: env contract, smoke-test endpoints, architecture
note, stop instructions, two-fork sync ordering.

### Path layout assumptions

The upstream code already used:
- `path.join(GT_ROOT, rigName, 'mayor', 'rig')` ← our `/gt/<rig>/mayor/rig` ✓
- `path.join(GT_ROOT, '.events.jsonl')` ← `/gt/.events.jsonl` ✓
- `path.join(GT_ROOT, '.beads')` ← `/gt/.beads/` ✓
- `path.join(GT_ROOT, 'mayor')` ← `/gt/mayor/` ✓

All match Nebuchadnezzar's layout, so no path-rewriting was required.

### Out of scope for Phase 2 (deferred to Phase 3)

- Construct Bridge integration: Operator IS the bridge (server.js shells
  `gt`). The old Next.js dashboard's `construct_bridge/` becomes redundant
  on dashboard deprecation in Phase 3.
- README rewrite (will reference RUNNING.md from there).
- Visual QA pass against running browser (covered in Phase 3 testing).

## Phase 3 — Test, integrate, deprecate Next.js dashboard (2026-04-27)

### Tests

`npm test` against the matrix-reskinned `feature/matrix-theme`:

- **297 tests pass**, 46 skipped, 2 test files fail.
- The 2 failures are `e2e.test.js` and `integration.test.js`, both
  Puppeteer-driven. Failure cause: this OrbStack workspace runs arm64
  but the bundled Chromium binary is x86_64, so the browser process
  can't launch. **Not a regression** — purely an environment issue.
- All unit and shared-helpers tests are green, confirming our reskin
  did not break protocol contracts (agent-types keys preserved,
  exported APIs intact).

### Next.js dashboard deprecation

Removed `dashboard/` from Nebuchadnezzar `feature/matrix-theme`
(71 files, 6,501 lines). Operator is now the **canonical GUI** for
the matrix rebuild.

Commit on Nebuchadnezzar: `29237e577 chore: deprecate Next.js
dashboard in favor of Operator GUI fork`.

Original Next.js work preserved at Nebuchadnezzar commit `42ae594eb`
for any future salvage.

`construct_bridge/` kept — it has uses outside of the dashboard
(programmatic dispatch / state-sync). Will revisit deprecation if
it falls out of use.

### Maintenance guide updated

`/gt/project/v2_Matrix_Rebuild/MAINTENANCE_GUIDE.md` — added the
two-fork architecture table in the Phase 0 update, then refined
in Phase 3 with the canonical-GUI decision and run instructions.

### Phase 3 — out of scope (genuinely future work)

- README.md rewrite for Operator (currently still lists upstream
  copy). Will rewrite when there's a stable user-facing story to tell.
- Visual QA pass in browser at multiple viewport sizes — depends on
  having a workspace where Puppeteer can run, or doing it manually.
- Favicon/asset rebrand to matrix-themed graphics. The text logo
  with `matrix-glow` already provides identity; full asset rebrand
  is cosmetic polish, not blocking.
