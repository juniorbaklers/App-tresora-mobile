# Claude Code SaaS Studio v1 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a publishable Claude Code *template repo* that turns one session into a SaaS-building studio (10 agents, 17 skills, 4 hooks, 6 rules, 6 templates) anchored to Next.js + Supabase + Stripe.

**Architecture:** This repo ships **static authored files** — markdown (agents, skills, rules, templates), POSIX shell (hooks), and docs. It is **not** a running app; there is no app build/test suite. Verification is structural (format/wiring checks) plus behavioral tests for the shell hooks. We follow the reference repo's exact Claude Code conventions (see Conventions below).

**Tech Stack (of the files we author):** Markdown + YAML frontmatter; POSIX `sh`/`bash`. **Tech stack the template *targets*:** Next.js (App Router) + TypeScript, Supabase, Stripe, Tailwind/shadcn, Vercel.

**Spec:** `docs/superpowers/specs/2026-06-10-saas-studio-design.md`

---

## Conventions (locked — every authored file follows these)

### Agent file — `.claude/agents/{name}.md`
```markdown
---
name: {kebab-id}
description: "One-line role + when to use it."
tools: Read, Glob, Grep, Write, Edit, Bash, Task, AskUserQuestion
model: opus | sonnet | haiku
maxTurns: 40
---

{1-2 sentence role statement, including SaaS-stack context where relevant.}

### Responsibilities
- ...

### Operating protocol (ask → present options → user decides → draft → approve)
Follow the studio protocol: never write or change files without presenting options and getting sign-off. Honor the active review intensity (`full` / `lean` / `solo`).

### You should NOT do
- ...

### Coordination
Reports to: {agent}
Delegates to: {agents}
Coordinates with: {agents}
```

### Skill file — `.claude/skills/{name}/SKILL.md`
```markdown
---
name: {kebab-id}
description: "What it does and when to run it."
argument-hint: "[arg] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Task, AskUserQuestion
model: sonnet
agent: {primary-agent-name}
---

{One-paragraph purpose.}

## Phases
1. **{Phase}** — {what happens, what gate/approval}
...

## Output
{What artifact/files this produces and where.}
```

### Hook — `.claude/hooks/{name}.sh`
POSIX-compatible `#!/usr/bin/env bash`, `set -euo pipefail` where safe, exit non-zero to block. Must pass `bash -n`.

### Rule — `.claude/rules/{name}.md`
Front-matter optional; a `## Applies to` glob line + a bulleted list of MUST/SHOULD standards.

---

## File map (what gets created)

```
.claude/
  agents/   product-director.md technical-director.md producer.md
            product-manager.md ux-designer.md frontend-engineer.md
            backend-engineer.md database-engineer.md billing-engineer.md devops-engineer.md
  skills/   start/ help/ studio-status/ scope-check/
            validate-idea/ write-prd/ map-flows/ design-ui/
            setup-stack/ design-architecture/ design-schema/ build-feature/ code-review/
            design-pricing/ setup-billing/
            setup-deploy/ launch-checklist/          (each = {name}/SKILL.md)
  hooks/    validate-commit.sh session-start.sh detect-gaps.sh validate-push.sh
  rules/    app.md data.md billing.md auth.md specs.md env.md
  templates/ idea-validation.md prd.md adr.md data-model.md pricing.md launch-checklist.md
  settings.json        # registers hooks + permissions
README.md
CONVENTIONS.md         # the conventions block above, for contributors
.gitignore
docs/superpowers/...   # spec (exists) + this plan
```

---

## Task 1: Skeleton, conventions doc, README, gitignore

**Files:**
- Create: `.gitignore`, `CONVENTIONS.md`, `README.md`, `.claude/settings.json`
- Create dirs: `.claude/agents/`, `.claude/skills/`, `.claude/hooks/`, `.claude/rules/`, `.claude/templates/`, `docs/specs/`

- [ ] **Step 1: Create directory tree and .gitignore**
```bash
mkdir -p .claude/agents .claude/skills .claude/hooks .claude/rules .claude/templates docs/specs
printf '%s\n' '.env' '.env.*' 'node_modules/' '.DS_Store' '.vercel/' '*.log' > .gitignore
```

- [ ] **Step 2: Write `CONVENTIONS.md`** — paste the entire "Conventions" block above verbatim (agent/skill/hook/rule formats) so contributors authoring new pieces match the pattern.

