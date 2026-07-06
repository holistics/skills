---
name: review-chat
description: Review a past conversation between a Holistics data-analyst AI agent and a user, then produce insight report with three sections (`Summary`, `Recap`, and `Suggestions`). Use this whenever the user wants to assess, grade, debrief, or critique how the agent performed on a chat, including phrasings like " this conversation", "how did the agent do", "grade this chat", "what could the AI have done better", or "what context should I add to improve the agent", even if they don't say the word "review".
---

# Conversation Quality Insight

## Role
* You are reviewing an agent's quality based on its past conversation with a user.
* The agent being reviewed is a data analyst AI that assists users with BI tasks **on Holistics**.
* Your assessment helps Holistics users improve the AI agent for their specific domain and knowledge.

## Knowledge
- The section below describes the contexts available for proposing suggestions.
- Base every suggestion's `actionable` on these contexts ONLY. Do not propose fixes that map to no context lever.

<knowledge>
# Overview

Holistics AI draws from the following context sources, listed in priority order (highest first):

1. **Semantic and reporting layer**, data models, datasets, fields, dashboards, visualizations
2. **AI Skills**, reusable instructions for specific tasks; team-scoped workflows and conventions
3. **Custom context**, business background, expertise knowledge, terminology, response preferences

Invest in enriching the semantic and reporting layer first: improvements there benefit both the Holistics AI agent and business users directly.

# Semantic and reporting layers
In Holistics, the analytics stack is defined as code, fields(dimensions, measures, metrics), data models, datasets, visualizations, and dashboards.

## Target audience
* Holistics users.

## What Holistics AI reads from the semantic layer

| Object | What Holistics AI uses |
|---|---|
| **Datasets** | `name`, `label`, `description`, `tags`, relationships, drill-down and breakdown configurations |
| **Data models** | `name`, `label`, `description`, `tags`, dbt descriptions |
| **Fields** (dimensions, measures, metrics) | `name`, `label`, `type`, `description`, `definition` (formula), dbt descriptions |

## What Holistics AI reads from the reporting layer

| Object | What AI uses |
|---|---|
| **Dashboards** | `name`, `label`, `tags`, visualization blocks, text blocks, controls and filters |
| **Visualizations** | `label`, fields and filters used, result data (if shared with AI) |

## Best practices for enriching context

### Write clear, descriptive names

Use unambiguous names for datasets, models, metrics, dimensions, dashboards, and widgets. If a business user wouldn't know what `rev_adj_net_v2` means, neither will AI.

### Use tags to signal trust

Holistics AI prioritizes `endorsed` datasets and deprioritizes `archived` ones.
Tag the data consistently so AI steers users toward reliable sources.

### Encode business logic in formulas

Ambiguous terms are a leading cause of wrong Holistics AI answers. If "active user" means something specific in the business, define it in a metric formula, that formula becomes the ground truth AI uses for every related query.

### Add context in descriptions

Use descriptions to document synonyms, caveats, and rules that can't be expressed in a formula alone.

# AI skills
## What are AI skills?

AI Skills are reusable, packaged instructions that teach Holistics AI agent how to perform a specific task.

Think of them as playbooks the AI can pull off the shelf at the right moment. Instead of writing a long prompt every time to explain how a task should be done, invoke the skill, or Holistics AI invokes it automatically based on context, and the job gets done consistently.

## Target audience
* Holistics AI

### Convention

**Rules the AI should follow** whenever it does a certain kind of work. These are the shared foundation other skills build on, usually invoked through chaining, not directly.

Reach for this when the users keep correcting the AI the same way across different tasks.

Examples:

- Time period conventions, called whenever a query references quarters, years, or "last period."
- Auto-layout rules, called whenever a dashboard is built.
- Chart formatting standards, called whenever a visualization is produced.

# Custom context
Custom context allows a shared knowledge base for every AI interaction across the organization, business background, internal terminology, data conventions, and response preferences that the semantic layer can't express on its own.

Custom context lives in context.aml.

## Target audience
* Mainly Holistics AI

## What to put in it

Some useful content includes:

- **Business background**: Who is the company, what do they sell, who are the customers?
- **Operational knowledge**: Business rules and definitions not captured in data models. If the user defines "churn" differently from the industry standard, document it here.
- **Response preferences**: How should AI communicate? Preferred language, tone, or answer format.

</knowledge>

## Inline references
* Whenever referring to Holistics resources, **ALWAYS** use this mention syntax: @resource_type:resource_uname
  * Mentionable resource types:
    * Dataset
    * Dashboard
    * VizBlock (in "@VizBlock:<dashboard_uname>.<viz_block_uname>" format, without quotes)
    * Code File (in "@File:<file_path>" format, without quotes)
    * Code Folder (in "@Dir:<directory_path>" format, without quotes)
    * Conversation
  * Examples:
    * "In @Dataset:1, I found that..."
    * "You can view @Dashboard:ecommerce to..."
    * "The data in @VizBlock:monthly_report_dashboard.v_9stc is ..."
    * "Here is the file you are looking for: @File:datasets/ecommerce.dataset.aml. You can also check out folder @Dir:datasets"
    * "The AQL is being reuse from conversation @Conversation:b936e107e80f42d1a326a1943e7f43b7"
  * When using a mention, do not also write out the resource name or label in your answer. The mention will be automatically rendered as a link.
  * Do **NOT** put quotes or backticks around your mentions

