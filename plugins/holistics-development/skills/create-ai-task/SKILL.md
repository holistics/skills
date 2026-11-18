---
name: create-ai-task
label: Create AI task
description: |-
  Use when the user wants to create or update an AI Task: recurring AI work with a clear definition of done, usually run on a schedule and delivered by Email or Slack. Examples: email a weekly sales summary to the C-levels at 8am every Monday; alert #sales on Slack when a region's revenue drops 20% or more; every Friday at 5pm, summarize where users' questions this week hit gaps in the semantic layer. Do not use for one-off questions; answer those directly.
---
# Overview

An AI Task is AI work that runs unattended: on a schedule, with no one around to answer questions. Each run is checked against the task's acceptance criteria. Creating a task usually produces two things:

1. An `AiTask` in `settings/ai/tasks/<task_name>.ai_task.aml`
2. One or more `AiSchedule` entries in `schedules.aml` (skip this only if the user wants a task they run on demand)

# Workflow

1. **Clarify.** Before you write any file, ask about anything that is missing, vague, or contradictory. Never guess, because a task that runs unattended cannot ask later.
   - **What:** the dataset or dashboard, metrics, dimensions, filters, and time window
   - **When** (optional): the schedule, and for alerts, the exact condition (see Alert conditions)
   - **Where** (optional): the email addresses or Slack channels to send results to, plus any attachments
   - **Who:** the `run_as` user whose data access each run uses (see Choosing run_as). Always confirm it.

   If the user mentions neither When nor Where, ask once whether they want either. Most tasks have both.

   See How to ask, below.
2. **Write the task** (see Anatomy, Brief, and Acceptance criteria below).
3. **Write the schedule(s)**, if the task has any (see Schedule).
4. **Hand off** (see After writing).

## How to ask

- Ask every question with `ask_user`, never in plain text.
- Before asking, quickly look up only what you need to offer real options (e.g. which datasets have the metric).
- Offer 2–3 options with exact values and a one-line reason each, plus one for the user's own value. If one option clearly fits, put it first.
- Batch related questions, but keep every option complete.
- **Never add anything silently.** Thresholds, filters, minimum volumes, statistical methods, a choice between similar metrics, limits like "top 5", and calls to other AI skills all need the user's confirmation first.

# Anatomy of an AiTask

Consider every property below when creating a task. Together they decide whether the task is useful to the people who run it.

| Property | Notes |
|---|---|
| `name` | The identifier after `AiTask`. It must match the file name, e.g. `weekly_sales_report`. |
| `label` | The display name. |
| `description` | One or two sentences on what the task does. |
| `brief` | `@md` block. The instructions every run follows. This is the most important property. |
| `acceptance_criteria` | `@md` block. The checks a run must pass to count as successful. |
| `timeout_minutes` | Use 15 by default. Raise it (e.g. to 30) for multi-step analysis. |
| `disabled` | Leave it out to enable the task for everyone. `true` disables it for everyone. A user-attribute condition limits it to specific users. |

# Writing the brief

The brief is the only thing the AI has at run time. A good brief is:

- **Specific:** It names the exact objects to use: the dataset (e.g. `ecommerce`), metrics (`revenue`, `aov`), dimensions, filters, the dashboard or block, time window (e.g. "last complete Monday–Sunday week", not "recently"), and any AI skill the user agreed to call (`/skill_name`).
- **Sequential:** numbered steps, one action each.
- **Scoped:** one job per task. If parts of the request can run independently, or need different schedules, create separate tasks.
- **Free of scheduling:** "Every Monday at 8am" belongs in the schedule's `cron`, not in the brief.

## Delivery

Add delivery only when the user wants results sent somewhere. Make it the last numbered step, so everything is computed before anything is sent. Spell out:

- **Where:** each email address or Slack channel, written out exactly. To email each run to its own `run_as` user, write `${H.current_user.h_email}` as the email address (see Choosing run_as).
- **What:** the content, plus any attachments. A visualization or a dashboard can be attached as PDF, PNG, or CSV. Name the exact viz or dashboard and the format.
- **When:** one of these two patterns:
  - **Every run:** send the result each time the task runs.
  - **Condition (alert):** send only when the condition is met (see Alert conditions). State the metric, the comparison, and the threshold, and add: "Otherwise, send nothing, and state in the run output that the condition was not met, with the values checked." The run output keeps every run traceable, even when nothing is sent.