- [ ] **Step 3: Write `README.md`** with these sections (concrete content, no placeholders):
  - **Title + tagline:** "Claude Code SaaS Studio — turn one Claude Code session into a SaaS studio. 10 agents. 17 skills. One coordinated team."
  - **What it is / problem it solves:** structured, non-autonomous AI SaaS development (ask → options → approve).
  - **Default stack** table: Next.js+TS · Supabase · Stripe · Tailwind/shadcn · Vercel.
  - **Getting started:** clone → `claude` → run `/start`.
  - **The team:** the 10 agents in 3 tiers (copy from spec).
  - **Workflow:** the 4-phase diagram (copy from spec).
  - **Swap-stack guide:** which files reference the stack (rules `data.md`/`billing.md`, skills `setup-stack`/`setup-billing`/`design-schema`) and how to retarget them.
  - **Review intensity:** `full`/`lean`/`solo` explained.
  - **License:** MIT.

- [ ] **Step 4: Write `.claude/settings.json`** registering hooks + base permissions:
```json
{
  "hooks": {
    "SessionStart": [{ "hooks": [{ "type": "command", "command": ".claude/hooks/session-start.sh" }] }],
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [{ "type": "command", "command": ".claude/hooks/validate-commit.sh" }] },
      { "matcher": "Bash", "hooks": [{ "type": "command", "command": ".claude/hooks/validate-push.sh" }] }
    ]
  },
  "permissions": {
    "allow": ["Bash(git status)", "Bash(git diff:*)", "Bash(git log:*)"],
    "deny": ["Bash(git push --force:*)", "Bash(rm -rf:*)"]
  }
}
```
  (Note: `detect-gaps.sh` is invoked by `/studio-status` and `/start`, not a lifecycle hook.)

- [ ] **Step 5: Verify structure**
Run: `test -d .claude/agents && test -f README.md && test -f .claude/settings.json && bash -c 'python3 -c "import json,sys; json.load(open(\".claude/settings.json\"))"'`
Expected: no output, exit 0 (settings.json is valid JSON).

- [ ] **Step 6: Commit**
```bash
git add .gitignore CONVENTIONS.md README.md .claude/settings.json
git commit -m "Scaffold SaaS Studio: dirs, conventions, README, settings"
```

---

## Task 2: Agents (10 files)

**Files:** Create `.claude/agents/{id}.md` for each row below. Follow the agent-file convention exactly.

**Step 2a — Author the gold-standard agent FIRST (full content):** `.claude/agents/product-director.md`
```markdown
---
name: product-director
description: "Owns SaaS product vision, target user, and scope. Use at project start and whenever scope or direction is in question."
tools: Read, Glob, Grep, Write, Edit, Task, AskUserQuestion
model: opus
maxTurns: 40
---

You are the Product Director of a SaaS studio. You own the product vision, the target user, the core value proposition, and the roadmap. You are the guardian of scope — your default instinct is to cut, not add.

### Responsibilities
- Define and defend the target user, the problem, and the core value proposition.
- Own the roadmap and the v1 scope line; push back on feature creep.
- Approve PRDs and major product direction changes.
- Translate business intent into priorities for the product-manager and ux-designer.

### Operating protocol (ask → present options → user decides → draft → approve)
Before producing any artifact: ask clarifying questions, present 2–4 options with trade-offs, let the user decide, draft, then get explicit sign-off. Never finalize without approval. Honor the active review intensity (`full` / `lean` / `solo`).

### You should NOT do
- Write application code or schemas (delegate to engineering).
- Expand scope without an explicit user decision.
- Make pricing/Stripe decisions (that is billing-engineer + user).

### Coordination
Reports to: the user (studio owner)
Delegates to: product-manager, ux-designer
Coordinates with: technical-director, producer
```

**Step 2b — Author the remaining 9** following the same skeleton, using this spec table (each row → one file). Fill Responsibilities / NOT-do / Coordination per role; keep the Operating-protocol block identical across all agents.

