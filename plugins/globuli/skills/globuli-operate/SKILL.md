---
name: globuli-operate
description: Use when the session is told to use Globuli, or to run it for the maintainer, that is to watch the daemon, see where things stand, deal with what waits (an escalation, a question, an approval, an alert, a report to publish), watch the agents' usage, pause or resume, and keep the build moving.
---

# Operating Globuli

**Any LLM's session** (D-421): Claude Code, Cursor, Codex or another; `AGENTS.md` sends
them here. Everything below is a command any of them can run; the MCP tools are a
shorter way where the CLI has them. Told "use Globuli" and what to do: start at the
loop, do that, and keep the loop going until it is done.

**Told only "use Globuli", or to show where a project stands (D-638):** steps 1 and 2
of the loop, then say where it stands and what waits, and ask what to do. Change
nothing until the person says what: no answer, PR comment, merge, conflict resolved,
plan, pause, resume, canary or note. Their word on an item, or "handle what waits", is
the go-ahead; from then the loop runs for it. On 2026-11-09 a contributor's first
session, opened by setup with "Use Globuli.", posted an `/answer` on a notes PR, tried
to answer an escalation and resolved a merge conflict before the person had said a word.

For the session that runs Globuli for the maintainer. A subagent, or a session asked
only to change Globuli, does not operate it: in Globuli's source checkout, `CLAUDE.md`'s
hard rules stand for those (the maintainer's checkout only).
Globuli's MCP server gives thirteen read tools, which change nothing. Its maintainer tools
(`globuli_answer`, `globuli_pause`, `globuli_resume`, `globuli_plan`, `globuli_acceptance`,
`globuli_notify`, `globuli_approve`) are switched off, so **this session acts through the CLI**:
`globuli …` on the PATH. It finds the project and its roots by itself (D-592: `--project`,
`$GLOBULI_PROJECT`, the folder the session is in, the one registered project; `globuli
version` says which it found and from where). Each command below takes `--project
$GLOBULI_PROJECT` (`globuli note` needs none); another project's also `--state-root` and
`--worktrees-root`. In a source checkout of Globuli, `source tools/maintainer/env.sh` once
per shell puts `globuli` (the main checkout's code on Node 24) on the PATH.

From an install (D-593) the session is opened in the project's own folder (its knowledge
repo), with the `globuli` plugin: its start hook says which project the folder drives and
sets `$GLOBULI_PROJECT`, and its MCP server serves that project. The docs the skills cite
are `globuli docs <name> [<section>]` (`globuli docs` lists them), read from Globuli's own
root: nothing of the source tree is needed. `globuli-change` and `globuli-postmortem` are
skills of Globuli's source checkout: from an install, a defect of Globuli is an
observation (below), and changing Globuli is the maintainer's.

On a contributor's machine the project is joined (D-630, `globuli project join`): it runs
on the maintainer's machine, and the read tools (`globuli_brief`, `globuli_attention`,
`globuli_item`, `globuli_why`, …) come through the hub, read-only. They act on nothing,
and no `globuli` command acts on a joined project from here: answers, pauses, plans and
approvals are the maintainer's, on the machine that runs it. A tool that says the hub
refused the token (401) or the machine did not answer (503, 504): tell the person, who
asks the maintainer.

## The loop

0. Start watching: `globuli watch --follow --project $GLOBULI_PROJECT` under a tool that
   streams a command's lines (Claude Code's Monitor), or, without one, `globuli watch
   --project $GLOBULI_PROJECT` every few minutes. Each line is something to act on
   (`## Watching`). The status page is at http://127.0.0.1:4747/ at all times, even
   while the daemon is down (D-421).
1. `globuli_brief`: where things stand and what needs doing. Every session starts here.
2. `globuli_attention`: everything that waits for the maintainer, each with what was
   asked, its options and the exact command for each (`limit`, `offset` to page).
3. Once told to (above), handle each item (below). First what holds a slot or the
   release's critical path.
   Read with the tools (list below), not with `sqlite3`, `gh api` or the run folders.
4. `globuli brief --mark --project $GLOBULI_PROJECT` once you have dealt with what it
   showed: the next brief lists the alerts since.
5. Leave what the next session must know and Globuli cannot derive (a decision and its
   reason, a promise, a thing to watch): `globuli note add "<text>" --link <ID>`, and
   `globuli note done <MN-…|SN-…>` for one that is settled. Never the state: the brief has it.
   On a shared store the note goes into the store and every machine's brief shows it;
   for another machine only, add `--for <machine>` (its name as `globuli machines` shows
   it): only that machine's brief shows it (D-717).

Without the tools: `globuli brief --project $GLOBULI_PROJECT` and `globuli status
--project $GLOBULI_PROJECT` say the same on the command line; `globuli note list`.

## Which tool reads what

