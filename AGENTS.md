# Agent Instructions

## Issue Tracking

This project uses **bd** (beads) for issue tracking.
Start every session with:

```bash
bd prime
bd ready
```

Do not use ad-hoc markdown TODOs or TodoWrite for task tracking. Use `bd` issues as the source of truth.

## Quick Reference

```bash
bd ready                               # Find unblocked work
bd show <id>                           # View issue details
bd update <id> --status in_progress    # Claim work
bd close <id>                          # Complete work
bd sync                                # Sync issue state with git
```

## Current Initiative

The current main line is **native tmux sidebar MVP**.

Read these before touching code:

- `docs/native-sidebar-research.md`
- `docs/native-sidebar-prd.md`

Primary tracked work:

- `kmux-1n6` — Native sidebar MVP

Current ready tasks:

- `kmux-0c3` — Add client sidebar state and config surface
- `kmux-e5d` — Render native sidebar region in client redraw
- `kmux-cr0` — Route sidebar keyboard and mouse input in server client
- `kmux-jl1` — Reuse window tree and mode tree for sidebar data model

Recommended session start:

```bash
bd prime
bd ready
bd show kmux-1n6
bd show <task-id>
bd update <task-id> --status in_progress
```

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