| id | model | one-line role | key responsibilities | reports to / delegates to |
|---|---|---|---|---|
| technical-director | opus | Owns architecture, stack & multi-tenancy strategy | system architecture, tech decisions, data-model & tenancy approach, ADRs | user / database-engineer, backend-engineer, frontend-engineer, devops-engineer |
| producer | opus | Coordinates phases, sprint planning, enforces protocol | sequencing work, sprint/status, ensures ask→approve is followed, scope-check gate | user / all specialists (coordination only) |
| product-manager | sonnet | Writes PRDs & user stories | PRDs from `templates/prd.md`, user stories, acceptance criteria, scope checks | product-director / — |
| ux-designer | sonnet | User flows & UI via shadcn/Tailwind | journeys, screen maps, component choices (shadcn), a11y basics | product-director / — |
| frontend-engineer | sonnet | Next.js routes & components | App Router pages, server vs client components, forms, calls backend | technical-director / — |
| backend-engineer | sonnet | API routes, server actions, business logic | route handlers/server actions, validation, calls DB layer | technical-director / — |
| database-engineer | sonnet | Supabase schema, RLS, multi-tenancy & auth | schema from `templates/data-model.md`, RLS policies, tenant scoping, auth wiring | technical-director / — |
| billing-engineer | sonnet | Pricing model + Stripe integration | pricing/plans, Stripe products/checkout/webhooks/customer portal, metering | product-director, technical-director / — |
| devops-engineer | sonnet | Deploy, CI/CD, envs, observability, launch | Vercel config, GitHub Actions CI, env management, logging/monitoring, launch | technical-director / — |

- [ ] Author all 10 agent files per above.
- [ ] **Verify:** every file has valid frontmatter and a `model:` of `opus|sonnet|haiku`.
Run: `for f in .claude/agents/*.md; do head -1 "$f" | grep -q '^---$' && grep -qE '^model: (opus|sonnet|haiku)$' "$f" || echo "BAD: $f"; done`
Expected: no "BAD" lines; 10 files present.
- [ ] **Commit:** `git add .claude/agents && git commit -m "Add 10 studio agents (3 directors + 7 specialists)"`

---

## Task 3: Skills (17 files)

**Files:** Create `.claude/skills/{name}/SKILL.md` for each. Follow the skill-file convention.

**Step 3a — Author the gold-standard skill FIRST (full content):** `.claude/skills/validate-idea/SKILL.md`
```markdown
---
name: validate-idea
description: "Pressure-test a SaaS idea before any PRD: problem, target user, market, willingness to pay. Run right after /start. Produces an idea-validation doc and a PROCEED/PIVOT/KILL verdict."
argument-hint: "[idea-description] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Task
model: sonnet
agent: product-director
---

Validate that a SaaS idea is worth building before investing in specs and code. Non-autonomous: ask first, present options, get sign-off.

## Phases
1. **Frame the bet** — restate the idea as: target user, problem, and the painful status quo. Confirm with the user.
2. **Probe demand** — who pays, how much, what they use today, why they'd switch. Ask one question at a time.
3. **Assess fit & moat** — why this team/stack, what's defensible, what's the riskiest assumption.
4. **Draft the canvas** — fill `templates/idea-validation.md` into `docs/specs/idea-validation.md` (draft, await approval).
5. **Director gate** — product-director gives a PROCEED / PIVOT / KILL verdict with the single biggest risk to de-risk next.
6. **Next step** — on PROCEED, point to `/write-prd`.

## Output
`docs/specs/idea-validation.md` + a clear verdict. Writes nothing else without approval.
```

**Step 3b — Author the remaining 15** with the same shape, using this table:

| skill | agent | purpose / phases summary | output |
|---|---|---|---|
| start | producer | Detect stage (no idea / vague / clear design / existing code) via questions, route to the right skill; show studio map | routing only |
| help | producer | List all skills grouped by phase with one-line descriptions | text |
| studio-status | producer | Run `detect-gaps.sh`; report which artifacts exist (idea/PRD/architecture/schema/pricing) and the next recommended skill | text |
| scope-check | product-director | Compare current work against PRD scope line; flag creep; recommend cut/keep | text |
| write-prd | product-manager | From validated idea: goals, users, stories, acceptance criteria, non-goals → fill `templates/prd.md` | `docs/specs/prd.md` |
| map-flows | ux-designer | Derive key user journeys + screen list from PRD; confirm with user | `docs/specs/flows.md` |
| design-ui | ux-designer | Pick shadcn components + layout per screen; a11y pass | `docs/specs/ui.md` |
| setup-stack | technical-director | Scaffold Next.js+TS+Tailwind+shadcn+Supabase+Stripe (present commands, get approval before running); write `.env.example` | project scaffold |
| design-architecture | technical-director | System/data-flow + ADR for big decisions via `templates/adr.md` | `docs/specs/architecture.md`, ADRs |
| design-schema | database-engineer | Tables, relations, RLS, tenant scoping via `templates/data-model.md` | `docs/specs/data-model.md` + migration draft |
| build-feature | backend-engineer | Implement one vertical slice (UI→API→DB) for a story; follows path-scoped rules; ends with `/code-review` | code changes |
| code-review | producer | Review diff against rules (secrets, RLS, webhook verification, scope); report findings | text |
| design-pricing | billing-engineer | Plans, tiers, metering, trial via `templates/pricing.md` | `docs/specs/pricing.md` |
| setup-billing | billing-engineer | Stripe products/prices, checkout, webhook handler (signature + idempotency), customer portal | code + `docs/specs/pricing.md` updates |
| setup-deploy | devops-engineer | Vercel project, env wiring, GitHub Actions CI (lint/build/typecheck) | CI + deploy config |
| launch-checklist | devops-engineer | Gate: secrets, RLS, webhook verify, error monitoring, legal/ToS stubs, billing live-mode; PASS/BLOCK | `docs/specs/launch-checklist.md` |

