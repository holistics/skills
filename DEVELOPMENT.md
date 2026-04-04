# Development Guide

## Repository structure

```
plugins/
  holistics-common/       # Shared source of truth for skills and references
    references/
    skills/
  holistics-development/  # Plugin for development workflows
  holistics-reporting/    # Plugin for reporting workflows
scripts/
  create-link.sh          # Add a shared skill/reference to a plugin
  sync-links.sh           # Sync all (or one) linked directories from source
```

## Shared content via links

Skills and references shared across plugins live in `plugins/holistics-common`. Other plugins reference them via a `.link` file — a plain text file containing the relative path to the source directory from the repo root.

When synced, the `.link` file is preserved inside a full copy of the source contents. The pre-commit hook keeps copies up to date automatically before every commit.

## Scripts

### Add a link to a plugin

```bash
./scripts/create-link.sh <source-path> <dest-plugin>
# e.g.
./scripts/create-link.sh plugins/holistics-common/skills/analyze-data plugins/holistics-development
```

Run with no arguments for an interactive picker:

```bash
./scripts/create-link.sh
```

### Sync all linked directories

```bash
./scripts/sync-links.sh
```

### Sync a single linked directory

```bash
./scripts/sync-links.sh plugins/holistics-development/skills/analyze-data
```

## Adding a new shared skill or reference

1. Create the skill/reference under `plugins/holistics-common/`.
2. Run `./scripts/create-link.sh` to link it into the relevant plugins.
