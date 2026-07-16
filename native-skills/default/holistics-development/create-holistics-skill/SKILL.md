---
name: create-holistics-skill
description: Author a Holistics skill. Use whenever the user wants to write, edit, or refine a skill that gives Holistics AI specific knowledge, workflows, or guardrails — including phrasings like "add a skill for X", "create a workspace glossary skill", "turn this prompt into a reusable skill", or "make this Holistics AI smarter about Y". For converting a skill written for another runtime (Claude, OpenAI/Codex) into AML, use `convert-agent-skill-to-holistics` instead.
---

# Creating a Holistics skill

A skill is a persistent, named bundle of instructions and knowledge that Holistics AI loads when invoked. This guide walks you through authoring one as an AML `Skill` block placed at `settings/ai/skills/<skill_name>/skill.aml`.

If the user is porting an existing Claude or OpenAI/Codex skill into Holistics — or vice versa — use the `convert-agent-skill-to-holistics` skill instead.

A skill is the **wrong** tool when:

- The request is a one-off prompt. Just ask the agent directly.
- The knowledge belongs in a dataset or model. Put it there.
- The workflow is already something the agent does well unprompted.

## Anatomy of a Holistics skill

A Holistics skill is a single AML `Skill` block — no directory structure, no bundled scripts or references, just one block in one file.

Every skill has four parts:

1. **Name** — the identifier in `Skill <name> { ... }`. User-visible in Holistics AI's skill list, and the handle for manual invocation. Use an imperative verb phrase in `kebab-case` — e.g., `create-holistics-skill`, `define-company-metrics`.
2. **Description** (`description`) — what Holistics AI reads *before* loading the body to decide whether to invoke. The single highest-leverage line in the skill.
3. **Body** (`content`) — the instructions, knowledge, and examples loaded into the conversation when the skill triggers.
4. **Invocation controls** (`invocation`, `allow_switching_invocation`, `disabled`) — govern whether the agent or the user activates the skill, and whether it's hidden at all.

### Progressive disclosure

Holistics AI loads a skill in two stages:

1. **Always loaded** — name + description. Present in the agent's available-skills list at every turn.
2. **Loaded only when the skill triggers** — body content.

This is why "when to use" must live in the description, not the body — the body isn't read until the triggering decision has already been made.

### Optional features