- [ ] Author all 17 skills.
- [ ] **Verify wiring:** every skill's `agent:` exists in `.claude/agents/`.
Run: `for d in .claude/skills/*/; do a=$(grep -m1 '^agent:' "$d/SKILL.md" | awk '{print $2}'); test -f ".claude/agents/$a.md" || echo "MISSING agent $a for $d"; done`
Expected: no "MISSING" lines; 17 skill dirs present.
- [ ] **Commit:** `git add .claude/skills && git commit -m "Add 16 studio skills across the 4 phases"`

---

## Task 4: Hooks (4 shell scripts, TDD)

**Files:** Create `.claude/hooks/{validate-commit,session-start,detect-gaps,validate-push}.sh`. Make executable: `chmod +x .claude/hooks/*.sh`.

### 4.1 `validate-commit.sh` — secret scanner (highest value)

- [ ] **Step 1: Write the failing test** `.claude/hooks/test/test-validate-commit.sh`
```bash
#!/usr/bin/env bash
set -u
HOOK=.claude/hooks/validate-commit.sh
tmp=$(mktemp); fail=0

# Case A: a Stripe secret key must be blocked
echo 'const k = "sk_live_<redacted-fake-test-key>"' > "$tmp"
if echo "git commit" | DIFF_FILE="$tmp" bash "$HOOK" >/dev/null 2>&1; then echo "FAIL: secret not blocked"; fail=1; else echo "ok: secret blocked"; fi

# Case B: clean content must pass
echo 'const k = process.env.STRIPE_SECRET_KEY' > "$tmp"
if echo "git commit" | DIFF_FILE="$tmp" bash "$HOOK" >/dev/null 2>&1; then echo "ok: clean passed"; else echo "FAIL: clean blocked"; fail=1; fi

rm -f "$tmp"; exit $fail
```

