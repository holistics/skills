---
name: convert-agent-skill-to-holistics
description: Convert an agent skill written for another runtime (Claude `SKILL.md`, OpenAI/Codex skill, raw system prompt) into a Holistics AML `Skill` block — or the reverse direction. Use whenever the user wants to migrate, port, or translate a skill across formats, including phrasings like "convert this Claude skill to AML", "port this OpenAI skill to Holistics", "turn this SKILL.md into an AML Skill", "translate this AML skill back to Claude", or "migrate this agent skill".
---

# Converting an agent skill into a Holistics AML Skill

Use this skill when porting an agent skill between Holistics AML and another runtime (Claude `SKILL.md`, OpenAI/Codex skill, raw system prompt). What changes is the wrapper, the file path, and a handful of field semantics; the skill's purpose and content stay the same.

For the principles that govern *how* a good Holistics skill is written — description triggers, concise body, explain-the-why — see the `create-holistics-skill` skill. Apply those after the mechanical conversion below.

## Field mapping

| Holistics AML | Claude / OpenAI Markdown `SKILL.md` |
|---|---|
| `Skill <name> { ... }` block | YAML frontmatter + Markdown body |
| `description: "..."` | frontmatter `description:` |
| `content: @md ... ;;` | Markdown body below the frontmatter |
| `invocation` field | see invocation tables below |
| `disabled: true` | delete the file, or the equivalent field if the host runtime supports it |
| `Slot[...]` parameters | no direct equivalent — inline the resolved values, or split into multiple skills |
| `@Skill:other_skill` reference | reference by name in prose; the consuming agent navigates via its own skill tool |
| `H.current_user.<...>` gating | no direct equivalent — split into separate skills or inline conditions in the body |
| Placed at `settings/ai/<name>/skill.aml` | Placed at the consuming tool's project-skill path (commonly `.claude/skills/<name>/SKILL.md`) |

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

## Conversion workflow

1. Capture the source skill's name and description.
2. Rewrite the description for Holistics AI's triggering surface — concrete phrasings, what + when. Don't paste the original verbatim; trigger surfaces differ between agents.
3. Move the body content into `content: @md ... ;;`. Strip any "when to use" lines that have migrated into the body (in Holistics, those belong in `description`).
4. Map invocation fields using the tables above.
5. For each AML-only feature the source can't express (Slots, `@Skill:`, role-gating), decide whether to use it now (going to AML) or how to inline it (going to Markdown).
6. Place at `settings/ai/<name>/skill.aml` (or the target tool's project-skill path if going the other direction).
