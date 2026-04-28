#!/usr/bin/env node
import { readFileSync } from 'fs'
import { resolve, dirname, relative } from 'path'
import { fileURLToPath } from 'url'
import { glob } from 'glob'
import matter from 'gray-matter'

const RED = '\x1b[31m'
const YELLOW = '\x1b[33m'
const RESET = '\x1b[0m'

const REPO_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const REQUIRED_FIELDS = ['name', 'description']

const files = await glob('plugins/**/SKILL.md', { cwd: REPO_ROOT, absolute: true })

const fileErrors = []

for (const file of files) {
  const rel = relative(REPO_ROOT, file)
  const content = readFileSync(file, 'utf8')
  const errs = []

  if (!content.startsWith('---')) {
    errs.push('missing frontmatter block')
  } else {
    let data
    try {
      ;({ data } = matter(content))
      for (const field of REQUIRED_FIELDS) {
        const val = data[field]
        if (!val || String(val).trim() === '') {
          errs.push(`missing or empty '${field}' field`)
        }
      }
    } catch (e) {
      const loc = e.mark ? ` (line ${e.mark.line + 1}, col ${e.mark.column + 1})` : ''
      errs.push(`invalid YAML${loc}: ${e.reason ?? e.message}`)
      errs.push(`hint: quote values that contain colons — description: "text: more text"`)
    }
  }

  if (errs.length) fileErrors.push({ rel, errs })
}

if (fileErrors.length === 0) {
  console.log(`All ${files.length} SKILL.md files have valid frontmatter.`)
} else {
  for (const { rel, errs } of fileErrors) {
    console.error(`${RED}✖ ${rel}${RESET}`)
    for (const msg of errs) {
      const color = msg.startsWith('hint:') ? YELLOW : RED
      console.error(`  ${color}${msg}${RESET}`)
    }
  }
  console.error(`\n${RED}${fileErrors.length} file(s) failed frontmatter validation.${RESET}`)
  process.exit(1)
}
