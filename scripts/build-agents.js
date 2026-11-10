#!/usr/bin/env node
// Render plugins/<plugin>/agent-templates/*.md into plugins/<plugin>/agents/*.md,
// replacing each `<!-- include: <path> -->` line with the contents of <path>
// (relative to the plugin directory). Pass --check to fail instead of writing
// when a rendered agent is out of date.
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'fs'
import { resolve, dirname, basename, relative } from 'path'
import { fileURLToPath } from 'url'
import { glob } from 'glob'

const RED = '\x1b[31m'
const RESET = '\x1b[0m'

const REPO_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const check = process.argv.includes('--check')
const INCLUDE = /^<!-- include: (.+?) -->$/gm

const templates = await glob('plugins/*/agent-templates/*.md', { cwd: REPO_ROOT, absolute: true })

let stale = 0
for (const template of templates) {
  const pluginDir = resolve(dirname(template), '..')
  const rendered = readFileSync(template, 'utf8').replace(INCLUDE, (_, path) =>
    readFileSync(resolve(pluginDir, path), 'utf8').trim(),
  )
  const out = resolve(pluginDir, 'agents', basename(template))
  const rel = relative(REPO_ROOT, out)
  const current = existsSync(out) ? readFileSync(out, 'utf8') : null

  if (current === rendered) continue
  if (check) {
    console.error(`${RED}✖ ${rel} is out of date${RESET}`)
    stale++
  } else {
    mkdirSync(dirname(out), { recursive: true })
    writeFileSync(out, rendered)
    console.log(`Built ${rel}`)
  }
}

if (stale) {
  console.error(`\n${RED}${stale} agent(s) out of date. Run \`pnpm build-agents\` and commit the result.${RESET}`)
  process.exit(1)
}
console.log(check ? `All ${templates.length} agent(s) up to date.` : 'Agents built.')
