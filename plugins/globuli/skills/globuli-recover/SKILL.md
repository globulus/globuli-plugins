---
name: globuli-recover
description: Use when Globuli is not doing what it should, for example the daemon is down or will not start, nothing moves, an agent keeps failing, a usage limit, the canary gate shut after a CLI update, a low disk, or a stack that will not come up.
---

# When Globuli is not doing what it should

Find the cause before changing anything: `globuli_brief` (the daemon and its supervisor,
pauses, the canary gate, free disk), then `globuli_why` with the ID of what is stuck (a
work item, an escalation, a notes PR, a planning session, a round, or `release`).
`globuli_queue` gives the jobs and what holds each, every pause, the load and the stack
runs waiting on it; `globuli_alerts` the alerts in full; `globuli_release` the release
check with what fails. On the
command line, `globuli` on the PATH (in a source checkout of Globuli,
`source tools/maintainer/env.sh` puts it there): `globuli brief --project $GLOBULI_PROJECT`,
`globuli status --project $GLOBULI_PROJECT` and `tail -30 <state root>/logs/daemon.log`
(`~/.globuli` without another). What acts below is the CLI: the maintainer tools are off.
From an install (D-593), `globuli-change` and `globuli-postmortem` below are the source
checkout's skills: a defect of Globuli you find goes on record as an observation
(`globuli observe add`, globuli-operate) and to the maintainer, and its change is his.

## Check in this order

1. Is the daemon running? `Daemon: not running`, or no answer at `http://127.0.0.1:4747/`.
   The brief's `alive, not ticking` is a live process after a sleep or in a long tick
   (D-281): wait for its next tick unless the brief lists it under "needs the maintainer".
2. Is it held on purpose? Under "Pauses": `all` (`globuli pause`), `cli:claude` (a usage
   limit), `intake` (the nightly, from 01:45). Or the daemon is draining for a reload.
3. Is the canary gate shut? `claude agents are stopped: claude is now …`.
4. Is the disk under its floor? The `disk:` line, a `low-disk` alert.
5. Does it wait for a person? An escalation, a question, `/approve-plan`, a notes PR.
6. Does it wait for the machine? Stack runs wait for the load and for a stack slot.
7. Is one item stuck, or one agent failing again and again?

## The daemon is down, or will not start

- The supervisor starts the daemon again only after a reload; any other exit ends
  both, and the last lines of the log say why. `Error: ENOSPC` is a full disk (below).
- **A start the daemon refuses** ends it with exit 78 and the log line `globuli daemon:
  not starting (<reason>): …`; the supervisor posts one alert with the reason and the
  path, then ends too (D-238). A crash once the loop runs alerts nobody. Put right what
  the line names: for the project's configuration (D-217) `globuli validate --project
  $GLOBULI_PROJECT --daemon` says what would be loaded and why not (a link in the path,
  a damaged stored copy, a copy under another path).
- Start it, once `ps -ax | grep "globuli.js daemon"` shows none running:
  `globuli daemon start --project $GLOBULI_PROJECT` in the background (it never returns
  while the daemon runs; it gives the daemon the roots it finds, and its log is
  `<state root>/logs/daemon.log`).
  The store keeps all state. Always supervised: only then does a pull load by itself.
- A file on the product's `main` that fails its checks stops nothing: the daemon keeps
  the last good copy and alerts once. A defect in new Globuli code is mended or
  reverted by a PR on the train (`globuli-change`), never in the main checkout.

## Nothing moves

- **Paused.** Resuming everything is the maintainer's word (`globuli-operate`).
- **A reload.** A hand-over takes seconds. A predecessor that hangs is stopped by the
  new process after ten minutes (D-191): wait, signal nothing.
- **`idle-slot`, `dependency-cycle`.** The alert says why each waiting item cannot
  start. A cycle: mend the `Depends on` row of one of its plans on its branch (D-126).
- **`stuck`** (a working state for three hours, nothing running or scheduled):
  `globuli advance <WI> --project $GLOBULI_PROJECT`. **`long-run`:** let it finish
  unless it plainly hangs; stopping a run is for the maintainer to decide.
- **A planning session** that waits, is blocked on questions nobody will answer, or
  was left running with no job: `globuli plan --cancel <session> --project
  $GLOBULI_PROJECT` (D-226). Its question files stay open in the knowledge repo: set
  each to `status: obsolete` in a notes PR.
- **A ready requirement nothing plans** is reported once, in an `escalation` alert:
  `globuli plan <requirement>… --project $GLOBULI_PROJECT`.
- **A red release check** plans its own fix (D-175): act only when one could not run.
  **A release check that never starts:** the build (D-300, D-357, D-374) and the critical
  path (D-269) hold it at most `release_check.max_unchecked_hours` (4) after the first
  merge it waits for; then it starts with a `release-check-failed` alert that names
  what held it (D-571). Still waiting past that: a round's testers, another check under
  way, or a pause of its CLI (the check is an agent's run): `globuli_why`.
  **No release PR, no acceptance round:** `globuli-acceptance`.

## An agent keeps failing

- Read the run: `globuli_run` (`id`, `report: true`), or `~/.globuli/runs/<RUN-id>/`:
  `run.json`, `report.md`, and for "why was X refused" `launch/` first.
- Much is retried by itself and not counted: a start that failed (workspace, Docker
  slot, browser, sandbox, CLI), a network error, a GitHub 5xx, a git lock. An `error`
  or a crash is retried once after five minutes; two timeouts on a step escalate.
- A commit-path violation: the agent wrote outside its plan's `## Files` table. If the
  file belongs to the change, amend the plan on the item's branch, then answer; a
  cause in the product (a real bug, a wrong test) is answered too (`globuli-operate`).
