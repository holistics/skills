---
name: apply-chat-suggestions
description: Address suggestions in a past conversation's insight by performing each suggestion's actionable fix. Use when the user asks to implement, apply, address, or act on the suggestions from a conversation insight. Requires a conversation ID. Do NOT use this to generate a new insight.
---

## Input
- `conversation_id` (required) — ID of the conversation whose insight suggestions to address. If missing, ask the user.

## Insight shape
The `insight` returned by `fetch_conversation` has this structure:

    {
      "summary":  "Descriptive information about the conversation.",
      "recap":  "Useful information extracted from the interaction between user and agent.",
      "suggestions": [
        { "type": "...", "description": "...", "actionable": "..." }
      ]
    }

- The insight was based on your interaction with the users. Use these insights to help enrich the contexts provided to you.
- Only `suggestions[].actionable` items are things to *do*.
- `summary` and `recap` are background — use them to understand *why* a fix is needed and *how* to apply it well, never as fixes themselves.

## Context layers (where suggestions can be applied)
1. **Semantic and reporting layer** — data models, datasets, fields, dashboards, visualizations.
  - Main target audience: human analysts and business users.
2. **Custom context** — business background, expertise, terminology, response preferences. (Located in context.aml)
  - Main target audience: you (the AI agent)
3. **AI Skills** — reusable instructions for specific tasks, team-scoped workflows and conventions.
  - Main target audience: you (the AI agent).

## Workflow
1. Call `fetch_conversation` with the given ID. On error (not found, no access, etc.), surface the error and stop.
2. **No insight present** → tell the user, ask whether they want to generate one instead, and stop.
3. **Insight present but `suggestions` empty** → tell the user there's nothing to fix. Surface `summary` / `recap` for context, and stop.
4. **Suggestions present** → **STOP. Before calling any TOOL, list the target suggestions so the user sees the full scope** This will help users to quickly see which suggestions there are. The suggestions should be a list in this form:
   - `[type]` — *description*
     - Fix: *actionable*
     - Target layer: *one of the three above*
5. Process each suggestion. Classify the fix and act accordingly:
   - **Unambiguous**  → apply directly.
   - **Requires choices** (paths, names, scope) → ask the user first.
   - **Conflicting fixes** → surface the conflict; let the user resolve.
   - **Out of scope or no tool available** → skip and record for the report.

   All changes apply to the **current** conversation's context, not the original conversation's.
6. Report results: which suggestions were addressed, which were skipped, and why.