---
name: globuli-acceptance
description: Use when a release is to be accepted, that is when an acceptance round should start, is ready for the maintainer's testing, is being retested by the testers, has reported its bugs, has failed, or is to be cancelled.
---

# Release acceptance

Before a release ships, the maintainer tests its head by hand, Globuli's testers
retest what was not passed, and the notes and confirmed bugs go to Stage 1 and the
planner (D-199, D-225, D-228; `globuli docs orchestrator "Release acceptance"`). Globuli
runs all of it. The session checks, tells and unblocks.

## What a round is

- `acceptance-<release>-r<n>` (`acceptance-0.1.0-r2`): one release head, and one open
  round per release at a time. The next round tests all fixes since together.
- Its states: `preparing`, `ready-for-maintainer`, `machine-testing`, `reporting`,
  `done`, or `failed`. A superseded or a cancelled round is stored as `failed` and
  shown by its own name; so is a round still open when its release PR merged, which
  the poll closes as `released` (D-278).
- Two stacks from the head: the manual stack, the maintainer's, on the tailnet; and
  the QA stack, the testers', on localhost.
- Where it stands: `globuli_brief` and `globuli_status` show the release's latest round;
  `globuli_why` with the round's ID, or `release`, says what it waits for;
  `globuli_release` adds the release check in full and each open item. The page's
  link carries the round's token, so no tool gives it:
  `globuli acceptance <release> --status --project $GLOBULI_PROJECT` does.
- The commands here are the CLI's, `globuli` on the PATH, which finds the project and
  its roots by itself (D-592); in a source checkout of Globuli,
  `source tools/maintainer/env.sh` puts it on the PATH. `<release>` is `release-0.1.0`
  or `0.1.0`. The tool `globuli_acceptance` is switched off.

## How it starts

- **By itself.** The poll opens the draft release PR `release-X.Y.Z → main` once every
  work item is done, no planning is pending or running, no flaky test raised to High
  waits for a fix, and the latest release check passed on the head; then a round on
  that head. An open test fix holds neither (D-363): the brief says the release PR's
  merge waits for it. Not while Globuli is paused: the round starts at the first poll after the
  resume. Not while the last round's notes PR (or its follow-up) is open: its bugs are
  planned at that merge (D-621). An event says why there is none yet.
- **By hand.** `globuli acceptance <release> --start --project $GLOBULI_PROJECT`, or
  `/acceptance` on the release PR. It needs a green release check on the head and says
  so when there is none; `globuli release-check --run --project $GLOBULI_PROJECT` runs one.
- **`--start --any-head`** starts on a head that is not green: on the command line
  only, and only when the maintainer wants that build tested whatever its check says.
- No round starts while an ended round's step still runs or its clean-up is to come;
  the answer names what it waits for. While Globuli is paused the clean-up waits too.
- A round whose head the release has left, or whose head is no longer green, is closed
  as superseded before anything is prepared; the next opens by itself on the new green
  head. Nothing to do by hand.

## Before the maintainer is told

Globuli tells them itself when the round is ready: an `acceptance` alert with a
mention and a comment on the release PR give the page, the manual stack's app and mail
addresses, and how to finish. Before you add your word, check:

1. the round is `ready-for-maintainer`, on the head the release has now;
2. the page opens and lists the criteria, and the app and the mailbox answer at the
   addresses the alert gives;
3. the invitation to the maintainer is in the mailbox;
4. no stack started by hand holds the same names and ports
   (`globuli stack status`, and `globuli stack down`);
5. nothing heavy is to run on the machine while they test and the testers run.

**Chrome only.** The product is tested in Chrome, by the maintainer's decision. Do not
raise Safari or Firefox as a gap, and plan no work for them.

## The maintainer's part

- They open the page (it is phone-sized) and accept the invitation. Then "Seed the
  app again" on the page, or `/acceptance-seed` on the release PR, adds the demo data.
