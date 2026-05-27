# Development Guide

## Prerequisites

Install [pnpm](https://pnpm.io/installation), then run:

```bash
pnpm install
```

This installs dependencies and sets up git hooks via husky.

## Commit conventions

Commits follow [Conventional Commits](https://www.conventionalcommits.org/) and are enforced by commitlint (the `commit-msg` git hook). The format is `<type>(<scope>): <subject>`, e.g. `chore(plugins.development): add naming convention to create-holistics-skill`. Multiple scopes are allowed, comma-separated.

The allowed `type` and `scope` values live in `.commitlintrc.ts` — update that file when adding a plugin.

Which commits show up in a release's `CHANGELOG.md` is decided separately by `conventional-changelog.config.mjs`: types marked `hidden: true` there (e.g. `chore`, `docs`, `refactor`) are committed but omitted from the changelog, while types like `feat`, `fix`, and `security` are surfaced under their sections.

Quick guidance on picking a `type`:
- `feat` — introducing a new plugin, skill, or feature - included in CHANGELOG.
- `fix` — fixing a bug in something that already exists - included in CHANGELOG.
- `chore` — small adjustments or tweaks to existing plugins/skills that aren't a fix.
- `docs` — changes to docs only (e.g. `README.md`, this guide).
- `release` — version bumps produced by `pnpm bump`.

## Repository structure

```
plugins/
  holistics-common/       # Shared source of truth for Holistics- skills and references
    references/
    skills/
  holistics-development/  # Plugin for Holistics development workflows
  holistics-reporting/    # Plugin for Holistics reporting workflows

  analytics/              # Plugin for generic analytics workflows (not Holistics-specific)
    skills/
scripts/
  bump.js                 # Bump plugin version and update CHANGELOG
  create-link.sh          # Add a shared skill/reference to a plugin
  sync-links.sh           # Sync all (or one) linked directories from source
  validate-links.sh       # Validate linked directories match their source
```

## Shared content via links

Skills and references can be shared across plugins. A skill is defined once in a *source* plugin (e.g. `holistics-common`, or `analytics` for generic skills). Each consumer holds a **full copy** of the source directory with a `.link` file at its root pointing back to the source path — the copy is what the AI agent actually loads, and `pnpm sync-links` keeps it in step with the source.

> **Always edit the source, never the copy.** Edits to a synced copy are overwritten on the next sync, and `pnpm validate-links` (run as a pre-commit hook) rejects copies that have diverged from their source.

### Common workflows

**Share an existing skill into another plugin**

```bash
pnpm create-link  # interactive picker for source + destination plugin
```

Or pass them explicitly:

```bash
pnpm create-link plugins/holistics-common/skills/analyze-data plugins/holistics-development
```

This copies the source into the destination, writes the `.link` file, and runs an initial sync.

**Update a shared skill**

1. Edit the files under the source (e.g. `plugins/holistics-common/skills/<name>/`).
2. Propagate changes to all consumers:

   ```bash
   pnpm sync-links                                                    # all links
   pnpm sync-links plugins/holistics-development/skills/analyze-data  # just one
   ```
3. Commit the source edits and the synced copies in the same commit.

**Unshare a skill from a plugin**

Delete the synced directory (the one containing the `.link` file) from the consumer. If no plugin still uses it, also delete the source.

**Verify everything is in sync**

```bash
pnpm validate-links  # runs automatically as a pre-commit hook
```

This checks that each linked directory matches its source and warns about missing sources.

## Scripts

### Bump a plugin version

Updates the plugin version in `.claude-plugin/plugin.json`, bumps the marketplace version in `.claude-plugin/marketplace.json` by the same semver increment, and prepends the new entries to `CHANGELOG.md`:

```bash
pnpm bump plugins/holistics-development 1.2.0
```

The marketplace version is treated as a semver dependent of the plugin — if the plugin gets a minor bump, the marketplace gets a minor bump too.

> Plugin versions control caching in Claude Code: users only receive updated content when the version changes. Always bump the version before releasing changes.