- The same failure on several items, or a refusal the role should allow: a defect in
  Globuli. Facts first, then `globuli-change`. Do not answer around it.

## A local Ollama model fails (D-544)

An agent on `ollama/<name>` runs against the Ollama server on the maintainer's machine.
Its run's `exit_detail` and doctor's `ollama` lines (`globuli doctor --project
$GLOBULI_PROJECT`, or `globuli validate --project $GLOBULI_PROJECT --daemon`) say what
is wrong; each line ends with its fix. Everything below is the maintainer's to do on
his machine: tell him the exact command, then run doctor again.

- **`ollama-down`, or "Ollama isn't running"**: start the Ollama app, or `ollama serve`.
- **`ollama-no-model`, or "<name> is not pulled"**: `ollama pull <name>`.
- **Too short a context** ("runs with N tokens of context, under min_context"): restart
  the server with `OLLAMA_CONTEXT_LENGTH=64000 ollama serve`, or for the app
  `launchctl setenv OLLAMA_CONTEXT_LENGTH 64000` and restart it. "Not loaded" is only a
  warning: `ollama run <name> /bye` loads it, and doctor can then read its context.
- **Too old** (before 0.14.0 it has no Anthropic API; before 0.40.9 a warning): update
  Ollama from https://ollama.com/download or `brew upgrade ollama`.
- **No tools, or too short a context of its own**: the model can't serve an agent. Name
  another model (`globuli-new-project`, "Local models").
- **A cloud model refused** (`…:cloud`, `…-cloud`): it sends the code to ollama.com.
  Name a local model; `model_providers.ollama.allow_cloud: true` is the maintainer's
  decision, and a `globuli-change`.

## A usage limit

Every agent on that CLI pauses until the reset time in the message, with an alert as it
starts and again after two hours. It is no failure and ends by itself: nothing to do.
The limit is the subscription of the item the brief's "agents sign in with" line names
(D-508), not this session's. Once the maintainer says the limit was raised,
`globuli resume --cli claude --project $GLOBULI_PROJECT` continues what the pause held.
To go on at once on another subscription the maintainer has stored as a Keychain item:
`globuli account --project <file> --state-root <dir> --worktrees-root <dir> --use
globuli.<item>` (D-423), which also ends the pause; runs the limit cut off
resume their sessions under it. The steps are in globuli-operate, "Two daemons, two
subscriptions".
Codex (D-541) runs on an OpenAI API key, so its limit is that key's quota or rate
limit: `globuli resume --cli codex …` once the maintainer says it was raised.
`globuli account` doesn't cover Codex; another key is a config PR (`accounts.codex`).

## The canary gate is shut after a CLI update

Agents run only on the CLI version the last canary passed with
(`~/.globuli/canary/status.json`), and Claude Code updates `claude` on PATH by itself.

1. `globuli daemon start` gives the daemon the tested version's binary while it is
   still installed (or the one in `--claude-bin`, `GLOBULI_CLAUDE_BIN`). A daemon
   started before the update needs its supervisor started again: only when nothing
   runs, `kill -TERM <supervisor pid>` (the line `globuli daemon start` printed names
   it), wait for it to end, then `globuli daemon start` again.
2. For the new version: `globuli canary --precheck --cli claude --claude-bin <path>`
   launches every agent with nothing planted (minutes; no approval, not a canary pass).
   Mend what it finds, then ask the maintainer, with a mention, for the real
   canary (`globuli canary --run --i-have-approval`, every Claude and Cursor app
   closed): theirs to approve, as is a CLI upgrade. A clean pre-check opens no gate.
3. Codex (D-541): it doesn't update itself; the maintainer installs or upgrades it
   (`npm install -g @openai/codex`, or `globuli upgrade-cli`). The gate keeps Codex's
   agents stopped until a canary has run Codex: `codex` on PATH or `--codex-bin`, and
   the pre-check with `--cli codex`. Codex can't enforce `access.shell` (its rules only
   forbid), so an agent without a shell, such as the supervisor, is refused on it:
   `validate` and the launch say `cannot run on codex`. Leave that agent on its CLI.

## The disk is low

A `low-disk` alert under 50 GB free; under 25 GB no agent run starts until 45 GB are
free again. Globuli removes its own leftovers by itself; `globuli cleanup --dry-run
--project $GLOBULI_PROJECT` lists what it can still remove, and without `--dry-run`
removes it (a snapshot first when a post-mortem is due, `globuli-postmortem`). What
fills the disk by then is something else (Docker's images and volumes, other programs):
the maintainer's to free. Never delete under `~/.globuli/runs` or the worktrees by hand.

## A stack will not come up

- **An acceptance stack.** The alert names the command, how it ended and the log
  (`~/.globuli/acceptance/<project>/<kind>-stack.log`). The cause is in the log; paste
  none of it anywhere.
- **A checkout that "was not moved"** holds a file the new head would overwrite. One
  that may go is removed by hand, on the maintainer's word, and the round started again.
  The stack's secrets file may not: the release must stop tracking it instead.
- **A stack by hand on the same ports:** `globuli stack status`, then `globuli stack down`.
- **An agent's stack** (Feature QA, integration-e2e) waits for the load, up to 20
  minutes, then runs with a `machine-load` alert. Look at what else loads the machine
  and whether Docker answers (`docker info`).
- **The preview:** `globuli preview --project $GLOBULI_PROJECT` builds it again.

## Needs the maintainer

Resuming everything; accounts, limits and credentials; the real canary and CLI
upgrades; freeing disk that is not Globuli's; removing a file under `~/.globuli` or
`/Users/Shared/Globuli`; stopping a running agent; a merge on the product's `main`.
Tell them in Slack with a mention and the exact action (`globuli-operate`). Afterwards
`globuli note add "<text>"`; a command or check that was missing is a `globuli-change`.