| You need | Call |
|---|---|
| One work item: hold, waits, history, runs; its answers and the run that took each | `globuli_item` (`id`) |
| An item's plan header, `## Files` table and Stop-and-ask list from its branch | `globuli_item` (`id`, `plan: true`) |
| One run: verdict, findings, cost; the agent's report | `globuli_run` (`id`, `report: true`) |
| Why something does not move; which run took an answered escalation | `globuli_why` (`id`: WI, ESC, notes#N, plan-…, round, `release`) |
| The queue: pending and running jobs with due times and what holds a due one | `globuli_queue` (`kind` for one kind) |
| Pauses of every scope (`all`, `cli:<cli>`, `intake`) | `globuli_queue` |
| The machine load, the stack slots and the stack runs waiting on the load (D-193) | `globuli_queue` |
| The agents at work and when each should end; run durations by agent, for an ETA | `globuli_queue` (`since`: `2d`, `30d`; default a week) |
| The nightly: the last one, the next, how to skip one | `globuli_queue` |
| Alerts since a time, in full | `globuli_alerts` (`since`, `kind`, `item`; `after` to page) |
| The latest release check: failing tests, known and flaky ones, suspects | `globuli_release` (`release`) |
| One line per open item of the release, with what it waits for; the ETA | `globuli_release` |
| Stage 1 per notes PR: state, critic round, fix loop, runs | `globuli_notes` |
| A notes PR's critic findings in full, with the synthesizer's and the re-check's answer to each | `globuli_notes` (`id`: `notes#N`; `round` for one critic round) |
| What happened, by time | `globuli_events` (`item`, `since`, `all: true`) |

Without the tools, `globuli status` has the counts, the queue, the pauses and the load
in short. A read none of them gives is a change to Globuli (`globuli-change`), not a
`sqlite3` recipe kept here.

## Answering an escalation or a question

An item stops `escalated` (a failure, a limit) or `blocked` (a question). Read the findings
and the run's report first, and check a claim in the code or the data before writing it.

- Answer with `globuli answer <ESC|WI|notes-PR> --file <path> --project $GLOBULI_PROJECT`
  (or `--text "<text>"`): at once, and the PR gets the text. `/answer <text>` as the
  first line of a comment on the PR does the same at the next poll. The item resumes at
  the step that stopped. Examples by kind: `globuli docs answers` (one of them: `globuli docs answers <name>`).
- **A decision of the maintainer's on what an item builds** goes in with `/decide <text>` on
  its PR or `globuli decide <WI> --file <path> --project $GLOBULI_PROJECT` (D-757), not a
  notes PR first: the item is re-planned on it at once, and Globuli opens the notes PR itself,
  which doesn't hold the item. WI-0166's notes PR first took 85 minutes to its plan.
- **A plan fact goes into the plan:** an answer that settles one (a value, a rule, what a
  criterion means) is given with `--into-plan` (D-476), which commits it into the plan
  first, so the reviewers and Feature QA read it too. It writes into the plan of the item the
  escalation names. In a batch (`B-NNNN`, several items built on the leader's branch),
  that is the leader, which may not own the criterion. First read which item's
  `Covers` names the criterion (`globuli_item`). When it isn't the escalated item,
  commit the fact into that item's `specs/WI-NNNN/plan.md` on the batch's branch
  yourself (`docs(plan): …`), and answer naming the commit (D-679). On 2026-11-12
  ESC-0034's answer went into WI-0046's plan, but `FR-0073.AC-3` was WI-0080's, in
  the same batch B-0005. Feature QA failed it again twice (ESC-0035, ESC-0036) before
  the fact reached WI-0080's plan.
- **An answer reaches only the runs of the step the item continues with** (D-254), never
  a later reviewer or Feature QA, nor the coder's merge run that may come first (its
  own question's answer goes to it alone). Where no agent's step is next (`planned`,
  `plan-review`, `merging` with no conflicts) it reaches the next run. Ask only for
  what it may write (`access.write` in `agents/<name>/agent.yaml`): the coder cannot
  write `specs/` (the planner's) or `e2e/` (Feature QA's).
- **A plan change or a file outside the plan goes into the plan first (D-126).** The
  commit check reads only the plan's `## Files` table, so an approval given in the
  answer alone gets the coder's commits reverted and the item escalates again; and
  reviewers judge against the plan. The planner does not amend it for you: that path
  (D-234) is switched off. Read the plan's Files table first (`globuli_item`, `plan:
  true`). **For a coder's escalation that needs files, one command does all of it
  (D-275):** `globuli approve-files <WI> <ESC> --file <path>=<line>…
  [--shared <path>=<line>…] [--covers <criteria>] [--text "<more>"] --project
  $GLOBULI_PROJECT` (`--shared` for a contract or shared file; `--dry-run` first if in
  doubt). It writes the rows and the Stop-and-ask lines, commits as the bot, pushes and
  answers naming the commit; it refuses, changing nothing, what the plan checks would.
  For any other plan change, amend `specs/WI-NNNN/plan.md` on the item's branch, in a
  worktree of your own from the product checkout (after a fetch,
  `git -C ~/Documents/GitHub/IvERP/IvERP worktree add <dir> origin/<branch>`), never
  in `/Users/Shared/Globuli`: rows in `## Files` marked "(maintainer, ESC-NNNN)", a line
  under "Stop-and-ask items included" for a contract or shared change, and the header's
  `Covers` or `Depends on` if they change (the poll re-reads `Depends on` until coding
  starts and `Covers` until Feature QA starts, D-126, D-210). Commit as `docs(plan): …`
  (lowercase, at most 100 characters), `git push origin HEAD:<branch>`, then answer
  naming the commit.
- **A `release-broken` alert after a merge run (D-572)** says the coder merged the
  release in and the merge was pushed: the item goes on, and the failures it names
  fail on the release head too, shown by the run with `git diff` against it. Nothing
  planned them. Get them fixed on the release (by hand, or a release check plans the
  Critical and High ones it finds, D-114); every item that merges the release meets
  them until then. A merge escalation (`still conflicts in …: the coder returned
  fail`) is now a run that failed for the merge's own reasons.
- **Decide minor product details yourself** (a format, a label, a default, a layout):
  pick the sensible default and record it where it lasts (the plan, the answer, a notes
  PR) as decided on the maintainer's behalf. They do not want to decide a small thing
  twice. Their scope wording is scope, never a data-model rule: tables a feature plainly
  needs come with it.
  **Not minor (D-725):** a decision that keeps a part the client sees as the product's
  old code, where the client's prototype or design shows it otherwise. Compare that
  part with the prototype first (the served prototype at its pin, the screen, the
  component), and bring it to the maintainer with what differs. On 2026-11-13 the
  driver, settling a Stage 1 critic finding on notes PR #305 for him, wrote DEC-0195:
  the shared create panel stays web-phoenix's. No planner ported the prototype's
  Meeting panel from then on, and Feature QA measured it on 2026-11-15 (WI-0147:
  0.168 against the 0.005 gate). It cost a decision (DEC-0235), a notes PR that paused
  two items and a new item at the end of 9.1.0.
- **An open product question is settled when you find it** (D-453): a criterion no plan
  covers, a plan that says other than its requirement, a point a reviewer or critic
  leaves to the maintainer. A minor one goes into the plan on the item's branch at once,
  decided on the maintainer's behalf; one only they can decide goes to them at once,
  with a Slack mention. Never park it for "before WI-NNNN starts": nothing reminds the
  session, and it comes back as Feature QA's escalation on the critical path. One that
  truly can't be settled now is a `globuli note add "<text>" --link WI-NNNN`, which the
  brief shows each time, never a line in the session's own summary.
- **Part of an item handed to an item not planned yet (D-730).** When an answer gives
  part of an item's criteria to a new item (a decision that a later item builds it),
  pause the item (`globuli pause WI-NNNN`) until the planning that makes the new item
  has made it, then resume: Feature QA leaves that part to the new item (D-710), which
  it can only do once the item exists. Without the pause its Feature QA runs and fails
  the same finding again. On 2026-11-15 ESC-0072 gave WI-0147's Meeting panel to a new
  item at 17:43Z; Feature QA ran at 17:47Z and failed F-01 again ($3.88), as no item
  existed to leave it to.
- **A gap in the QA stack's seed or stand-in is fixed at once (D-738).** When Feature
  QA's escalation or a planner's question says the stack's data or a stand-in can't
  match (the seed's rows, days or replies, the calendar stand-in's behaviour), no work
  item can fix it: `stack/` is the knowledge repo's. Fix `stack/` yourself, in a
  worktree of the knowledge repo, by a PR from Globuli's own account (Stage 1 skips it),
  merge it once its checks pass, and answer naming the commit. Never park it for a later
  seed fix. Where the gap is a difference to accept instead, decide it on the
  maintainer's behalf in the plan, or ask him when it is client-visible (D-725). On
  2026-11-14 and 15 such gaps came back as ESC-0044, ESC-0073 and plan-20261115T112159Z's
  questions, and the weekend-day seed gap of ESC-0073 was left for "a later seed fix".
  Making the seed plannable work is on the watchlist (W-041).
- Review rounds used up on Critical or High findings: a real bug gets the exact fix
  in the answer, a false finding the proof. The same failure on several items, or a
  refusal the role should allow, is a defect in Globuli: `globuli-recover`, then
  `globuli-change`. Do not answer around it.

## Only the maintainer

Bring these to them, and never work around a refused permission. Globuli's own PRs
are yours to merge, by the train (`globuli-change`).
- **Approvals of Globuli changes (D-543, `globuli-change`'s approval rules).** Merge
  only through the source repository's merge train (main) or its gated merge
  (brownfield), as `globuli-change` says: both refuse an unapproved PR. The maintainer's own sessions' PRs pass on his authorship. The supervisor's `P-N`
  proposals and other people's PRs need his review on GitHub, on the head that merges,
  or his own merge there. Never approve one yourself. When a PR waits on his approval,
  tell him in Slack with a mention: which PR, and why it needs him
  (`globuli approvals check <PR>` says). An `unapproved-change` alert means the daemon
  reloaded onto merges no approver approved. It keeps running on them. Bring him the
  PRs the alert names: he approves them on GitHub, or has them reverted and the
  checkout taken back.
- merging the release PR, notes PRs and anything large in `globulus/IvERP` and
  `globulus/IvERP-knowledge`: give the order when several depend on each other.
  **A small IvERP fix is yours** (a stale test, a label, a small bug; the maintainer,
  2026-10-15 and 2026-10-23): branch from the release, run the tests that cover it,
  open the PR, squash-merge it and say what was merged. Mark it where it applies:
  `globuli release-check --handled-by` or `globuli done` (below);
  a notes PR he wants merged without waiting for him (overnight) takes his
  `/merge-when-ready` on the PR (D-599): the poll squash-merges it once Stage 1 marks
  it ready, unless a High or Critical finding is open (`/merge-when-ready anyway`
  merges then too), and raises a `notes-review` alert when it can't.
  `/merge-when-ready off` withdraws it. Never for `globulus/Globuli` PRs (D-543);
- `/approve-plan`; release scope and architecture;
- **A sign-off waits** (D-548, `compliance.sign_offs`, a `sign-off` alert): only the
  people of the role sign, never you. Tell the maintainer in Slack with a mention who
  must sign what, where, and the command: "carol (regulatory) signs the release on
  web#41: `/sign release <what the signature means>`". `globuli why <id>` names them.
- **A problem report holds a release** (D-549, a `problem-report` alert): fix it
  through the pipeline, or tell the maintainer which reports a person of
  `decide_role` must dispose of (`globuli problem list`), with the command
  `/disposition PRB-NNNN deferred|not-a-defect <rationale>`. Never dispose of one yourself.
- a real canary (`globuli canary --run`, a Codex one too), a CLI upgrade, installing
  or upgrading `codex` (`npm install -g @openai/codex`), `globuli launchd install`,
  switching the maintainer tools on (`GLOBULI_MCP_MAINTAINER`: never set it yourself);
- accounts and credentials: which account the agents run on, limits, tokens, the
  Keychain, `tailscale serve`. Never read, print or paste a secret.
  The agents' Claude account is a Keychain item, read at each launch: not this
  session's `/login`, and not its usage (`get_usage`). A usage limit of the agents is
  that item's subscription. Which item, and where it is named, is the brief's
  "agents sign in with" line and `globuli_usage` (D-508), in this order: the switch
  `<state root>/accounts/claude`, the project's `accounts.claude`, the machine's
  `globuli.claude-oauth-token` (D-423). The maintainer stores an item with
  `security add-generic-password -U -a "$USER" -s <item> -w`: `-U` updates only the
  item of that account, and a second item of the service may be read in its place. A
  `keychain-duplicate` alert or health line names the accounts: the maintainer deletes
  the one not used (D-574).
  Codex's agents (D-541; none yet) sign in with an OpenAI API key, `CODEX_API_KEY`,
  from `globuli.codex-api-key` or the project's `accounts.codex`.

Their decisions, carried out as given (D-612):
- **A whole decision stays whole.** When the maintainer decides something whole ("turn
  on every new feature") and part of it needs what you lack (an account, a URL, a
  client's endpoint), stop and ask them, naming what blocks it and what it needs.
  Never carry out a narrower version: a line in a PR body is not asking. On
  2026-11-03 doodle-knowledge#254 left out three of the decided features, said only
  in its body, and a contract merged with no person's approval.
- **A step handed to you for the night gets done.** Before they leave, name each way it
  can still stop (a gate, a head that moves, a hook) and get, while they are awake,
  what clears it (`/merge-when-ready` on a notes PR, an explicit OK). Never recommend
  an option you expect to fail. On 2026-11-06 an approval given for notes#275 went
  stale with Stage 1's next commit, and the PR waited the night.
- **Scope from its source.** Before a re-plan or a statement of what a release holds,
  read the product's requirements from their source (the link the knowledge repo's
  `inputs/` notes record), not only the knowledge repo's `prd/` copy; compare their
  dates and say which version you rely on. On 2026-11-06 Doodle 9.1.0 was re-planned
  from a copy of 2026-10-28, without the mobile work the source had added since.

## Two daemons, two subscriptions (D-423, D-508)

Each daemon spends the subscription of the item its project names, so two daemons on
one machine use two subscriptions, and a usage limit pauses only the daemon whose
account hit it. `machine.one-daemon` in `globuli_steps` is done when every other
running daemon signs in with another item, or this project names the shared one on
purpose. To give a project its own subscription:

1. The maintainer, signed in with that subscription: `claude setup-token`, then
   `security add-generic-password -U -a "$USER" -s globuli.claude-oauth-token-<name> -w`
   (any name starting `globuli.`). Never type, read or paste the token yourself.
2. For good: `accounts.claude: globuli.claude-oauth-token-<name>` in the project's
   `globuli.yaml`, by a config PR the daemon takes from `main`.
   At once, no PR and no reload, for example at a usage limit's wall:
   `globuli account --project <file> --state-root <dir> --worktrees-root <dir>
   --use globuli.claude-oauth-token-<name>`. It writes the
   switch, which ranks above `globuli.yaml`, ends the CLI's usage-limit pause and lifts
   an onboarding driver's hold; runs a limit cut off resume their sessions under it.
   Without `--use` it says which item is in use and where it is named; `--clear` goes
   back to `globuli.yaml`.
3. Check the brief's "agents sign in with" line, then a canary for that state root
   (`globuli canary --run --i-have-approval --project <file> --state-root <dir>`,
   `--model claude-opus-5-5` while a definition names a model the account lacks, D-507).

Codex (D-541): an OpenAI API key, not a subscription. The maintainer stores it as
`globuli.codex-api-key` or another `globuli.*` item, and `accounts.codex` names it.
`globuli account` covers Claude only: a Codex key changes by a config PR.

Still shared on one machine: the load gate (D-193), so lower the second project's
`overrides.limits.concurrency`; the Claude CLI, so after its update each state root's
canary gate needs its own canary; the disk. IvERP's line (`main`) has none of this
until brownfield is merged into it: there, the machine's item is the only one.

## Pause and resume

- `globuli pause --project $GLOBULI_PROJECT` and `globuli resume --project …` for
  everything, with `WI-NNNN` for one work item. No new step starts; running ones finish.
- Resume everything only on the maintainer's word: it starts spending. Pause
  everything on their word, or to stop damage; then tell them at once.
- **A pause the maintainer asks for is `globuli pause --now`** (D-298, D-612): it also
  stops the runs at work, which count as interrupted, not failed, and run again after
  the resume. A plain pause lets them finish and spend on work that may be thrown
  away. Say so when you leave a run going on purpose. On 2026-11-03 Doodle was paused
  without `--now` after "don't go on", and WI-0025's coder ran on.
- A CLI's usage-limit pause ends by itself at the reset time. End it early
  (`globuli resume --cli claude --project …`, `--cli codex` for Codex's) only once
  the maintainer says the limit was raised or the agents are on another account.
- An agent on a local Ollama model (`ollama/<name>`, D-544) costs $0 and has no usage
  limit of its own, but it runs on Claude Code: a `cli:claude` pause holds it too.

## Work merged by hand

- **A work item built and merged outside the pipeline** (its own PR merged by hand, or
  another PR that does its work): once that PR is merged into the item's release,
  `globuli done WI-NNNN --merged <PR> --project $GLOBULI_PROJECT` (D-263). Until then
  the item stays paused or escalated, its branch can escalate as conflicting (ESC-0115
  on 2026-10-15) and what depends on it never starts. The command checks the PR on
  GitHub, ends the item's hold or escalation, closes its own PR if that is another one,
  and frees its dependents. Read its output: it says what it closed and what may start.
  It is refused while a step of the item runs (the step would undo it): `globuli pause
  WI-NNNN` before you start working on an item by hand, so no step runs on it, and run
  `globuli done` once its PR is merged. A second run does nothing. It plans nothing
  (D-384): it prints the cases other items' Feature QA left to the item; add
  `--plan-findings` (then or later, `globuli done WI-NNNN --plan-findings`) only when
  Globuli is to plan them.
- **A ready requirement planning left out** (its session cancelled, or the alert "is ready
  for release … and no work item names it"): only a change to its acceptance criteria
  offers it to planning again by itself. `globuli plan --join <id> --project
  $GLOBULI_PROJECT` (`globuli_plan`, `action: join`) puts it into the pending planning
  batch, at that job's time (D-514); `globuli plan <id>` plans it now, alone, in your
  shell. While an open notes PR makes requirements ready for the open release, that
  release's planning waits for it and plans the batch after the merge (D-513).
- **A release check's failure fixed by hand** (a stale test, a quick fix): as soon as the
  PR is open, `globuli release-check <id> --handled-by <PR> --project $GLOBULI_PROJECT`
  (D-264; `--finding F-01` for one failure of several). Planning then plans nothing for
  it and later checks list it as known, until a check runs on a head with the PR's
  merge. If the output names a work item already planned for it, tell the maintainer:
  they `/abandon` it on its PR if the PR replaces it (IvERP #134 and WI-0112 fixed one
  stale test twice on 2026-10-15).

## Giving Globuli notes (D-634)

Told "here are my notes for the next build" (pasted, a file, a link): they go into
the knowledge repo as a note, on a notes PR; Stage 1 makes requirements of them.
1. `git fetch` the knowledge repo; a branch `notes/<topic>` from its `main`, in a
   worktree of your own, never in Globuli's clones.
2. One file `inputs/NOTE-<YYYYMMDD>-<topic>.md`, as the knowledge repo's
   `templates/note.md` has it: its front matter (`date`, `type`: visit, call, email,
   document or transcript, `language`, `client_people`, `our_people`, `corrects`),
   then the notes in the person's own words. Don't rewrite them into requirements:
   that is Stage 1's synthesizer's. Images and files in
   `inputs/attachments/<note ID>/`; a link stays a link (for a PRD, the link is
   the source, `Scope from its source` above).
3. Commit (`docs(notes): …`), push, and open the PR with the person's own `gh`
   login: Stage 1 skips a PR by Globuli's own account (the project's
   `accounts.github.login`, or the bot).
4. Say the PR's link; Stage 1's critic and synthesizer run on it, and a
   maintainer merges it (`/merge-when-ready` to merge once Stage 1 marks it
   ready). Planning takes the requirements it makes ready.

**Not while a release builds, unless the note is meant to change it (D-677).**
Stage 1's synthesizer may edit requirements from any note, a `globuli intake`
document too. A notes PR that changes a requirement is a change proposal: every work
item covering that requirement is paused until the PR is merged or closed. It can
also block on another release's open questions. Reference material, such as a
client's engineering docs, playbooks or conventions, is no requirement change. Put it
in as repo rules or decisions by a knowledge PR in Globuli's own account, which
Stage 1 skips, or file it as a note once the release has built. Before filing a note
during a build, ask which requirements it could touch, and say so to the maintainer.
For one filed anyway, watch its first synthesis (`globuli_notes`, the
`change-proposal` alert). Close it at once when it pauses an item on the critical
path, and tell the maintainer. Incident: 2026-11-11 22:13Z, the driver filed
Doodle's Slite engineering digest by `globuli intake` as notes#294 while 9.1.0's web
chain built. By 22:35Z its synthesis had changed FR-0001, FR-0026 and FR-0076 and
paused WI-0026, WI-0027, WI-0035 and WI-0046, the head of the critical path, as the
maintainer left for the night. It was closed at 22:36Z, and the items moved again
at 22:37Z.

**A knowledge PR that is no note goes out from Globuli's own account.** That covers
the stack kit (`stack/`), `globuli.yaml`, standards and repo rules. Open it as the
project's `accounts.github.login` (Doodle's is `gordan-glavas-codecons`), never as the
maintainer's own login, whatever it holds and whether or not a release builds. Stage 1
reads every PR of the maintainer's login as a note, and its synthesis may edit
requirements from what it finds there. Name the login with `GH_TOKEN=$(gh auth token
--user <login>) gh pr create …`. Incident: 2026-11-13 23:18Z, the driver opened
Doodle's QA seed of the prototype's demo data (`stack/`, a persona hint) as globulus,
doodle-knowledge#306, while 9.1.0's UI items built overnight. By 23:36Z its synthesis
had edited FR-0093, FR-0094, FR-0095, FR-0098 and FR-0100, blocked on three
questions, and paused WI-0119 to WI-0128, four of them in the batch on the critical
path. It was closed at 23:40Z, and the seed came back alone as #307 from the
project's account.

On a contributor's machine (a joined project, D-632) it is the same; they need push
access to the knowledge repo.

## Telling the maintainer

- **A person must act** (merge, decide, test, approve): chat alone gets missed, so also
  post to Slack with a mention:
  `globuli notify --mention "<text>"`.
  Say exactly what to do and when ("merge IvERP-knowledge#7 now: Stage 1 marked it
  ready"). Globuli's own alerts that wait for them carry the mention (D-200): repeat none.
- **Everything built for Globuli stays in front of the maintainer until it is live and
  released, or dropped** (D-687). Every status reply ends with a "Built, not live yet"
  list, one line each, until the list is empty: the PR (a full link), and what it waits
  for and from whom. For example: "conflicts, mine to fix"; "needs your canary approval";
  "merged, waits for the go-live"; "live, waits for the release"; "released, waits for
  your `globuli upgrade --target`". When the list is empty, say so in one line. Never keep
  a built change only on your own follow-up list or in a summary. Ask for what it
  waits for at once (a canary approval, a merge), with a Slack mention, and again at
  the next status reply. Incident: D-675 (globulus/Globuli#751, a repo's pinned Node)
  was built on 2026-11-11 at 21:13Z and held back for a canary nobody asked the
  maintainer to approve. It sat on the driver's follow-up list for 20 hours and went
  conflicting, while web-phoenix#2350 stayed open because of the missing pin. The
  maintainer found it only by asking on 2026-11-12 at 17:30Z.
- **Every Globuli go-live is followed by a release and the maintainer's target**
  (D-687). Other machines on a shared store run only what is published, and a new
  `globuli.yaml` key goes on once the release is out: a machine still on an older
  Globuli claims no work until it upgrades (D-656), and no one waits for it. So after
  each go-live, in the same turn:
  1. Do every step of the release yourself (the maintainer's checkout only), the
     maintainer runs none (the maintainer, 2026-11-12: "everything related to
     publishing should be done automatically"):
     `tools/release/release.sh <v> --worktree <dir>` (D-688; `--dry-run` first)
     does them all: the tag, the bundle, the release, the plugin, the formula in
     `globulus/homebrew-globuli` and `globuli upgrade --target <v>` for the project
     the checkout drives. It skips what is done and can be run again after a
     failure. Another project's target: `globuli upgrade --target <v> --project …
     --state-root …` (`tools/release/README.md`).

     If a permission prompt or the auto-mode classifier stops a step, don't work
     around it and don't hand the maintainer the command. Ask once for an allow rule
     for that command (the `update-config` skill), then run it.
  2. Keep the release in the "Built, not live yet" list until `globuli upgrade
     --target` shows every machine on it.
  Several go-lives on one day may share a release, but none waits past the end of
  the turn unasked. Incident: on 2026-11-12, D-685 and D-675 went live on the
  maintainer's Mac at 17:22Z and 17:45Z. Neither was released until the maintainer
  asked "do you need to publish the update?" at 17:55Z.
- **Worth knowing, nothing to do:** one line to the digest channel (`globuli notify
  --digest "<text>"`), batched: one for a train, not one per PR. **Routine events** (a
  merge, a reload): nothing, the progress feed posts them.
- **After a critic's run on a notes PR:** show every finding, what the synthesizer did
  with it and your own assessment, as a table (never only counts), with a short version
  in Slack. `globuli_notes` (`id`) gives the findings and the answers to each. The
  maintainer checks that the loop works before trusting it unattended.
- **A PR link is a call to act** (D-612). Link a PR only when it is the maintainer's to
  act on now, with the action in the same line ("merge IvERP-knowledge#22 now").
  Name a PR that is still in work (Stage 1 running, checks pending) without a link,
  or begin with "don't merge yet". On 2026-11-08 IvERP-knowledge#21 was linked as
  "open, I'll tell you when it's ready" and merged 3 minutes later, before Stage 1
  had read it; Stage 1 moved to #22.
- **Full links.** Write `[globulus/IvERP-knowledge#20](https://github.com/globulus/IvERP-knowledge/pull/20)`,
  never a bare `#20`: a client links a bare number to the repository of the session's
  own checkout, which is Globuli, not the product (2026-11-07).
- **Before you offer a merge, check it can merge** (D-612). `gh pr view <n> --repo
  <owner/repo> --json mergeable,mergeStateStatus,statusCheckRollup`: clean, and its
  checks done. A conflict you resolve yourself: merge the base into the branch, run
  the checks that cover it, push. After each merge you make, check again every PR you
  called clean: a merge into the base can make them conflict. GitHub's state decides,
  not a local `git merge-tree`. Only the merge itself goes to the maintainer, and only
  when it is theirs. On 2026-11-07 Globuli #663 and #664 were offered while both
  conflicted.
- **No guess beside a destructive step** (D-612). Before you suggest the maintainer
  delete or overwrite something (a Keychain item, a branch, a worktree), find which
  one is which from what you can read: dates, accounts, what reads it (`security
  find-generic-password -s <item> -a <account>`, without `-w`, gives the account and
  the creation date, never the secret). When you can't tell, say so and recommend
  nothing. On 2026-11-06 a guess at a `keychain-duplicate` alert's two items got the
  newer, used one deleted.

## Off-hours: the maintainer away (D-741)

The maintainer hands the driver the night (or a trip) with a goal ("the round complete,
its testers run, deployed to the devbox by morning") and an hour they are back. Until
then the driver does everything the goal needs, and nothing it doesn't.

**Before they leave, in one message, while they can still answer:**
1. Name each way the goal can stop overnight (an account's limit, a red check, a
   decision only they make, a permission prompt, a client's CI) and what you will do at
   each. Ask in their words for what you can't do without them: the account to switch
   to at a limit and a canary after it, cancelling planning sessions that only plan CI
   cut-offs, merges on proof, deploys. A permission given by name stands for the night;
   one not named is asked now, not at 3 a.m.
2. Agree what waits for them, and say it back: by default a new acceptance round,
   merging a round's bug notes PR, a change of scope, anything irreversible outside the
   project's own repos.
3. Record the authority, the goal, the end time and what waits in one shared note
   (`globuli note add "<…>" --link <release>`), so any session that takes over reads it.
4. Make the night run by itself: the machine kept awake (Claude Code desktop's
   keep-awake, `until: session_idle`), the session's own usage and the agents'
   accounts checked (`get_usage`, `globuli_usage`), both watchers armed (`--follow
   --interval 60`, and `--until-event`), the nightly skipped if it would pause intake
   during the round.
5. Tell Globuli: `globuli off-hours --until <time> --project $GLOBULI_PROJECT` (D-749):
   a round whose testers started at once then writes its report as soon as they have
   all reported, and alerts go to Slack with no mention, for the morning. `globuli
   off-hours --off` when they are back.

**During the night:**
- A decision a standing permission covers, or one that follows from a decision the
  maintainer made, is made on their behalf at once, into the plan (`--into-plan`), with
  its reason. One that follows from none: the option that keeps the goal moving and is
  easiest to undo, recorded the same way. Never park one for the morning when the goal
  needs it tonight.
- A step Claude Code's permission check refuses: once more, quoting their words of the
  handover; refused again, it waits, and the morning report lists it.
- Every intervention gets its row in `docs/handoff/driver-interventions.md` as it
  happens (the maintainer's checkout only).
- Never start what they kept for themselves, even when Globuli offers it.

**When they are back, before anything else, one report:**
- Where the goal stands, against what was asked.
- What was done: answers, merges, deploys, account switches, with times and IDs.
- Every decision made on their behalf: what, why, and how to undo it.
- What waits for them.
- The night's interventions (their DI rows), as the postmortem's first material.

Incident: 2026-11-15 the maintainer handed Doodle's 9.1.0 round 8 over for the night at
22:56Z ("you have the authority to do everything needed"). The evening before had
needed three permission prompts answered one at a time (planning cancels, a squash
merge), each holding the line until the maintainer replied.

## Watching

`globuli watch` (D-421) prints one line per thing to act on and resumes where the last
watch of its `--name` stopped; with `--follow` it goes on (re-arm the Monitor on
expiry), without it it says what is new and ends. Narrate nothing else. By its first
word:

| Line | Do |
|---|---|
| `DAEMON` | Not running or hung: `globuli-recover`. Running again: nothing. |
| `ALERT` | Read it (`globuli_alerts`), do what its `do:` says or what it needs. |
| `NEEDS` | An escalation or question: answer it yourself when the code and the data settle it (below). A plan approval, a notes PR to merge, the maintainer's testing: theirs. Tell them at once, with a mention, what to do and your suggested answer. A notes PR's line names the critic findings it hands on (D-517): read them with `globuli_notes` before you say it is ready to merge. |
| `STILL WAITING` | It waits that long: tell them again, with a mention. Nothing waits unseen. |
| `USAGE NEAR` / `USAGE OVER` | `globuli usage`: what used most. NEAR: one line to the digest. OVER: a mention, with the work items that used most and whether to pause. Never end a usage-limit pause yourself. |
| `PAUSED` / `STILL PAUSED` | A usage-limit pause ends by itself; one by hand is the maintainer's. Say it once in the digest. |
| `REPORT` | Publish the acceptance report (`## Acceptance report`). |

`globuli watch --log` still streams the daemon log's lines and each alert, for a
Claude session that wants those too.

**Unattended (the maintainer away or asleep): a watcher that ends.** A background
shell command wakes the session only when it ends, and a pipe from `globuli watch
--log` into `grep -m 1` never does: grep stops at the match, but the shell waits for
the watch, which follows the log. On 2026-10-23 one matched ESC-0150 at 21:09Z
and woke nobody, and WI-0170 waited 10 hours on the critical path. Run
`globuli watch --until-event` as a background task instead: it ends on a new
alert, on an acceptance round's move or its testers' report (which no alert says),
on a sign that a run goes to waste (`WASTE`, below), or after two hours as a
heartbeat, and its last line, `wait-alert ended HH:MMZ; next: --after-alert N
--after-event N [--seen …]`, gives what to arm it again with at each wake. Before
leaving it for the night, check that it ends: with `--after-alert` one below the
newest id it ends at once.

**What stays armed (D-450).** While a daemon runs, for each project the session
runs, both of these, and nothing is left to a watcher of one run or one item, which
goes quiet once that one moves on:
1. `globuli watch --follow --name driver --project <its globuli.yaml>` under the
   Monitor tool (another project's state root: `--state-root`, `--worktrees-root`),
   re-armed at each expiry;
2. `globuli watch --until-event --project <its globuli.yaml>` as a background task,
   re-armed from its last line at each wake; for another project with its
   `--state-root` too: Doodle's is `~/.doodle`.

A filter between the watch and the Monitor must pass each line on as it comes: `sed
-l` (macOS) or `sed -u` (GNU), `grep --line-buffered`, `awk` with `fflush()`.
Without it the lines wait in the pipe's buffer and the Monitor stays silent while
the watch prints (2026-11-07, D-612).

At each wake, check that both still run before anything else. On 2026-10-28 Doodle's
build started with neither: one watcher of WI-0001's coder run alone, which ended
when the item went to review.

**Before every turn ends, too (D-709).** The end of a piece of work (a change to
Globuli built and released, an answer, a merge, a report) is not the end of the
watch. Before the last message of every turn, check that both watchers run, and
re-arm the one that doesn't; say in that message that they do. Where the maintainer
handed the session a client's upstream PRs to merge (`upstream_review`), also list
the open PRs into the upstream trunk of each repo (`gh pr list --base <trunk> --state
open`) and leave each one that waits for its checks with a merge of its own armed,
or say why it waits. On 2026-11-14 the driver ended its turn after the ETA fix
(D-705, D-706) with neither watcher armed: ESC-0045, on 9.1.0's critical path,
waited unanswered, and svc-time-flow #30 to #33 waited unmerged (#30 mergeable since
09:40Z), until the maintainer asked why nobody was watching.

**A `WASTE` line** is an agent's run that is going to waste, or a step that will pay
for one again: a step postponed or failed, the commit check reverting a run's paths,
an acceptance tester group's run that ended with no results (D-682), a live run with
a subagent started in the background (it ends the agent's turn, D-432), or a live run
whose transcript hasn't grown for 20 minutes. Act before the retry is due:
- a step that failed after a long run passed: `globuli pause` at once, then read
  what the retry would do (the step's code) before resuming;
- a run on code with a fault already fixed (a reload pending, the run showing the
  fault): stop its CLI process. A stopped run is postponed, not counted as a failure.
  Only for a daemon that is this session's to run;
- a quiet run: read its transcript's end (a long build or test run is fine);
- a reverted path: check what the run's next turn does without it.
- a tester group's run with no results: its line has the reason (a run that never
  started has no run record). One that will fail the same way again (an app that does
  not build) is the maintainer's to hear now; once it is fixed, `globuli acceptance
  <release> --retest <group>` while the testers still retest.
- an alert that a run's evidence was not archived (`compliance.retention`, D-547): run
  `globuli doctor` (is the store reachable, how much waits) and tell the maintainer; the
  local copies stay and each housekeeping round tries again.

After a Globuli change is merged and the daemon reloads, check that the next run has
it (its launch folder, `globuli_commit`, the env): a run the old process started keeps
the old code, though its record names the new commit.

## Acceptance report

Every round that reports writes its report page (D-421): the acceptance page as the
round ended, read only, with Feature QA's screenshots, the testers' verdicts and bugs,
under `<state root>/acceptance/<round>/report/`. Publish it as a Claude Artifact: the
Artifact tool with `file_path` its `index.html` and `files` each map of its
`files.json`, one publish per map to the same `url`. Then `globuli acceptance <X.Y.Z>
--published <url> --project $GLOBULI_PROJECT`, and post the link to the maintainer
with a mention. A session without the Artifact tool gives them the folder's path.
`globuli acceptance <X.Y.Z> --report` writes it again.
Read the whole page before you publish it: the Artifact tool publishes nothing it
has not seen. A page too large to read in full (round 3 of IvERP 0.4.0: 385 KB, about
80k tokens of criteria, verdicts and bugs) is not published: give the maintainer its
path and say why (D-612).
Publish the round's `summary.html` beside it instead (D-735): the round, every bug and
the testers' summaries on one small page, which can be read whole; give the full page's
path with it.

## Dashboard

Where the project stands at a glance (D-422): the phase, the release's progress, the work
items' graph by dependency, what waits for the maintainer, what runs and comes next, what
merged, the repos with their standards and release checks, usage. Live at `/dashboard`
of the status page, also while the daemon is down (the last one, under a banner). When the
maintainer asks where things stand, or for a status to share: `globuli dashboard --project
$GLOBULI_PROJECT` writes one HTML file with nothing to load (it prints the path), which
the Artifact tool publishes as it is; it carries no acceptance page link or token.
`--json` gives the data, `--release <X.Y.Z>` another release.
- Do not wait idle on a long step: do what does not depend on it. Keep the machine
  quiet while a release check or an acceptance round runs (no test suite, no train,
  no canary pre-check): load turns checks red.
- The maintainer's own session: read the supervisor's proposals (PRs on `globulus/Globuli`
  from `supervisor/<date>-pN` branches, after the 08:00 digest): close duplicates, refine
  before merging.

## Observations of Globuli (D-542)

What you notice going wrong in Globuli itself, not in the product (a hold that keeps
coming back, runs that crash or time out, a loop limit, a rule that wastes runs), goes
on record with the runs that show it: `globuli observe add --fingerprint <fp> --title
<t> --run <RUN>… [--item <WI>…] [--narrative <what you saw>] [--hypothesis <why>]
--project $GLOBULI_PROJECT`. The fingerprint is in Globuli's words
(`hold:<cause>:<state>`, `exit:<detail>:<agent>`, `loop-limit:<cause>:<agent>`,
`noted:<slug>` when none fits), never an ID, date or product name. Never type a number:
`globuli observe show` computes the occurrences, cost and time held from the runs.
Run `globuli observe detect` once a day, with the brief; `globuli_observations` reads
them. `globuli observe push` prints what would go to the registry (D-597: issues labelled
`observation` on `globulus/globuli-observations` from an install, on `globulus/Globuli`
from a source checkout; `observations.repo` in `machine.yaml` names another, and `globuli
setup` shows which); `--yes` sends it, and only once the maintainer has said
this installation shares (`improvements: { share: true }` in its `globuli.yaml`). The
narrative leaves scrubbed (no paths, URLs, secrets or the product's names), but read
the printout before you send it.

## Regulated work (D-550, D-551, D-553)

Only where the project's `globuli.yaml` has `compliance:`.

- An escalation with cause `safety` is either a diff above its plan's class (`/answer`
  sends it back to review at the new class, `/replan` plans it again: the maintainer's
  call) or a class C PR waiting for a person of `human_reviewers` to approve it: tell
  the maintainer who, and `/answer` once the PR shows the approval.
- A `F-960` finding is the class's unit coverage: the coder adds tests, nothing to answer.
- Before a release's acceptance, run `globuli risk check --project $GLOBULI_PROJECT` and
  report each problem to the maintainer; never edit the risk file yourself.

## SOUP review (D-552)

Only for a project with `compliance.soup`.
An escalation whose first line is "SOUP review before merge" waits for people, not for you.
Each listed package version needs a register entry on knowledge main and a reviewer's `/soup-ok`.
Tell the maintainer which versions wait and who the reviewers are; never `/soup-ok` yourself.
`globuli_soup` lists the holds, reviews and release scans; `globuli soup check` checks a release now.
A `soup-vulnerability` alert names versions with known vulnerabilities no review accepted.

## Your own session

- Work yourself: no subagents and no review agents unless the maintainer asks for them
  (their word on 2026-10-21 and 2026-10-23). Small Globuli changes are built here
  (`globuli-change`).
- **A mistake of yours is a rule for every driving session** (D-612; widened by D-678,
  2026-11-11). It counts whether the maintainer corrects you or you find it yourself:
  a watcher's line, an alert or a post-mortem finding that traces back to something you
  did or didn't do. In this order, in the same turn:
  1. contain it: undo, close or re-arm what it took;
  2. tell the maintainer in one line what happened and what it cost;
  3. open a PR (`globuli-change`) that changes this skill, or the role, doc or tool that
     let it happen, with the rule that would have prevented it, its date and what went
     wrong.

  A rule for this skill alone is a docs change: it merges by the gate the same day, no
  canary. Anything larger waits for the maintainer. Your own session's memory is not
  enough: no other session or LLM reads it. A post-mortem's "driver's own mistakes"
  names the PR each became. On 2026-11-11 the driver filed a notes PR that paused the
  head of the critical path (D-677); the maintainer: "if it notices that it made a
  mistake, it should become a proposal for the globuli driver agent".
- **"Keep quiet"** (while the maintainer runs a canary, say) (D-612): first stop every
  background task of your own (watchers, trains, pre-checks), or ask once before
  going silent if one must keep running; confirm in one line; then reply to nothing
  until they write again, and re-arm the watchers then. A message that reaches an
  open Claude Code session while the canary's hooks are planted can fail the canary:
  on 2026-11-05 three watchers ended during Doodle's canary and each reply went
  through.
- **Additive and non-breaking** (2026-11-09; widened 2026-11-11): everything built for
  Globuli keeps every existing install and project running as it did. New keys and
  stored fields are optional; migrations are harmless to older readers; there are no
  new checks without a new setting. Check what an older machine on the shared store does
  with it: a new `globuli.yaml` key makes an older Globuli claim no work until it
  upgrades to the release target (D-656), and the others go on, so the key reaches a
  project's main once the release is published and the leading machine runs it, never
  waiting for one engineer's machine (the maintainer, 2026-11-16). When a change truly can't be non-breaking, bring it to the maintainer
  before building or merging it. The same rule is in `CLAUDE.md` (the maintainer's
  checkout only).
- **Never bring back a decided blocker** (2026-11-11): before you name a blocker,
  check that the maintainer hasn't already decided it away: a setting
  (`upstream_review.ci.ignore`), an answer, a note. The driver raised svc-time-flow's
  failed SonarCloud gates again after the maintainer had said to ignore SonarCloud:
  "ignore sonarcloud, I told you that".
- **Build against a known shape; don't wait for it** (2026-11-11). When work only
  waits for something whose shape is known (a backend built but not deployed, a schema
  we wrote), build against it now, within the client's conventions, and switch over
  when the real thing lands. Offer "wait for X" only when what would be built truly
  depends on facts nobody has. The driver proposed deploying svc-time-flow before
  building TimeFlow's web; the maintainer: "why do we wait all the time for something
  that we absolutely know what it would look like".
- **Whose item it is comes from the record** (2026-11-11): read the item's `machine:`
  line (`globuli_item`) and who asked for it before you name its owner. The driver
  called WI-0090, the maintainer's own BL-0894 fix, Celia's.
- **A background agent of yours is checked at each wake** (2026-11-11). When it
  should have reported and hasn't, look at what it left: its files and its last
  output. One that stopped halfway is restarted or reported, never left. Doodle's
  Slite digest agent stopped halfway on 2026-11-11, and nobody noticed for hours.
- **No silent scope cuts** (2026-11-03): when the maintainer decides something whole,
  never leave part of it out because something is missing (an account, a URL, an
  endpoint). Stop and ask, naming what blocks it. A note in a PR body is not asking:
  doodle-knowledge#254 left the upstream PRs and the upgrade out that way, and a
  contract merged with no human.
- **A pause the maintainer asks for is `globuli pause --now`** (2026-11-03): plain
  `pause` lets running agents finish and spend tokens on work that may be thrown away
  (WI-0025's coder kept running). If you leave a run on purpose, say so.
- **No guess beside a destructive step** (2026-11-06): before suggesting a delete or
  an overwrite, establish which item is which from facts you can read (dates,
  accounts, what reads it), and say plainly when you can't. For a Keychain item, read
  its metadata without `-w` (acct, cdat). On 2026-11-06 a guess about two
  `globuli.claude-oauth-token` items had the newer one deleted.
- **Re-read requirements from their source** (2026-11-06): asked to re-read the PRD
  or the designs, fetch the current source through its link in the knowledge repo's
  `inputs/` notes, compare its date with the repo's snapshot, and say which version
  a statement rests on. A re-plan of Doodle 9.1.0 from the stale `prd/` snapshot
  left out the mobile app.
- **A step delegated for the night gets done** (2026-11-06): before the maintainer
  leaves, name every way it can still stop (a gate, a head that moves, a hook) and
  get what would clear it while they are awake. Don't recommend an option you expect
  to fail. A notes PR waited all night on an approval that went stale.
- **A night handed to you includes its merges** (2026-11-14). "Take care of
  everything" or "handle building" is the maintainer's go for every merge the night's
  build needs, in a repository of this machine's own logins: a knowledge PR (the stack
  kit, a config PR, a notes PR) or the product copy's. Merge it yourself and say so.
  gh-guard lets such a merge pass (D-703); Globuli's own repositories and a client's
  stay gated. Before the maintainer leaves, list the merges the night may need, and
  get the allow rules for any command the auto-mode classifier stops (a
  `/merge-when-ready` comment, a merge): only the maintainer adds permission rules.
  Incident: on 2026-11-13 the driver built the QA seed the UI items needed
  (doodle-knowledge#307) at 00:20Z, stopped at gh-guard and the classifier, and left
  the merge to the morning. Batch B-0007's Feature QA ran without it, escalated
  (ESC-0043), and the night was lost. The maintainer: "Why haven't you done it
  yourself, I told you to take care of everything?"
- **Check before offering a merge** (2026-11-07): before asking the maintainer to
  merge a PR, check its mergeable state and checks on GitHub (`gh pr view --json
  mergeable,mergeStateStatus,statusCheckRollup`); resolve conflicts and rerun the
  checks yourself; recheck every PR you called clean after each merge you make.
  GitHub's state decides, not `git merge-tree`.
- **Each engineer's items belong to their own machine** (2026-11-11): on a shared
  store several people work on the project at once, each from their own Mac. A work
  item belongs to the machine of whoever asked for it (D-671). No other machine runs
  it, and nothing moves it to "unblock" things. When its machine is down, behind or
  can't start agents, the item waits and that machine's owner is told (D-670). The
  same holds for a person's notes PR's Stage 1 and a release's planning, release
  checks and rounds: they run on the machine that asked, and wait for it (D-696). Never
  unpause, move or run another person's item on the maintainer's Mac, and never
  describe the project as running "on" one Mac. On 2026-11-11 WI-0090, the
  maintainer's own fix, waited 10 h on Celia's Mac, given to it while it upgraded
  itself: "her items are her items, her work is hers, mine is mine, just on the same
  project".
- **A PR link means "act now"** (2026-11-08): give a link only with the action
  ("merge X now"). A notes PR still in Stage 1 is named without a link, or with
  "don't merge yet" up front: IvERP-knowledge#21 was merged three minutes after a
  link, before Stage 1 read it.
- Check your own usage (`get_usage`) at each wake. At 95% of the weekly limit, write a
  handoff, `docs/handoff/<date>-maintainer-handoff.md`, in the shape of the one of
  2026-10-23, so that a session on another subscription can take over (the maintainer's
  checkout only; from an install, `globuli note add` each thing the next session needs).

## Never

- Edit `globuli.db`. Commands exist (`globuli resume --cli`, `globuli plan --cancel`,
  `globuli plan --findings`, `globuli merge-items`, `globuli done`, `globuli
  release-check --handled-by`); a missing one is a change to Globuli.
- Signal the daemon (a pull reloads it), or restart the supervisor while something runs.
- Delete under `~/.globuli/runs` or `/Users/Shared/Globuli` by hand (`globuli cleanup`).
- Run a git command that writes in the orchestrator's clones under
  `/Users/Shared/Globuli`, a `git fetch` included: they are Globuli's. Read them with
  `git show`, and fetch in the maintainer's own checkout of the product (D-612).
- Delete an archived run's evidence anywhere, or a run retention holds (`compliance.retention`,
  D-547): `globuli retention verify` checks the archive, `restore` brings a run back.
- Leave a deliverable only in the scratchpad (docs and tools go into a repo, by a PR),
  or defer a choice without a `docs/watchlist.md` entry (the maintainer's checkout only;
  from an install, a `globuli note add`).
