---
name: convert-agent-skill-to-holistics
description: Convert an agent skill written for another runtime (Claude `SKILL.md`, OpenAI/Codex skill, raw system prompt) into a Holistics AML `Skill` block — or the reverse direction. Use whenever the user wants to migrate, port, or translate a skill across formats, including phrasings like "convert this Claude skill to AML", "port this OpenAI skill to Holistics", "turn this SKILL.md into an AML Skill", "translate this AML skill back to Claude", or "migrate this agent skill".
---

# Converting an agent skill into a Holistics AML Skill

Use this skill when porting an agent skill between Holistics AML and another runtime (Claude `SKILL.md`, OpenAI/Codex skill, raw system prompt). What changes is the wrapper, the file path, and a handful of field semantics; the skill's purpose and content stay the same.

For the principles that govern *how* a good Holistics skill is written — description triggers, concise body, explain-the-why — see the `create-holistics-skill` skill. Apply those after the mechanical conversion below.

## Features that map directly

| Holistics AML | Claude / OpenAI Markdown `SKILL.md` |
|---|---|
| `Skill <name> { ... }` block | YAML frontmatter + Markdown body |
| `description: "..."` | frontmatter `description:` |
| `content: @md ... ;;` | Markdown body below the frontmatter |
| `invocation` field | see invocation tables below |
| `disabled: true` | delete the file (or the equivalent field if the host runtime supports it) |
| Placed at `settings/ai/skills/<name>/skill.aml` | Placed at the consuming tool's project-skill path (commonly `.claude/skills/<name>/SKILL.md`) |

## Invocation mapping — from Claude

| `disable-model-invocation` | `user-invocable` | AML Skill |
|---|---|---|
| false *(default)* | false | `invocation: 'auto'` |
| false *(default)* | true *(default)* | `invocation: 'auto'` |
| true | true *(default)* | `invocation: 'manual'` |
| true | false | `disabled: true, invocation: 'manual'` |

## Invocation mapping — from OpenAI/Codex

| `allow_implicit_invocation` | AML Skill |
|---|---|
| true *(default)* | `invocation: 'auto'` |
| false | `invocation: 'manual'` |

## Handling incompatibilities

Agent skills and Holistics skills cover different sets of functionalities. For example:

- Agent skills can bundle `references/*` documents and `scripts/*` executables; Holistics skills currently cannot.
- Holistics skills can be parameterized via the programmatic AML `Slot[...]` mechanism; agent skills cannot.

The exact list of differences may change over time; treat any feature in the source skill not covered by the mapping tables above as an incompatibility.

When the source skill uses an incompatible feature, do not silently drop, inline, or translate it. The right move depends on how that feature is being used in the source skill, and only the user can tell you.

For each incompatible feature found:

1. State which feature it is and why it has no equivalent in the target.
2. Quote or describe what the feature is doing in the source skill (the `Slot`'s purpose, the script's behavior, the role-gate's condition).
3. Ask the user how to handle it in the target. Don't suggest a specific answer; let them decide.
4. Apply the user's answer and continue. If multiple incompatibilities exist, ask about each separately — they may want different treatment.

If the user opts to defer, emit the converted skill *without* the incompatible feature and call out in the conversion summary exactly what was left out, so they can rebuild it elsewhere (MCP tool, dataset, separate skill) later.

## Conversion workflow

1. Capture the source skill's name and description.
2. Rewrite the description for Holistics AI's triggering surface — concrete phrasings, what + when. Don't paste the original verbatim; trigger surfaces differ between agents.
3. Move the body content into `content: @md ... ;;`. Strip any "when to use" lines that have migrated into the body (in Holistics, those belong in `description`).
4. Map invocation fields using the tables above.
5. Scan the source skill for any feature that isn't covered by the mapping tables above. For each one found, halt and ask the user — see [Handling incompatibilities](#handling-incompatibilities). Resume the workflow with their decisions applied.
6. Place at `settings/ai/skills/<name>/skill.aml` (or the target tool's project-skill path if going the other direction).
