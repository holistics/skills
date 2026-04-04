#!/usr/bin/env node

import { execSync } from 'child_process'
import { existsSync, readFileSync, writeFileSync } from 'fs'
import { basename, dirname, resolve } from 'path'
import { fileURLToPath } from 'url'
import semver from 'semver'

const REPO_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const [, , path, version] = process.argv

if (!path || !version) {
  console.error('Usage: bump.js <plugin-path> <version>')
  console.error('  e.g. bump.js plugins/holistics-development 1.0.0')
  process.exit(1)
}

if (!/^plugins\//.test(path)) {
  console.error(`Invalid path: ${path}. Path must start with plugins/`)
  process.exit(1)
}

if (!existsSync(resolve(REPO_ROOT, path))) {
  console.error(`${path} is not a directory`)
  process.exit(1)
}

if (!/^\d+\.\d+\.\d+/.test(version)) {
  console.error(`Invalid version: ${version}`)
  process.exit(1)
}

const pluginName = basename(path)

execSync('git fetch --tags', { stdio: 'inherit' })

// Update version in plugin.json
const pluginJsonPath = resolve(REPO_ROOT, path, '.claude-plugin/plugin.json')
const pluginJson = JSON.parse(readFileSync(pluginJsonPath, 'utf8'))
const prevVersion = pluginJson.version
pluginJson.version = version
writeFileSync(pluginJsonPath, JSON.stringify(pluginJson, null, 2) + '\n')
console.log(`Updated ${pluginJsonPath}: ${prevVersion} -> ${version}`)

// Bump marketplace version using the same semver increment type
const marketplacePath = resolve(REPO_ROOT, '.claude-plugin/marketplace.json')
const marketplace = JSON.parse(readFileSync(marketplacePath, 'utf8'))
const prevMarketplaceVersion = marketplace.metadata.version
const releaseType = semver.diff(prevVersion, version)
marketplace.metadata.version = semver.inc(prevMarketplaceVersion, releaseType)
writeFileSync(marketplacePath, JSON.stringify(marketplace, null, 2) + '\n')
console.log(`Updated ${marketplacePath}: ${prevMarketplaceVersion} -> ${marketplace.metadata.version}`)

// Write context for conventional-changelog
const contextFile = '/tmp/holistics-skills-bump-context.json'
writeFileSync(contextFile, JSON.stringify({ version }) + '\n')

const cmd = [
  'pnpm conventional-changelog',
  `-n conventional-changelog.config.mjs`,
  `-c ${contextFile}`,
  `-i "${path}/CHANGELOG.md"`,
  `-t "${pluginName}-v"`,
  `--commit-path "${path}"`,
].join(' \\\n  ')

console.log(cmd)
execSync(cmd, { stdio: 'inherit', cwd: REPO_ROOT })