- They mark each criterion Pass, Fail or Skip, with a note where needed, and write
  general notes. Marks save as they go.
- They end with "Done testing" on the page or `/acceptance-done` on the release PR.
  For them, on their word only:
  `globuli acceptance <release> --done --project $GLOBULI_PROJECT`. A session's `--done`
  is refused by the auto-mode classifier without that word (Doodle 9.0.0, 2026-10-29):
  ask them, never work around it.
- **Bugs fixed by hand** don't go to a planner: mark each, before the round's notes PR
  merges, with `globuli acceptance <release> --handled-by <repo>#<n> --bug <N>[,<N>]…
  --project $GLOBULI_PROJECT` (D-474), the numbers as the round's note lists them. A notes
  PR whose change is built already: `globuli stage1 <notes-PR> --built-by <repo>#<n>…`
  (D-475).
- **No time to test now? Testers first (D-265).** "Start the testers now" on the page,
  or for them, on their word only:
  `globuli acceptance <release> --testers-now --project $GLOBULI_PROJECT`. The testers
  take what is not passed or noted so far, and the page keeps saving marks. Never
  answer "start the round, I'll test later" with `--done`: that closes their part and
  pushes their testing to the next round. A pass or fail they give while the testers
  have the criterion counts over the tester's verdict. If the testers finish first,
  their part of the report goes to the release PR once and the round waits for the
  maintainer: remind them, with the page, until they press "Done testing".
- The release moving while they test does not close the round: they are told once on
  the PR, and the next round opens after this one has reported or been cancelled.

## The testers

Every criterion not marked pass, and every one with a note, is retested: in groups by
requirement, each tester in its own Chrome, after the load gate, with 90 minutes. A
tester whose results judge every criterion of its group is done however its run ended
(D-215). One that writes no results runs once more; then its group fails and the
report says so. Keep the machine quiet meanwhile. Started early, they get what the
maintainer leaves unpassed or noted since once "Done testing" comes (D-265).

**When the testers report, read each group's line** (`globuli_why <round>`): what it
passed, partly passed, failed and blocked, and why. A group whose results block every
criterion tested nothing: it runs once more by itself, and if it does so again an
`acceptance` alert names it (D-362). A group with most of its criteria blocked for no
reason in the product (not a scheduled job, not a setup the stack lacks) failed too:
tell the maintainer at once, with the criteria and what testing them takes. Testers
have no subagents (D-361): on 2026-10-24 g2 of acceptance-0.2.0-r2 ended its turn to
wait for four, was asked for its verdict and tested none of its 69 criteria.

While a round's testers have work, no release check starts (D-266): the status says
"waits for <round>'s testers", and the check runs once they have reported, or after three
hours (`release_check.testers_first_max_minutes`) beside them, with an `acceptance` alert:
then ask why the testers aren't done (`globuli_why <round>`). Merges go on as usual. A check already running when the testers start runs to its end beside them.
`globuli release-check --run --project $GLOBULI_PROJECT` is not held: run it only if the
maintainer wants a check now and accepts the load.

## The report and the bugs

- When there is anything to note: a notes PR on `globulus/IvERP-knowledge`, branch
  `notes/acceptance-<release>-r<n>`, with the maintainer's notes verbatim and each
  confirmed bug with steps, expected and actual. A summary goes to the release PR and
  the digest channel. The QA stack goes down; the manual stack stays until the release
  PR is merged or closed.
