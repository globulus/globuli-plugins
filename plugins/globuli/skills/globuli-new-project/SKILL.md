---
name: globuli-new-project
description: Use when a new project (a brownfield client's repos, or a new product) is to be brought up on Globuli, from a bare machine to its first open release with ready requirements, or when such a bring-up stopped halfway and is to be picked up again.
---

# Bringing a project up

For the maintainer's session. Globuli's step runner (D-420, `globuli docs brownfield
"15. The step runner"`) knows the steps, checks each against real state and does the ones it can.
You do the talking, the judging and the editing. The person decides.

Joining a project that already runs, on someone else's machine (another engineer on
the same project), is not this skill: it is `globuli setup` at a terminal, answering
`join` (D-632). That clones the project's repo, says what to ask the maintainer for,
keeps the hub's token and runs `globuli project join`, with no daemon, no service and
no agent token on the joiner's machine; then the globuli-operate skill shows where the
project stands.

## The loop

0. A bare machine: `globuli setup` says what it needs, in order (D-413). On a new
   person's Mac, `curl -fsSL https://theglobulus.com/install | sh` installs Globuli and
   starts `globuli setup` guided (D-624, D-625): it stores the Claude token and signs
   gh in through their own commands, so nobody pastes a credential into a chat or
   types `security` by hand; Slack's webhooks are optional (D-626). An install
   carries its own Node, so there is nothing to bootstrap; a source checkout of Globuli
   without its dependencies (no `globuli_*` tool because the MCP server died) is
   bootstrapped first, as `globuli steps` says at `machine.globuli` (D-511). In a source
   checkout, `source tools/maintainer/env.sh` puts `globuli` on the PATH. Then pass
   `--project`, `--state-root` and `--worktrees-root` to every command until the project
   is registered or `machine.driver` has written its roots, and start the daemon with
   `globuli daemon start`, which gives it those roots. For a rerun of a release,
   `github.copies` brings the client's copies to their upstream first. Ask the
   maintainer for their Slack member ID before the daemon starts (`notify.maintainer-id`,
   D-512): without it every alert that waits for them posts unmentioned. Without the
   alerts webhook the step is done: no Slack, nobody to mention (D-626).
1. Call `globuli_steps` with `next: true` (or `globuli steps next --project <file>`).
   Before `globuli.yaml` exists, use the CLI with the path it will have.
2. Read who acts:
   - **Globuli can do it.** Ask the person, then `globuli_step` (or `globuli steps do
     <id>`). A step that writes outside this machine (repos, invitations, branches,
     PRs) needs `yes: true` / `--yes`, which you add only after the person said yes.
   - **The session.** Do it with your own tools: draft `globuli.yaml` (`steps do
     project.file` writes `globuli.draft.yaml` by detection; merge it in and fill each
     `DRAFT(globuli)` line with the person), review an onboarding PR against the code,
     draft `standards/` from the client's guides.
   - **The person.** Say exactly what to do (the step's `manual` gives the command or
     the text to send the client) and wait. A secret is typed in their own terminal,
     never into this session. For a step nothing can observe (an agreement with the
     client), record their own answer: `globuli_step` with `inputs.answer` and
     `inputs.by`.
3. Check the step again (`globuli_steps` with `step: <id>`). Done: go on. Not done: say
   what is missing, from the check, not from memory.

## Rules

- **The session in the project's folder (an install, D-593).** One install serves every
  project of the machine. Each project is registered (`machine.registered`: `globuli
  project register`, or `globuli setup --yes`) with its own state and worktrees roots
  and Claude item (`machine.one-daemon`; globuli-operate, "Two daemons, two
  subscriptions"). Its driver session is opened in the project's own folder (its
  knowledge repo, where its `globuli.yaml` is), with the `globuli` plugin: the start hook
  says which project the folder drives, and the MCP server serves that project. A
  folder that drives none gets the command that registers it.
- **One checkout per project (a source checkout of Globuli).** A second project gets its
  own Globuli clone (`machine.globuli`), roots, Claude item and `.globuli.env`
  (`machine.driver`, D-510); its driver session is opened in that clone.