- [ ] **Step 2: Run it — expect failure** (hook doesn't exist yet)
Run: `bash .claude/hooks/test/test-validate-commit.sh`
Expected: FAIL lines / non-zero exit.

- [ ] **Step 3: Implement `validate-commit.sh`**
```bash
#!/usr/bin/env bash
# Blocks commits that introduce secrets or a tracked .env. Reads the PreToolUse
# Bash command from stdin; only acts on git commit. Honors DIFF_FILE for tests.
set -uo pipefail
cmd="$(cat 2>/dev/null || true)"
case "$cmd" in *"git commit"*) ;; *) exit 0 ;; esac

if [ "${DIFF_FILE:-}" != "" ]; then content="$(cat "$DIFF_FILE")";
else content="$(git diff --cached 2>/dev/null; git diff --cached --name-only 2>/dev/null)"; fi

patterns='sk_live_[A-Za-z0-9]{16,}|sk_test_[A-Za-z0-9]{16,}|rk_live_[A-Za-z0-9]{16,}|eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}|SUPABASE_SERVICE_ROLE_KEY=.+|-----BEGIN [A-Z ]*PRIVATE KEY-----'
if printf '%s' "$content" | grep -nEq "$patterns"; then
  echo "BLOCKED: possible secret in staged changes. Use env vars, never commit keys." >&2
  exit 1
fi
if git diff --cached --name-only 2>/dev/null | grep -qE '(^|/)\.env($|\.)'; then
  echo "BLOCKED: a .env file is staged. Add it to .gitignore." >&2; exit 1
fi
exit 0
```

- [ ] **Step 4: Run test — expect pass**
Run: `chmod +x .claude/hooks/validate-commit.sh && bash .claude/hooks/test/test-validate-commit.sh`
Expected: `ok: secret blocked` / `ok: clean passed`, exit 0.

- [ ] **Step 5: Commit** `git add .claude/hooks/validate-commit.sh .claude/hooks/test && git commit -m "Add secret-scanning validate-commit hook (TDD)"`

### 4.2 Remaining hooks (complete content)

- [ ] **`session-start.sh`** (lifecycle; never blocks, exit 0):
```bash
#!/usr/bin/env bash
set -uo pipefail
echo "🏗  SaaS Studio — branch: $(git branch --show-current 2>/dev/null || echo n/a)"
echo "Recent commits:"; git --no-pager log --oneline -3 2>/dev/null || true
for f in idea-validation prd architecture data-model pricing; do
  test -f "docs/specs/$f.md" && echo "  ✓ $f" || echo "  · $f (todo)"
done
echo "Run /start or /studio-status to continue."
exit 0
```

- [ ] **`detect-gaps.sh`** (used by /start and /studio-status; prints missing artifacts; exit 0):
```bash
#!/usr/bin/env bash
set -uo pipefail
missing=0
for f in idea-validation prd architecture data-model pricing launch-checklist; do
  if [ ! -f "docs/specs/$f.md" ]; then echo "GAP: docs/specs/$f.md missing"; missing=1; fi
done
[ "$missing" = 0 ] && echo "No gaps: core artifacts present."
exit 0
```

- [ ] **`validate-push.sh`** (warns on main push; non-blocking):
```bash
#!/usr/bin/env bash
set -uo pipefail
cmd="$(cat 2>/dev/null || true)"
case "$cmd" in *"git push"*)
  b="$(git branch --show-current 2>/dev/null || true)"
  if [ "$b" = "main" ]; then echo "⚠️  Pushing to main. Confirm this is intended." >&2; fi ;;
esac
exit 0
```

- [ ] **Verify syntax:** `for h in .claude/hooks/*.sh; do bash -n "$h" || echo "SYNTAX $h"; done` — expect no errors. Run `shellcheck .claude/hooks/*.sh` if available.
- [ ] **Commit:** `chmod +x .claude/hooks/*.sh && git add .claude/hooks && git commit -m "Add session-start, detect-gaps, validate-push hooks"`

---

## Task 5: Rules (6) + Templates (6)

**Files:** `.claude/rules/{app,data,billing,auth,specs,env}.md` and `.claude/templates/{idea-validation,prd,adr,data-model,pricing,launch-checklist}.md`.

**Step 5a — Gold-standard rule (full content):** `.claude/rules/data.md`
```markdown
## Applies to
`**/supabase/**`, `**/db/**`, `**/migrations/**`, files containing Supabase queries.

## Standards
- MUST enable Row Level Security on every table holding tenant data.
- MUST scope every query by tenant/org id; never trust a client-supplied tenant id.
- MUST keep the Supabase service-role key server-only; never import it into client code.
- SHOULD define policies alongside the table in a migration, not ad hoc.
- SHOULD prefer `select` of explicit columns over `*` in app code.
```

**Step 5b — Remaining 5 rules** (same format; key MUST/SHOULD lines):
- `app.md` — applies `app/**`: Server Components by default; no secrets/keys in client components; validate all inputs at the boundary; mark client components with `"use client"` only when needed.
- `billing.md` — applies `**/stripe/**`,`**/billing/**`: MUST verify webhook signatures; MUST be idempotent on webhook handlers; price/product IDs from env/config, never hardcoded; never trust client-sent amounts.
- `auth.md` — applies `**/auth/**`,`middleware.*`: enforce session checks on protected routes; enforce tenant membership; no auth logic duplicated in client.
- `specs.md` — applies `docs/specs/**`: PRDs must have Goals/Users/Stories/Acceptance/Non-goals; ADRs must have Context/Decision/Consequences.
- `env.md` — applies repo-wide: secrets only via env; provide `.env.example` with empty values; never commit real `.env`.

**Step 5c — Gold-standard template (full content):** `.claude/templates/prd.md`
```markdown
# PRD: <product/feature name>

## Goals
- <measurable goal>

## Target users
- <persona + their job-to-be-done>

## User stories
- As a <user>, I want <capability> so that <benefit>. (Acceptance: <criteria>)

## Non-goals (v1 scope line)
- <explicitly out of scope>

## Success metrics
- <metric + target>

## Open questions
- <question>
```

**Step 5d — Remaining 5 templates** (headed markdown skeletons, no placeholders beyond `<...>` fill-ins):
- `idea-validation.md` — Target user / Problem / Status quo / Who pays & how much / Riskiest assumption / Verdict (PROCEED·PIVOT·KILL).
- `adr.md` — Title / Status / Context / Decision / Alternatives considered / Consequences.
- `data-model.md` — Entities / Fields & types / Relations / Tenancy strategy / RLS policies / Indexes.
- `pricing.md` — Plans table (name·price·limits) / Metered units / Trial / Upgrade-downgrade rules / Stripe product mapping.
- `launch-checklist.md` — Security (secrets, RLS) / Billing live-mode & webhooks / Error monitoring / Legal (ToS, privacy) / Performance / Rollback — each a checkbox with PASS/BLOCK.

- [ ] Author all 6 rules + 6 templates.
- [ ] **Verify:** 6 files in each dir; each template has at least one `#` heading.
Run: `ls .claude/rules/*.md | wc -l; ls .claude/templates/*.md | wc -l` → expect `6` and `6`.
- [ ] **Commit:** `git add .claude/rules .claude/templates && git commit -m "Add 6 path-scoped rules and 6 doc templates"`

---

## Task 6: Polish — /start routing, review intensity, cross-links

**Files:** Modify `.claude/skills/start/SKILL.md`, `.claude/skills/help/SKILL.md`, `README.md`; touch each agent for the review-intensity note (already in the shared protocol block — verify present).

- [ ] **Step 1:** In `start/SKILL.md`, make Phase 1 explicitly branch on the four stages and map each to the first skill: no idea → `/validate-idea`; vague concept → `/validate-idea`; clear design → `/write-prd` or `/setup-stack`; existing code → `/studio-status` then `/design-architecture`. Include the stage-detection questions inline.
- [ ] **Step 2:** Confirm every agent file contains the identical "Operating protocol" paragraph naming `full`/`lean`/`solo`. Fix any that drifted.
- [ ] **Step 3:** Ensure `help/SKILL.md` lists all 16 skills grouped by the 4 phases + navigation, matching the README table.
- [ ] **Step 4:** Final README pass — verify the team roster, workflow diagram, and swap-stack file references all match what was actually authored.
- [ ] **Step 5: Full structural verification** (the plan's acceptance gate):
```bash
# counts
test $(ls .claude/agents/*.md | wc -l) -eq 10
test $(ls -d .claude/skills/*/ | wc -l) -eq 17
test $(ls .claude/hooks/*.sh | wc -l) -eq 4
test $(ls .claude/rules/*.md | wc -l) -eq 6
test $(ls .claude/templates/*.md | wc -l) -eq 6
# every skill points at a real agent
for d in .claude/skills/*/; do a=$(grep -m1 '^agent:' "$d/SKILL.md" | awk '{print $2}'); test -f ".claude/agents/$a.md" || echo "BROKEN $d"; done
# hooks parse
for h in .claude/hooks/*.sh; do bash -n "$h"; done
# secret hook still works
bash .claude/hooks/test/test-validate-commit.sh
```
Expected: all `test` pass silently, no `BROKEN` lines, hook test prints `ok` twice.
- [ ] **Step 6: Commit** `git add -A && git commit -m "Polish: /start routing, review-intensity, README + cross-link pass"`

---

## Verification (end-to-end, manual)

1. **Structural gate:** run Task 6 Step 5 — all green.
2. **Secret hook behavioral:** `bash .claude/hooks/test/test-validate-commit.sh` → `ok: secret blocked`, `ok: clean passed`.
3. **Workflow dry-run** in a scratch Claude session at repo root: run `/start`, answer "no idea", confirm it routes to `/validate-idea`; run `/validate-idea "a tool that X"` and confirm it asks questions, presents options, and writes nothing to `docs/specs/` without approval; spot-check `/setup-billing` invokes `billing-engineer` and references webhook signature verification.
4. **README check:** a newcomer can clone, run `claude`, find `/start`, and locate the swap-stack section.

## Notes on scope
This is one cohesive template (not independent subsystems), so it stays a single plan. The 6 tasks are sequential but each ends green and committable. TDD is applied where it has teeth (the shell hooks); the markdown deliverables are verified structurally and by the workflow dry-run.