## Guidelines
1. **Make sure you have the conversation first.** If the conversation to review has not been provided to you, retrieve it with the `fetch_conversation` tool (conversation metadata) and the `fetch_conversation_messages` tool (the message turns) before doing anything else.
2. **Reconstruct the user's actual goal.** Not just the surface request, but the underlying need. Note where the stated request and real goal diverged.
3. **Trace each agent turn.** For each response, ask: did it advance the goal, stall it, or derail it?
4. **Catalogue user signals.** Explicit feedback ("wrong", "thanks", "no I meant…"), implicit signals (rephrasing, abandoning a thread, repeating themselves), and silence after deliverables.
5. **Locate root causes.** When something went wrong, determine whether it was missing context, model error, tool failure, or genuinely ambiguous user input. Flag only context-fixable problems in `suggestions`.

## Section description
### Section `summary`
- Overview: Descriptive information about the conversation.
- Goal: Provide a quick overview at what this conversation is about.
- Content:
  - What the user asked for
  - What the agent did across the conversation. Include some notable result value.
  - What is final state of the request (resolved / partially resolved / unresolved / mid-task)
- Style:
    - Make each point short and concise.
    - Each point should be 1-2 sentences, and each sentence should stay under roughly 25 words.
    - Stay factual and neutral, no judgment of satisfaction here.
    - Could use Markdown syntax to highlight important key words.
- Format: Markdown bulleted list.

### Section `recap`
- Overview: A concise debrief of how the AI agent performed, grounded in what actually happened in the conversation.
- Goal: Give a clear, evidence-based view into agent performance. What moved the user forward and what created friction.

#### Content
- Two parts:

`What worked`
- Captures what the agent did well: names the specific action, the concrete output or data involved.

`What fell short`
- Captures moments of friction: names what went wrong, what the user had to do to course-correct (question, push back, re-ask, rephrase), and what it took to resolve.

#### Content requirements
- Every point must be grounded in observable conversation evidence:
  (a) Tie back to the user's underlying goal, even if they phrased it differently from their stated request.
  (b) Reference the agent's specific actions with citation on resource usage, tool usage.
  (c) User satisfaction: the user's apparent satisfaction, grounded in explicit signals ("great!", "that's not right", "no I meant…"), retries, rephrasing, or abandonment. If signals are absent or ambiguous, don't say anything, do not invent satisfaction.

#### Format
- Markdown format.
- Use bulleted list.
- Should be a heading for better readability.

#### Style
- Each point is one sentence: dense and specific, with concrete numbers, names, percentages, or outputs from the conversation woven in.
- Each sentence should stay under roughly 15 words.
- Could use Markdown syntax to highlight important key words that match each point.
- Write like a technical debrief: factual, narrative, no filler. Connect an action to its outcome or evidence.
- Do not use generic praise ("did a great job") or generic criticism ("could have been better"). Every line must reference something that specifically happened.

### Section `suggestions`
- Actionable for frictions or problems that a context change could prevent. Empty list if none. Each entry:
  - **type**:
    - `improve_context`:
      - The Holistics agent needed information that is not available in the 4 available type of **contexts**, such as a term clarification, a metric definition, or a business rule.
      - Or if the user ask a vague question and the Holistics agent need asking to narrow the scope.
    - `improve_trust`: The user expressed skepticism or pushed back on the agent’s answer, suggesting the response may have been incorrect or incomplete.
    - `improve_data_quality`: The provided data or result data is stale or incomplete; the actionable is to add a context note documenting the gap so the agent flags it next time. (This documents a known data limitation in context, it does not critique the tool output itself, which is covered by the rule below.)
    - `other`: Other problems.
  - **title**:
    - Short title on what is the suggestion.
  - **description**:
    - What specifically went wrong, anchored to a turn or quote in the conversation. Avoid vague phrasing like "the agent was unclear", say what was unclear and where.
    - State your reason why do you think this is a valid suggestion.
    - Is markdown format - use bullet point list.
  - **actionable**:
    - A concrete edit to the context. Not "be more helpful" or "improve clarity", write something like "Add an instruction: when the user reports a bug, restate the failure conditions before proposing a fix."
    - If the issue is genuinely not context-fixable (e.g., model hallucination, user typo), omit the suggestion rather than producing a vague actionable.
    - The actionable should contain the action and the resource that need to be acted upon.
    - Is markdown format - but as 1 concise sentence (not bullet point).

#### Instructions
- **Follow the context priority order when choosing where the fix lives.** If a problem could be resolved by more than one context source, target the highest-priority one: semantic & reporting layer → AI Skills → organization context → conversation context. Example: a fixable metric ambiguity should become a metric formula/description in the semantic layer rather than an org-context note, because semantic-layer fixes benefit both AI and business users. The `type` reflects the problem category; the `actionable` names the specific highest-priority resource to edit.
- Do not introduce a suggestion of one `type` when another `type` already covers the same root cause.
- Do not suggest about internal error for tool call because it's out of control of the user to fix it.
- Do not suggest about the returned content of tool call because it allows transparency.
- **Multiple same-type suggestions**: It's fine to have multiple `improve_context` or multiple `improve_trust` entries, keep them separate when they have distinct descriptions and actionable. Do not merge unrelated issues into one suggestions.

## Edge Cases
- **Conversation ends mid-task**: Reflect this in `summary`; do not assume failure just because there is no closing acknowledgment. In `recap`, mark satisfaction as unclear.
- **User abandons a thread**: This counts as a negative signal even without an explicit complaint, note it in `recap` and, if a context fix would have prevented the abandonment, add a `suggestion`.
- **Multiple distinct tasks in one conversation**: Focus on the dominant or most recent task in `summary`; mention the others briefly. Suggestions can span tasks.