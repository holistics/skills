# Development Guide

## Prerequisites

Install [pnpm](https://pnpm.io/installation), then run:

```bash
pnpm install
```

This installs dependencies and sets up git hooks via husky.

## Repository structure

```
plugins/
  holistics-common/       # Shared source of truth for skills and references
    references/
    skills/
  holistics-development/  # Plugin for development workflows
  holistics-reporting/    # Plugin for reporting workflows
scripts/
  bump.js                 # Bump plugin version and update CHANGELOG
  create-link.sh          # Add a shared skill/reference to a plugin
  sync-links.sh           # Sync all (or one) linked directories from source
  validate-links.sh       # Validate linked directories match their source
```

## Shared content via links

Skills and references shared across plugins live in `plugins/holistics-common`. Other plugins reference them via a `.link` file — a plain text file containing the relative path to the source directory from the repo root.

When synced, the `.link` file is preserved inside a full copy of the source contents. Always edit the source in `holistics-common` and run `pnpm sync-links` to propagate changes.

## Scripts

### Bump a plugin version

Updates the plugin version in `.claude-plugin/plugin.json`, bumps the marketplace version in `.claude-plugin/marketplace.json` by the same semver increment, and prepends the new entries to `CHANGELOG.md`:

```bash
pnpm bump plugins/holistics-development 1.2.0
```

The marketplace version is treated as a semver dependent of the plugin — if the plugin gets a minor bump, the marketplace gets a minor bump too.

> Plugin versions control caching in Claude Code: users only receive updated content when the version changes. Always bump the version before releasing changes.

### Add a link to a plugin

```bash
pnpm create-link plugins/holistics-common/skills/analyze-data plugins/holistics-development
```

Run with no arguments for an interactive picker:

```bash
pnpm create-link
```

### Sync linked directories from source

```bash
pnpm sync-links                                                  # all links
pnpm sync-links plugins/holistics-development/skills/analyze-data  # one link
```

### Validate links

Checks that each linked directory matches its source, and warns about removed `.link` files:

```bash
pnpm validate-links
```

This also runs automatically as a pre-commit hook.

## Adding a new shared skill or reference

1. Create the skill/reference under `plugins/holistics-common/`.
2. Run `pnpm create-link` to link it into the relevant plugins.
