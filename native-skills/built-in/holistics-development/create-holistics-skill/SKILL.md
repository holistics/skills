---
name: create-holistics-skill
description: Write an AML AI Skill for Holistics AI. An AML AI Skill is an agent skill with AML programmatic features on-top. Use skills to extend, customize, or optimize Holistics AI agent capabilities by providing contextual knowledge and instructions.
---

## Type definition
```aml
Type SkillInvocation = 'auto' | 'manual'

@doc
  Use skills to extend, customize, or optimize Holistics AI agent capabilities by providing contextual knowledge and instructions.  
  NOTE: Skills can only be used by Agentic chat model, not Quick generation model.
;;
Type Skill (elem_name_as: 'name') {
  label (optional): String
  @doc
    What the skill does and when to use it.  
    Holistics AI uses this to decide when to invoke this skill.
  ;;
  description: String | Heredoc[Any] | Slot[String] | Slot[Heredoc[Any]]
  @doc
    Prevent AI agent and users from discovering or invoking this skill
  ;;
  disabled (default: false): Boolean | Slot[Boolean]
  @doc
    Configure the invocation mode for this skill
    * `'auto'` (default): AI agent automatically decides when to invoke this skill. End-users can still invoke manually on demand.
    * `'manual'`: AI agent won't invoke this skill on its own. End-users must manually invoke this skill.
  ;;
  invocation (default: 'auto'): SkillInvocation | Slot[SkillInvocation]
  @doc
    Allow end-users to switch the invocation mode for this skill
  ;;
  allow_switching_invocation (default: false): Boolean | Slot[Boolean]
  @doc
    Knowledge and instructions for the AI agent to learn and use when this skill is invoked
  ;;
  content: Heredoc[Any] | Slot[Heredoc[Any]]
}
```

## Basic examples

Auto-invoked skill that provides business context:
```aml
Skill company_glossary {
  description: "Use when the user asks about or references MRR, ARR, churn rate, or other company-specific metrics to ensure accurate definitions are applied"
  content: @md
    ## Metric Definitions
    - **MRR**: Monthly Recurring Revenue — sum of all active subscription amounts normalized to a monthly value
    - **ARR**: Annual Recurring Revenue — MRR × 12
    - **Churn Rate**: percentage of customers who cancelled in a given period
  ;;
}
```

Manually invoked skill for on-demand tasks:
```aml
Skill executive_summary {
  description: "Generates a concise executive summary from the current query results"
  invocation: 'manual'
  content: @md
    Generate a concise executive summary from the current query results.
    Focus on key trends, anomalies, and actionable insights.
    Use clear, non-technical language suitable for C-level stakeholders.
  ;;
}
```

Programmatically configured skill:
```aml
Skill query_guidelines {
  description: "Enforces query best practices and performance guidelines for this workspace"
  allow_switching_invocation: H.current_user.h_role != 'viewer'
  content: @md
    Always follow these guidelines when writing queries:
    - Filter on partition columns to reduce scan cost
    - Avoid SELECT * in production queries
    - Add a LIMIT clause when exploring large tables

    Refer to @Skill:company_glossary for metric definitions.
  ;;
}
```

## Constraints
* Skills **must** be placed under `settings/ai/` for Holistics AI to discover and use.
* Skills are only available to the Agentic chat model, not the Quick generation model.

## Best practice
* Place new Skill at `settings/ai/skills/<skill_name>.skill.aml`

## Conversions
### From Claude Skills
| disable-model-invocation | user-invocable | AML Skill |
|--------------------------|----------------|-----------|
| false *(default)* | false | `invocation: auto` |
| false *(default)* | true *(default)* | `invocation: auto` |
| true | true *(default)* | `invocation: manual` |
| true | false | `disabled: true`, `invocation: manual` |

### From Codex Skills
| allow_implicit_invocation | AML Skill |
|---------------------------|-----------|
| true *(default)* | `invocation: auto` |
| false | `invocation: manual` |

