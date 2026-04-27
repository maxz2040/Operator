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

## Phase 2 — Reroute to Nebuchadnezzar

_(pending)_

Will retarget `server.js` and CLI shells from stock gastown to our
Nebuchadnezzar build. State paths → `/gt/neb/...`. Dolt → port 3307,
our beads schema. Validate against upstream `CLI-COMPATIBILITY.md`.

## Phase 3 — Test, integrate, deprecate Next.js dashboard

_(pending)_

Operator becomes the canonical GUI. The Next.js `dashboard/` in
Nebuchadnezzar core is retired (or repurposed for non-overlapping role).
