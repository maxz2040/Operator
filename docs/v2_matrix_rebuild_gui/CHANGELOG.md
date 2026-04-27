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

## Phase 1 — Reskin

_(pending)_

Will mirror the Nebuchadnezzar Phase 1 vocab map and matrix CSS palette.
See `/gt/neb/mayor/rig/docs/v2_matrix_rebuild/CHANGELOG.md` for the source of
truth on naming/colors.

## Phase 2 — Reroute to Nebuchadnezzar

_(pending)_

Will retarget `server.js` and CLI shells from stock gastown to our
Nebuchadnezzar build. State paths → `/gt/neb/...`. Dolt → port 3307,
our beads schema. Validate against upstream `CLI-COMPATIBILITY.md`.

## Phase 3 — Test, integrate, deprecate Next.js dashboard

_(pending)_

Operator becomes the canonical GUI. The Next.js `dashboard/` in
Nebuchadnezzar core is retired (or repurposed for non-overlapping role).