- **The maintainer's other inputs for the round** (customer feedback, files): they go
  on the round's notes PR, so the bugs and the feedback are planned in one session.
  Every human push restarts Stage 1 after `stage1_debounce_minutes` (D-181): synthesizer,
  critic and re-check again, about $10–15 and half an hour. So, one push:
  - Write the note and commit the files on a branch before "Done testing". Text alone
    can go into the page's general notes instead: the report quotes it.
  - Read `prd/releases/<version>.md` (its Goal and "Explicitly not in this release")
    against the scope the inputs set, and edit it in the same commit. The file is the
    maintainer's, and Stage 1 only proposes changes to it, as a critic finding that
    costs a second pass.
  - Put the commit on the notes branch as soon as the report opens the PR.

  On IvERP-knowledge#12 (2026-10-23), two pushes each cost a pass: the feedback came 6 s
  after the synthesizer started, then a release-file line Stage 1 had proposed (W-027).
- Stage 1 reads the notes PR at once and comments when to merge. The merge is the
  maintainer's: tell them, with a mention, when Stage 1 has marked it ready and not
  before. Notes merged early route nothing until Stage 1's follow-up PR merges.
- At the merge each confirmed bug is routed, once (D-225): through a criteria change,
  when the round's notes plan one for a criterion it names; else to the planner as a
  finding to fix, in the same planning session as the changes; a bug that names no
  criterion goes through Stage 1's note alone. An event says how many went which way.
- When the session that had the bugs failed or was cancelled, its alert names the
  command: `globuli plan --findings <round> --project $GLOBULI_PROJECT`. It plans only
  the bugs that nothing fixes or plans now.
- **Every round that reports has a report page (D-421):** the acceptance page as the
  round ended, read only, with Feature QA's screenshots, the testers' verdicts and the
  bugs, in `<state root>/acceptance/<round>/report/`. `globuli watch` says `REPORT` until
  it is published: publish it as a Claude Artifact (`globuli-operate`, "Acceptance
  report"), record it with `globuli acceptance <X.Y.Z> --published <url>`, and give the
  maintainer the link.
- **Small fixes during a round are the session's** (the maintainer, 2026-10-15 and
  2026-10-23): a stale test, a label or a small bug on the release gets a PR from the
  release branch, the tests that cover it and a squash-merge, without the pipeline or
  asking first; then say what was merged. A release check's failure fixed this way gets
  `--handled-by` (`globuli-operate`). Scope, plan approvals, notes PRs, the release PR
  and anything large stay the maintainer's.
- Then `globuli-postmortem`: a snapshot at the end of the round, and the round in the
  write-up. That skill is the source checkout's: from an install, tell the maintainer
  the round ended, and record what went wrong in Globuli as observations.

## Releasing

- Merging the release PR is the maintainer's step, the release's last (D-283). When a
  round is done and the maintainer accepts the release, list "merge the release PR
  (yours; a session can't)" with its number; the brief's "needs the maintainer" says
  the same while the PR is open, also when an earlier round is done and the open one
  has no mark yet (they may accept from the earlier one).
- A session's permission check refuses `gh pr merge` on a release PR, and that is
  right: don't work around it (no other command, no API call, no hand-off to a
  subagent). Say it is theirs and wait.
- Once it is merged, the poll marks the version released and closes a round of it
  still open (D-278), unless its maintainer pressed "Done testing": that one reports.
  A closed round's failed criteria come as one alert, by ID.

## Cancelling

On the maintainer's word, since their marks are their work:
`globuli acceptance <release> --cancel --project $GLOBULI_PROJECT`, or
`/acceptance-cancel` on the release PR. In any state before the
report; `reporting` is too late. The round's agents stop within seconds, the daemon
takes the QA stack down at its next tick (after the resume, while paused), no notes PR
is opened, and the PR gets one comment. The marks stay on the page, which no longer
saves. A cancelled or a failed round's head gets no other round by itself: start one
by hand.

## When a round fails

The alert says which command of which stack failed, how it ended, and where its log is
on this machine (`~/.globuli/acceptance/<project>/<kind>-stack.log`). Nothing the
command printed is in the alert, on purpose (D-229): read the cause in the log, and
paste none of it anywhere, since a stack's output holds its secrets. For a checkout
that "was not moved", and for the other causes, see `globuli-recover`. Then start
another round.