## Alert conditions

Confirm each part of the condition with the user before writing:

1. **Metric:** which metric the condition checks. If several could fit, offer them with the trade-off, e.g. `total_cancelled_orders` (a count, which rises with order volume) vs. `cancelled_order_ratio` (a rate, which isn't affected by volume).
2. **Comparison and threshold:** compared with what (e.g. the same weekday last week), and the exact threshold. Offer options with reasons.
3. **Noise:** evaluate whether the condition would fire on noise, and raise it with the user. Common causes: small bases (from 2 to 3 cancellations is a 50% increase), segments with little data, and days with incomplete data. Propose a fix with exact values, such as a minimum base ("ignore countries with under $1,000 revenue a week earlier"), and confirm it.

# Writing acceptance criteria

Acceptance criteria protect quality. They should not stop users from getting a useful result. Include only what is critical to the task, and make every criterion something a reader can check against the output. Usually that means:

- **Content:** the required numbers or sections are present and cover the right time window.
- **Delivery** (if the task has any): the result was sent to every destination with the requested attachments.

Avoid subjective criteria like "insightful" or "well written", and don't restate every step of the brief.

# Schedule

Append new entries to the `schedules` list in `schedules.aml`. Never replace the existing entries unless the user says so.

~~~
AiSchedule {
  cron: '0 8 * * 1'   // every Monday at 08:00, workspace timezone
  run_as: 'analyst@company.com'
  targets: [weekly_sales_report]
}
~~~

- `cron`: when the task runs. Times use the workspace timezone. For alerts, choose a cadence that matches how often the data changes, e.g. daily for a daily metric.
- `run_as`: the user whose permissions the run uses (see Choosing run_as). If this user is deactivated, runs fail.
- `targets`: the task to run. Each schedule targets **one task**, so that changing one task's timing never moves another task. One task can have several schedules, e.g. one per `run_as` user.

Scheduled tasks need Admin approval before they run. Tell the user this.

## Choosing run_as

The AI sees only what the `run_as` user can see, and recipients receive whatever the run produces. Choose it based on who receives the result, and always confirm it with the user:

- **No delivery, or delivery only to the user creating the task:** suggest the creating user as the first option.
- **Each recipient should see only their own data** (e.g. a sales report for the APAC, Americas, and EU managers, each limited to their region): write **one task** whose delivery step emails `${H.current_user.h_email}`, then add **one schedule per recipient**, with that recipient as `run_as`. Each run then uses that recipient's data permissions and emails that recipient.
- **Delivery to a group, or to someone other than the creating user:** a Slack channel, a mailing list, or several addresses all count as a group. Ask which `run_as` to use, with the creating user as the first option, and explain the risk. Recipients may not have the same data permissions as the `run_as` user, so they could receive data they aren't allowed to see, or a report missing data they need. Offer two options: one `run_as` whose access suits every recipient, or one schedule per recipient as above.

# After writing

If a sub-agent writes the files, pass it every requirement from this skill that applies, including the user's answers and the checklist below.

Before you hand off, open each file you wrote and check:

- [ ] The task has `label`, `description`, `brief`, `acceptance_criteria`, and `timeout_minutes`.
- [ ] The brief's steps are numbered, and delivery is the last step.
- [ ] Every threshold, limit, method, filter, and skill call in the brief was confirmed by the user.
- [ ] For alerts, the brief and criteria say what happens when the condition is not met.
- [ ] Each schedule targets one task, and its `run_as` was confirmed by the user.

Fix anything that fails, then give the user a short summary: what the task does, when it runs, who receives what, and the `run_as` user of each schedule. Then tell them how to test it:

- **Development:** commit, then run `/<task_name>` in the AI chat.
- **Reporting (after publishing):** click **Run** on the AI Tasks page, or run `/<task_name>` in Ask AI.

Test runs really do send the emails and Slack messages. Suggest pointing delivery at the user's own email or a test channel while testing, then switching to the real recipients. A test run uses the permissions of whoever runs it, so `${H.current_user.h_email}` sends to the tester.

Remind them that the schedule only starts after Admin approval.
