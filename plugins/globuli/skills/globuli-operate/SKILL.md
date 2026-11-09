---
name: globuli-operate
description: Use when the session is told to use Globuli, or to run it for the maintainer, that is to watch the daemon, see where things stand, deal with what waits (an escalation, a question, an approval, an alert, a report to publish), watch the agents' usage, pause or resume, and keep the build moving.
---

# Operating Globuli

**Any LLM's session** (D-421): Claude Code, Cursor, Codex or another; `AGENTS.md` sends
them here. Everything below is a command any of them can run; the MCP tools are a
shorter way where the CLI has them. Told "use Globuli" and what to do: start at the
loop, do that, and keep the loop going until it is done.

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
3. Handle each item (below). First what holds a slot or the release's critical path.
   Read with the tools (list below), not with `sqlite3`, `gh api` or the run folders.
4. `globuli brief --mark --project $GLOBULI_PROJECT` once you have dealt with what it
   showed: the next brief lists the alerts since.
5. Leave what the next session must know and Globuli cannot derive (a decision and its
   reason, a promise, a thing to watch): `globuli note add "<text>" --link <ID>`, and
   `globuli note done <MN-…>` for one that is settled. Never the state: the brief has it.

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
- **A plan fact goes into the plan:** an answer that settles one (a value, a rule, what a
  criterion means) is given with `--into-plan` (D-476), which commits it into the plan
  first, so the reviewers and Feature QA read it too.
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
- **An open product question is settled when you find it** (D-453): a criterion no plan
  covers, a plan that says other than its requirement, a point a reviewer or critic
  leaves to the maintainer. A minor one goes into the plan on the item's branch at once,
  decided on the maintainer's behalf; one only they can decide goes to them at once,
  with a Slack mention. Never park it for "before WI-NNNN starts": nothing reminds the
  session, and it comes back as Feature QA's escalation on the critical path. One that
  truly can't be settled now is a `globuli note add "<text>" --link WI-NNNN`, which the
  brief shows each time, never a line in the session's own summary.
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

On a contributor's machine (a joined project, D-632) it is the same; they need push
access to the knowledge repo.

## Telling the maintainer

- **A person must act** (merge, decide, test, approve): chat alone gets missed, so also
  post to Slack with a mention:
  `globuli notify --mention "<text>"`.
  Say exactly what to do and when ("merge IvERP-knowledge#7 now: Stage 1 marked it
  ready"). Globuli's own alerts that wait for them carry the mention (D-200): repeat none.
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

**A `WASTE` line** is an agent's run that is going to waste, or a step that will pay
for one again: a step postponed or failed, the commit check reverting a run's paths,
a live run with a subagent started in the background (it ends the agent's turn,
D-432), or a live run whose transcript hasn't grown for 20 minutes. Act before the
retry is due:
- a step that failed after a long run passed: `globuli pause` at once, then read
  what the retry would do (the step's code) before resuming;
- a run on code with a fault already fixed (a reload pending, the run showing the
  fault): stop its CLI process. A stopped run is postponed, not counted as a failure.
  Only for a daemon that is this session's to run;
- a quiet run: read its transcript's end (a long build or test run is fine);
- a reverted path: check what the run's next turn does without it.
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
- **A correction from the maintainer is a rule for every driving session** (D-612):
  write it into this skill by a PR (`globuli-change`) the same day, with the date and
  what went wrong, not only into your own session's memory, which no other session
  or LLM reads.
- **"Keep quiet"** (while the maintainer runs a canary, say) (D-612): first stop every
  background task of your own (watchers, trains, pre-checks), or ask once before
  going silent if one must keep running; confirm in one line; then reply to nothing
  until they write again, and re-arm the watchers then. A message that reaches an
  open Claude Code session while the canary's hooks are planted can fail the canary:
  on 2026-11-05 three watchers ended during Doodle's canary and each reply went
  through.
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
