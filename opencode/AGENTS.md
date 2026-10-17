# Global Rules

These are my personal defaults. When a project's own instructions (AGENTS.md, CLAUDE.md or its skills) say something different, follow the project.

## Pull Requests
- Always create pull requests in draft mode. This applies only when creating them: never move a PR I marked as ready back to draft.
- In the description, put demo captures one below the other under **Before** and **After** labels, never side by side in a table.
- Before editing a published PR description, read the current one from GitHub: I add images and videos by hand that local drafts don't have.

## Demo Videos
- Record demos in real time with Playwright's `recordVideo`. Use the same script and data for **Before** and **After**, so the two differ only by the change.
- Make each video clear on its own: show the cursor, add a short caption for every step over an empty part of the screen, and highlight what the caption talks about. `~/dotfiles/opencode/demo-video-overlay.cjs` does all three.
- Start once the page has loaded, trimming the loading, and end on proof that lasts, such as reopening the record to show what was stored.
- Use real actions only: never abort or fake a request to provoke an error.
- Re-record the **After** video whenever the code it shows changes, and restore any data the demo changed.

## Git Workflow
- Never commit directly to the main branch; work on a feature branch.
- Read-only git commands (status, diff, log, show, fetch) need no confirmation.
- For the task I asked you to do, you may create its branch, commit, push it and open its draft PR without asking.
- Ask before anything that rewrites history or touches work that isn't yours: rebase, merge, reset, deleting a branch whose PR isn't merged, or force-pushing a branch that isn't the one for the current task.
- Once one of my PRs is merged, you may clean up what was set up for it without asking: its branch (locally and on the remote), the worktree or slot it used, and the databases, containers and test data created for it.
- Never use `git stash`: the stash is shared across worktrees and holds my WIP. Set work aside with a patch file (`git diff > file.patch`).
- Keep each PR to a single commit: fold follow-ups into it (amend + `--force-with-lease`). Once the PR has review comments, address them in a new commit instead.
- Prefer small, focused pull requests. If a change would be large, propose splitting it into multiple PRs.

## Commit Messages
- Use high-level, product-oriented commit messages that describe the user problem and solution.
- Avoid overly technical wording.
- Write commit messages that could also serve as a PR description.
- Do not use any fixed structure or labels like WHAT/WHY/WHERE; write natural prose.
- Do not add a `Co-Authored-By` trailer (or any other attribution) for the agent you are running as, unless I explicitly ask for it.

## General Behavior
- Reply in the language I write in. Code, code comments, commits, PRs and tickets go in English.
- Keep changes minimal and avoid refactors unless explicitly requested.
- Do not reformat code that is not being modified to avoid noise in PRs.
- Follow existing code patterns and styles instead of introducing new ones.
- Before adding a new table, model, resource or abstraction, check whether an existing pattern already covers it. If not, justify it or propose leaving it for a later PR.
- Write code that a human can understand without comments. Keep comments short (one line) and as sparse as in the surrounding code; longer reasoning goes in the PR description.
- Do not modify shared tooling, or run scripts or backfills someone else owns, without asking. If something breaks locally, work around it locally and tell me.
- When errors occur, identify and explain the root cause before proposing a fix.
- Delete or overwrite freely what you created for the task and can get back: merged, pushed, or saved in a patch. Ask when it could lose something that isn't yours or can't be recovered, such as my uncommitted work or a database other environments use.
- Ask for clarification when requirements or UX are ambiguous or if a solution implies technical debt.
- Ask for confirmation before installing new dependencies if the problem can be solved with existing tools.
- For complex tasks involving multiple files, present a brief plan before writing code.

## Keeping the Mac awake
- When I ask for a task to run with caffeinate, run `cafe-on` when you start it and `cafe-off` when you finish it or stop to wait for me. Each agent has its own, so turning yours off never lets the Mac sleep under another agent.

## Testing & Quality
- Propose a test that reproduces the bug before fixing it whenever possible.
- Focus tests on user/product behavior rather than internal implementation details.

## Security (NON-NEGOTIABLE)
- Never include credentials, tokens, or PII in code or logs.
- Always validate and sanitize inputs.
- Verify authorization before executing critical actions.
- Ensure any new dependency is secure and necessary.