Available as needed (see [Step 4](#step-4--choose-features)):

- **Slots** — make `description`, `content`, or `disabled` dynamic per user, workspace, or role.
- **`@Skill:` references** — compose skills by linking to another skill's content.
- **Role-gating** — conditionally enable/disable based on `H.current_user`.

## Core principles

The principles below are universal — they apply when writing the description, the body, or any inline example.

### Concise is key

The body loads into every conversation that triggers the skill. The context window is a shared resource — it carries the system prompt, conversation history, other skills' metadata, and the user's actual request. Don't repeat what the model already knows. Challenge each paragraph: *does this earn its token cost?* If removing it wouldn't degrade output, remove it.

### Explain the why

"Filter on partition columns to reduce scan cost" beats "ALWAYS filter on partition columns." When the agent knows the reason, it can apply judgment to edge cases. Heavy-handed MUSTs strip that capacity. If you find yourself writing ALL CAPS imperatives, ask whether stating the *reason* would do the same job more robustly.

### Match degrees of freedom to fragility

Match the specificity of your instructions to the task's variability:

- **High freedom** (prose, heuristics) — when multiple approaches are valid and context determines the best one.
- **Medium freedom** (pseudocode, structured patterns) — when a preferred pattern exists but variation is acceptable.
- **Low freedom** (rigid templates, exact snippets) — when operations are fragile, consistency is critical, or a specific sequence must hold.

Think of the agent as walking a path: a narrow bridge with cliffs needs guardrails; an open field allows many routes.

### Theory of mind

The agent reading the skill is intelligent and has good general knowledge. Write for the smartest reader you can imagine, and give them only the information they don't already have. Don't lecture about basics; don't pad with safety-blanket disclaimers; don't restate what's already in the workspace's datasets, models, or dashboards.

## Writing style

### Imperative form

"Generate a summary" — not "you should generate a summary." The agent reads the body as direct instructions; hedging like "you should" or "the agent will" wastes tokens and weakens the directive.

### Define output formats with templates

When the output shape matters, show a template rather than describing it in prose:

```markdown
## Report structure
Use this exact template:
# [Title]
## Executive summary
## Key findings
## Recommendations
```

### Examples pattern

When behavior depends on input shape, show `Input → Output` side by side:

```markdown
**Example 1:**
Input: Added user authentication with JWT tokens
Output: feat(auth): implement JWT-based authentication
```

## Creation process

Walk through the seven steps below in order. The [principles](#core-principles) and [writing style](#writing-style) above apply throughout; the steps just tell you when each one matters most.

### Step 1 — Capture intent

Ground the skill in concrete examples before writing anything. Ask one question at a time, not all at once:

1. What should this skill enable Holistics AI to do?
2. When should it trigger? Give two or three phrasings a real user would type.
3. What is the expected output or behavior?
4. Who is the audience? (Analyst, viewer, developer — affects role-gating, tone, depth.)

If the conversation already contains examples, a draft, or an existing skill being converted, extract from that history first and only ask for gaps. Don't re-ask things the user already showed you.

### Step 2 — Draft the description

The description is the highest-leverage line in the entire skill (see [Anatomy → Progressive disclosure](#progressive-disclosure)). Get it right or the rest of the skill never runs.

Rules specific to the description:

- State **what** the skill does AND **when** to use it. Both are required.
- Be pushy. Include concrete trigger phrasings. Holistics AI undertriggers skills by default.
- The description is also user-visible in the workspace skill list — write so it reads cleanly to a human, not just to an LLM.

Paired examples — note how the "Good" version names the trigger surface:

**Bad** (vague, no triggers):
```
description: "Provides company metric definitions."
```

**Good** (what + when + phrasings):
```
description: "Use whenever the user asks about or references MRR, ARR, churn rate, CAC, LTV, or other recurring-revenue metrics — including phrasings like 'what's our MRR this quarter', 'plot churn over time', 'who has the highest CAC' — to ensure Acme-specific definitions are applied."
```

**Bad** (describes the skill without naming the trigger):
```
description: "Generates an executive summary from query results."
```

**Good** (names the trigger surface):
```
description: "Use when the user asks for an executive summary, exec readout, or C-level summary of the current query results. Typical phrasings: 'summarize this for the exec team', 'give me a one-pager', 'turn this into a QBR slide'."
```

### Step 3 — Draft the body

Apply the [core principles](#core-principles) and [writing style](#writing-style). The body should contain only what the agent needs but doesn't already know — typically definitions, decision criteria, output templates, and worked examples.

Canonical example — body of an auto-invoked passive-context glossary:

```markdown
## Metric definitions

- **MRR**: Monthly Recurring Revenue — sum of all active subscription amounts normalized to a monthly value.
- **ARR**: Annual Recurring Revenue — MRR × 12.
- **Churn Rate**: percentage of customers who cancelled in the period. Reported on the last day of each month against the prior month's active customer count.
- **CAC**: Customer Acquisition Cost — total sales + marketing spend in a period divided by new customers acquired in that period.
```

Notice what's absent: no "when to use" instructions (those live in the description), no MUSTs, no restating what subscription revenue is. Just the definitions the agent needs to be accurate.

### Step 4 — Choose features

Decide which Holistics features the skill uses. Each is independent; pick only what the skill needs.

#### Auto vs manual invocation

- **Auto** for passive context and guidelines (glossaries, query rules, business definitions, naming conventions, style guides). The agent pulls them in whenever they're relevant.
- **Manual** for named, on-demand transforms (`executive_summary`, `qbr_pack`, `investor_email`). The user explicitly invokes by name.
- **Never auto for irreversible side effects.** If the skill writes, sends, or deletes anything, make it manual so the user can intercept a mistaken invocation.

#### `allow_switching_invocation`

Lets end-users flip between auto and manual. Most skills should leave this off. Turn it on when admins or power users should be able to silence a normally-auto skill (or vice versa) per session.

#### Composition with `@Skill:`

When two skills naturally share a knowledge unit (a glossary, a set of rules), extract the shared piece into its own skill and reference it. Example — `query_guidelines` referencing the glossary above:

```aml
Skill query_guidelines {
  description: "Use whenever the user writes a SQL or AQL query against the warehouse — enforce partition filters, avoid SELECT *, cap exploratory queries with LIMIT."
  content: @md
    Always follow these guidelines when writing queries:
    - Filter on partition columns to reduce scan cost
    - Avoid SELECT * in production queries
    - Add a LIMIT clause when exploring large tables

    Refer to @Skill:company_glossary for metric definitions.
  ;;
}
```

Holistics resolves the `@Skill:company_glossary` reference at invocation time, pulling in the glossary alongside the guidelines.

#### Slot parameterization

Use Slots when `description`, `content`, or `disabled` should be dynamic per user, workspace, or role. Common cases: workspace name in the description, region-specific guidelines, role-conditional disabling.

```aml
Skill query_guidelines {
  description: "Enforces query best practices and performance guidelines for this workspace"
  allow_switching_invocation: H.current_user.h_role != 'viewer'
  content: @md
    Always follow these guidelines when writing queries:
    - Filter on partition columns to reduce scan cost
    - Avoid SELECT * in production queries
  ;;
}
```

`H.current_user.h_role != 'viewer'` is an AML expression evaluated at runtime — viewers cannot toggle the invocation mode here.

### Step 5 — Wrap + place

```aml
Skill <skill_name> {
  description: "..."
  invocation: 'auto'
  content: @md
    ## Heading
    body content
  ;;
}
```

Place at `settings/ai/skills/<skill_name>/skill.aml`. The directory name should match the identifier inside the `Skill` block.

### Step 6 — Validate

- Run `holistics aml validate` if the Holistics CLI is installed.
- Read the skill back as a stranger. Does the description make trigger conditions obvious? Does the body explain "why" wherever the agent will need to apply judgment? If either is unclear, fix it now before iterating.

### Step 7 — Iterate

There is no prescribed eval harness here. Use these two diagnostic levers instead:

- **Description is the lever for triggering.** If the skill doesn't fire when it should, fix the description first. Add concrete phrasings, add domain keywords, push harder. Resist the urge to edit the body until you've confirmed triggering works.
- **Body is the lever for output quality.** If the skill fires but produces the wrong output, fix the body. Common causes: too vague, too many MUSTs (the agent loses room to apply judgment), missing `Input → Output` examples, or restating things the model already knows.

Three iterations is typical. If you find yourself rewriting the whole skill, the intent (Step 1) was probably unclear — go back and re-capture it before continuing.

## Anti-patterns

Each one below is a common mistake and the reason it fails:

- **Vague description without trigger contexts.** Description has no "when to use", or only generic keywords. → Undertriggers; the agent never reaches the skill.
- **"When to use" duplicated in the body.** Both description and body explain when to invoke. → Wastes tokens; the body is only loaded post-trigger, so the duplication is unread.
- **Walls of MUST / NEVER.** The body is mostly all-caps imperatives. → Brittle; the agent loses room to apply judgment, and the prose is painful to maintain.
- **Restating what the model knows.** "SQL is a query language." "Be helpful and accurate." → Tokens that don't pull their weight.
- **Conflating skill with dataset/model knowledge.** The skill contains schema details, column definitions, or metric formulae that belong in the AML dataset or model. → The dataset is the source of truth; skill drift becomes inevitable.
- **Auto-invoke for an irreversible action.** A skill that sends an email, writes to production, or deletes a file is auto. → The user cannot intercept a mistaken invocation.
- **One mega-skill instead of two composed skills.** A single skill covers multiple unrelated triggers (glossary + query rules + summary template). → Harder to trigger reliably; description becomes incoherent; harder to maintain.

## Quick reference

### AML `Type Skill` grammar

```aml
Type SkillInvocation = 'auto' | 'manual'

Type Skill (elem_name_as: 'name') {
  label (optional): String
  description: String | Heredoc[Any] | Slot[String] | Slot[Heredoc[Any]]
  disabled (default: false): Boolean | Slot[Boolean]
  invocation (default: 'auto'): SkillInvocation | Slot[SkillInvocation]
  allow_switching_invocation (default: false): Boolean | Slot[Boolean]
  content: Heredoc[Any] | Slot[Heredoc[Any]]
}
```

Field semantics:

- `description` — what the skill does and when to use it. Holistics AI reads this to decide whether to invoke.
- `disabled` — hide the skill from both the agent and end-users.
- `invocation` — `'auto'` (agent decides) or `'manual'` (user must invoke by name).
- `allow_switching_invocation` — let end-users toggle between auto and manual on the fly.
- `content` — the instructions loaded into context when the skill triggers.

### Constraints

- AML skills must live under `settings/ai/` to be discovered by Holistics AI.
- Skills are available only to the Agentic chat model, not the Quick generation model.
- Best practice: one skill per directory at `settings/ai/skills/<skill_name>/skill.aml`. Keep the directory name in sync with the `Skill` block's identifier.