- **Agent CLIs and accounts.** Agents run on Claude by default; `overrides.models` can
  move one to Cursor or Codex (D-456, D-541). Each CLI signs in with its own Keychain
  item, named in `accounts`: `claude`, `cursor`, and `codex` (an OpenAI API key,
  `globuli.codex-api-key` by default). Codex enforces only the denied commands, never
  an agent's `access.shell` list, so an agent without a shell can't run on it; offer
  it to the person with that said. A CLI an agent is moved to needs `codex` (or
  `agent`) installed and a canary, both the maintainer's.

- **The check is the truth.** Never say a step is done that its check doesn't show.
- **Never answer for the person** on a `human` step: merges, the canary's approval,
  which requirements are ready, anything asked of the client. Prepare each with a
  summary and a suggested answer.
- **No secret** in a step's input, in the session, or in `<state root>/steps/`.
- The daemon never runs a step; the CLI runs in the maintainer's shell, on their `gh`
  login, and the bot's actions use its token from the Keychain.
- **No bot account is needed (D-627).** Without the item `globuli.github-bot-token`,
  Globuli acts as the person's own `gh` login (`gh auth login --web`): `github.bot` is
  done when that login can push to every repo, its own repos usually. A second account
  for the bot stays the alternative, for a person who wants Globuli's comments apart.
- **Other engineers (D-631, D-643).** `github.maintainer` is the one Globuli asks and mentions;
  another engineer gets one role in `github.roles`: `operators: [<login>, …]` do everything
  (as `github.maintainers` do), `builders: […]` answer and pause or resume one item,
  `viewers: […]` read. They are not paged. Put `roles` into `main` only once every machine
  of the project runs a Globuli with D-643: an older one refuses the key.

## Local models (D-544)

Agents run on Claude by default. A project may put an agent on a model a local Ollama
serves: `ollama/<name>` in `overrides.models` (`coder: ollama/qwen3-coder:30b`). It runs
on Claude Code against the server, with no Claude token and nothing sent to Anthropic.
To try one against Claude first, use the coder-model trial (D-349,
`work_item.coder_trial.model` in `overrides.limits`), not a switch for good.

- On a 64 GB Mac: `qwen3-coder:30b` (19 GB), `gpt-oss:20b` (14 GB), `llama3.3:70b`
  (43 GB, slow). `gpt-oss:120b` and Kimi K2 don't fit.
- Cloud models (`…:cloud`, `…-cloud`, Kimi among them) send the code to ollama.com and
  are refused unless `model_providers.ollama.allow_cloud` is true: the maintainer's
  decision, and the client's.
- Before the first run, the maintainer installs Ollama, pulls the model and sets the
  server's context (`OLLAMA_CONTEXT_LENGTH=64000`); `globuli doctor` checks all three.
  The setup is in `globuli docs orchestrator "Model providers: a local Ollama"`.

## Evidence retention (D-547)

- A regulated client: `compliance.retention` in `globuli.yaml` keeps the evidence of the
  runs behind a released item, and with a `store` archives it (S3, an rclone remote, a
  mounted folder). Which store, and the retention period, are the client's decision.
- An rclone remote is the maintainer's to make (`rclone config`, its OAuth sign-in); an
  S3 bucket's keys go into two Keychain items the file names. Then `globuli validate
  --daemon` and `globuli doctor`: both refuse a missing rclone, remote or folder.

## Regulated work (D-550, D-551, D-553)

For a medical-device client, ask the person which parts to turn on; each is a key of
`compliance:` in `globuli.yaml` (`globuli docs orchestrator "Regulated work behind compliance"`).

- `safety`: the IEC 62304 class of each path (`classes`, `default`), and
  `human_reviewers` when class C is in use. The classes are the client's decision:
  ask, never guess. `coverage_command` and `coverage_report` only where the repo writes
  lcov or Cobertura.
- `risk`: the risk file's folder in the knowledge repo (`risk/` by default), started
  empty; Stage 1 fills it from the notes.
- `impact_analysis: true`: every plan gets a `## Impact` section.
- `globuli validate` after each; `globuli risk check` once requirements are ready.

## After bring-up

When every step is done, `globuli steps` says so. From there `globuli-operate` takes
over: `globuli_brief` and `globuli_attention`.
