---
name: para-help
description: Display the PARA-Programming quick-reference guide with all 11 skills and the Research→Plan→Review→Execute→Review→Summarize→Archive workflow.
model: haiku
effort: low
---

Display the PARA-Programming quick-reference guide.

## Usage

```
para-help
```

## Implementation

Determine how to render user-facing skill requests before displaying the reference:

1. Render a client selector only when the host is explicit in runtime/system context or the user names the client.
2. Do not infer the host from ~/.agents/skills or another shared discovery path.
3. For an unknown client, OpenCode, or Gemini CLI, use exact-name natural language such as: Use the `para-plan` skill to plan `<task>`.
4. Treat the forms below as presentation only. The canonical request remains `para-<skill> [arguments]`.

<!-- para-client-invocation-map:start -->
| Client | User-facing form |
|---|---|
| OpenAI Codex | `$para-<skill> [arguments]` |
| Cursor | `/para-<skill> [arguments]` |
| Pi, skill commands enabled | `/skill:para-<skill> [arguments]` |
| Pi, skill commands disabled | `natural-language` — `Use the para-<skill> skill <intent-and-arguments>.` |
| OpenCode | `natural-language` — `Use the para-<skill> skill <intent-and-arguments>.` |
| Gemini CLI | `natural-language` — `Use the para-<skill> skill <intent-and-arguments>.` |
| Unknown client | `natural-language` — `Use the para-<skill> skill <intent-and-arguments>.` |
<!-- para-client-invocation-map:end -->

Display the reference below. Keep the skill identifiers canonical. In the Typical Flow, render each request using the selected client form; when using natural language, include both the exact skill name and its intent/arguments.

---

# PARA-Programming Quick Reference

**Workflow:** Research → Plan → Review → Execute → Review → Summarize → Archive

Detailed workflow: Research → Plan → Review Plan → Execute → Review PR → Summarize → Archive

## When to Use PARA

**Use PARA** if the task results in git changes: features, bug fixes, refactoring, config, migrations, tests, documentation edits, or complex debugging.

**Skip PARA** if the task is read-only or informational: questions, navigation, explanations, or state inspection.

## Skills

| Skill | Purpose |
|-------|---------|
| `para-init` | Initialize PARA structure in a project |
| `para-research <task>` | Deep codebase research before planning |
| `para-plan <task>` | Create a planning document through collaboration |
| `para-review --plan\|--pr` | Staff+ review loop for plans and PRs |
| `para-execute` | Create worktree, extract todos, start execution |
| `para-workflow` | Orchestrate execute → PR → review → summarize → archive |
| `para-summarize` | Generate post-work summary |
| `para-archive` | Archive context and start fresh |
| `para-status` | Check current workflow state |
| `para-check` | Decide whether a request needs PARA |
| `para-help` | Show this reference |

## Typical Flow

```
para-research Add user authentication
para-plan Add user authentication
para-review --plan
para-workflow           # or manually:
  para-execute          #   -> Creates worktree, implements with TDD
  para-review --pr      #   -> Staff+ review loop
  para-summarize        #   -> Generate summary
  para-archive          #   -> Clean up worktree
```

## File Structure

```
context/
├── context.md       # Active session context
├── plans/           # YYYY-MM-DD-task-name.md
├── summaries/       # YYYY-MM-DD-task-name-summary.md
├── archives/        # YYYY-MM-DD-context.md
├── data/            # Input/output files, research docs
└── servers/         # MCP tool wrappers
```

## Tips

- Use the `para-status` skill to see where you are in the workflow
- Use the `para-check` skill if unsure whether a task needs PARA
- Full methodology details are in `../../docs/METHODOLOGY.md`
