---
name: Running Operator against Nebuchadnezzar
description: Boot, environment, and verification steps for the Operator GUI driving our matrix gastown
type: ops-doc
---

# Running Operator

Operator is a Node.js Express + WebSocket server that shells the `gt` and `bd`
CLIs and reads town state under `GT_ROOT`. There are no Go components — this
is a pure adapter to your already-running Nebuchadnezzar town.

## Quick start

```bash
cd /gt/neb/gui/rig
./scripts/start-operator.sh
```

That's it. The wrapper:
- Sets `GT_ROOT=/gt` (our system layout, not the upstream `~/gt` default)
- Picks port `7667` (override with `PORT=...` or `OPERATOR_PORT=...`)
- Verifies `gt` is reachable
- Runs `npm install` if `node_modules` is missing
- Launches the server

Open http://127.0.0.1:7667 in a browser.

## Environment contract

Operator reads exactly four env vars. Defaults are sensible for our system.

| Var | Default | Purpose |
|---|---|---|
| `GT_ROOT` | `/gt` if it exists, else `~/gt` | Town root — where rigs, mayor, daemon, beads live |
| `GT_BIN` | `which gt` | Path to the `gt` binary |
| `BD_BIN` | `which bd` | Path to the `bd` binary |
| `OPERATOR_PORT` | `7667` (alias `GASTOWN_PORT`) | HTTP/WS listen port |
| `OPERATOR_HOST` | `127.0.0.1` (alias `HOST`) | Bind address |

If you build a custom Nebuchadnezzar `gt` and don't put it in PATH, point
`GT_BIN` at it explicitly:

```bash
GT_BIN=/gt/neb/mayor/rig/bin/gt ./scripts/start-operator.sh
```

## Verifying it's wired correctly

After boot, hit these endpoints — they should all return real data from your
running town, not empty/error responses:

```bash
PORT=7667
curl -s http://127.0.0.1:$PORT/api/status   | jq '.name, .daemon.running, .dolt.port, (.rigs | length)'
curl -s http://127.0.0.1:$PORT/api/doctor   | jq '.raw' | head -20
curl -s http://127.0.0.1:$PORT/api/convoys  | jq 'length'
curl -s http://127.0.0.1:$PORT/api/mail     | jq 'length'
```

Expected first-line outputs against our town as of 2026-04-27:
- `name`: `"gt"`
- `daemon.running`: `true`
- `dolt.port`: `3307`
- `rigs | length`: `5`

If `daemon.running` is `false` or `dolt.port` is missing, your Nebuchadnezzar
isn't booted — run `gt dolt start` and `gt daemon start` first.

## Architecture (what Operator actually does)

`server.js` is a thin gateway. It does NOT own state; it only:
1. Shells `gt <command>` for status, convoys, agents, doctor.
2. Shells `bd <command>` for beads (issues).
3. Reads `${GT_ROOT}/.events.jsonl` to stream the activity feed.
4. Reads `${GT_ROOT}/<rig>/config.json` for per-rig metadata.
5. Touches tmux for session info.

This means: as long as our Nebuchadnezzar `gt` produces output upstream-shaped
(which it does — the 3-Tier Blast Radius rule kept Go internals untouched),
Operator works without code changes.

The 192-commit gastown 1.0.1 sync already absorbed and the matrix rebuild's
behavioral parity with upstream is what makes this Phase 2 trivial. If we
ever diverge `gt` output shape, we'd need to add adapters here.

## Stopping

`Ctrl+C` in the terminal. The server installs SIGINT/SIGTERM handlers and
shuts WebSocket + HTTP cleanly.

## Two-fork sync workflow reminder

When upstream `web3dev1337/gastown-gui` ships changes, sync in this order:
1. Sync core first: `cd /gt/neb/mayor/rig && ./scripts/sync-upstream.sh`
2. Sync GUI second: `cd /gt/neb/gui/rig && ./scripts/sync-upstream.sh`

See `/gt/project/v2_Matrix_Rebuild/MAINTENANCE_GUIDE.md` for the rationale.
