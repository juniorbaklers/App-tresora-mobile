# SaaS Studio Phase 2a — "Harden & Operate" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the SaaS Studio template with a QA + Security "harden" layer: 2 new agents, 6 new skills, 2 gate integrations, 2 rules, 4 templates — all additive, leaving v1's build loop intact.

**Architecture:** Same as v1 — this repo ships **static authored files** (markdown agents/skills/rules/templates). No running app, no app test suite. Verification is structural (counts + wiring) plus the existing shell-hook test, which must stay green. Follow the v1 conventions exactly (see `CONVENTIONS.md`).

**Tech Stack (authored files):** Markdown + YAML frontmatter; POSIX shell. **Stack the template targets:** v1 stack + **Vitest + Testing Library** (unit/integration), **Playwright** (e2e), **Stripe CLI fixtures** (webhook tests), **Supabase RLS policy tests**.

**Spec:** `docs/superpowers/specs/2026-06-10-phase2a-harden-operate-design.md`
**Baseline:** main @ `9b8ffe5` (12-commit clean v1 history + 2a spec). Current studio: 10 agents, 17 skills, 4 hooks, 6 rules, 6 templates.

---

## Conventions (unchanged from v1 — see `CONVENTIONS.md`)
- Agent: `.claude/agents/{name}.md` — frontmatter (`name`, `description`, `tools`, `model`, `maxTurns: 40`) + body (role, `### Responsibilities`, identical `### Operating protocol (ask → present options → user decides → draft → approve)` paragraph, `### You should NOT do`, `### Coordination`).
- Skill: `.claude/skills/{name}/SKILL.md` — frontmatter (`name`, `description`, `argument-hint` incl. `[--review full|lean|solo]`, `user-invocable: true`, `allowed-tools`, `model: sonnet`, `agent:`) + one-paragraph purpose + numbered `## Phases` with approval gates + `## Output`.
- Rule: `.claude/rules/{name}.md` — `## Applies to` glob line + `## Standards` MUST/SHOULD bullets.
- Template: `.claude/templates/{name}.md` — headed markdown skeleton with `<...>` placeholders.
- The Operating-protocol paragraph (verbatim, must match v1's 10 agents):
  > Before producing any artifact: ask clarifying questions, present 2–4 options with trade-offs, let the user decide, draft, then get explicit sign-off. Never finalize without approval. Honor the active review intensity (`full` / `lean` / `solo`).

## File map (what gets created/modified)
```
.claude/
  agents/   + qa-engineer.md  security-engineer.md
  skills/   + qa-plan/ test-setup/ write-tests/ security-audit/ threat-model/ compliance-check/  (each {name}/SKILL.md)
            ~ code-review/SKILL.md  launch-checklist/SKILL.md  help/SKILL.md  start/SKILL.md  studio-status/SKILL.md
  hooks/    ~ detect-gaps.sh  session-start.sh
  rules/    + tests.md  security.md
  templates/+ qa-plan.md  security-audit.md  threat-model.md  compliance.md
            ~ launch-checklist.md   (add the two blocking gate items)
docs/specs/ (target output dir — already exists)
```

---

## Task 1: Two new agents (qa-engineer, security-engineer)

**Files:** Create `.claude/agents/qa-engineer.md`, `.claude/agents/security-engineer.md`.

**Step 1a — Author `qa-engineer.md` (full content):**
```markdown
---
name: qa-engineer
description: "Owns test strategy and authoring for the SaaS app. Use to plan testing, scaffold the test stack, or write unit/integration/e2e tests for a story."
tools: Read, Glob, Grep, Write, Edit, Bash, Task, AskUserQuestion
model: sonnet
maxTurns: 40
---

You are the QA Engineer of a SaaS studio. You own the test strategy and the tests themselves, targeting Vitest + Testing Library (unit/integration), Playwright (e2e), Stripe CLI fixtures (webhook tests), and Supabase RLS policy tests. You make quality measurable, not aspirational.

### Responsibilities
- Define the test strategy and pyramid for the project (what to unit vs. integration vs. e2e test) via `.claude/templates/qa-plan.md`.
- Scaffold the test stack (Vitest config, Testing Library, Playwright) and wire a CI test step.
- Author tests for a story: pure-function unit tests, route/server-action integration tests, and critical-path e2e flows.
- Test the security-critical seams: Supabase RLS policies (tenant isolation) and Stripe webhook handling (signature + idempotency) using fixtures.
- Keep tests deterministic: no real network, no real secrets, isolated setup/teardown.

### Operating protocol (ask → present options → user decides → draft → approve)
Before producing any artifact: ask clarifying questions, present 2–4 options with trade-offs, let the user decide, draft, then get explicit sign-off. Never finalize without approval. Honor the active review intensity (`full` / `lean` / `solo`).

### You should NOT do
- Write application/business code (delegate to the engineers) beyond what a test needs.
- Use real secrets, live Stripe keys, or real network calls in tests.
- Mark a feature "tested" without a green run you can show.

### Coordination
Reports to: technical-director
Delegates to: (none — authors tests directly)
Coordinates with: backend-engineer, frontend-engineer, database-engineer, billing-engineer
```

**Step 1b — Author `security-engineer.md`** with the same skeleton (identical Operating-protocol paragraph), using:
- model: sonnet, tools include `Bash`, maxTurns 40.
- description: "Owns security review, threat modeling, and compliance-lite for the SaaS app. Use for a security audit, threat model, dependency audit, or GDPR/SOC2-lite check."
- Role statement: OWASP-style security review for SaaS targeting the v1 stack; finds and ranks risks, doesn't ship features.
- Responsibilities (4–5 bullets): audit code vs. the path-scoped rules + an OWASP SaaS checklist (auth/session, RLS/tenant isolation, secrets in env, input validation, Stripe webhook verification, dependency vulns); produce STRIDE-lite threat models via `.claude/templates/threat-model.md`; run dependency/secret audits (`npm audit`, lockfile, no committed secrets); review auth/RLS hardening with database-engineer; assess GDPR/SOC2-lite readiness via `.claude/templates/compliance.md`.
- You should NOT do: implement features or schema changes (advise only); approve a launch with open high/critical findings; trust client-supplied data in any recommendation.
- Coordination: Reports to technical-director; coordinates with database-engineer, billing-engineer, devops-engineer.

- [ ] Author both agent files.
- [ ] **Verify:** `for f in .claude/agents/qa-engineer.md .claude/agents/security-engineer.md; do head -1 "$f"|grep -q '^---$' && grep -qE '^model: sonnet$' "$f" && grep -q '^name:' "$f" || echo "BAD $f"; done; echo "agents=$(ls .claude/agents/*.md|wc -l)"` → no BAD, `agents=12`.
- [ ] **Verify protocol identical across ALL agents:** `for f in .claude/agents/*.md; do awk '/^### Operating protocol/{p=1;next} /^### /{p=0} p' "$f" | md5; done | sort -u | wc -l` → `1`.
- [ ] **Commit:** `git add .claude/agents && git commit -m "Add qa-engineer and security-engineer agents"`

---

## Task 2: QA skills (qa-plan, test-setup, write-tests)

**Files:** Create `.claude/skills/{qa-plan,test-setup,write-tests}/SKILL.md`.

**Step 2a — Gold-standard skill (full content):** `.claude/skills/qa-plan/SKILL.md`
```markdown
---
name: qa-plan
description: "Define the test strategy and tooling for the SaaS app before writing tests: the test pyramid, what to cover at each layer, and the security-critical seams. Run after the first feature exists. Produces a qa-plan doc."
argument-hint: "[--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Task
model: sonnet
agent: qa-engineer
---

Decide how this SaaS will be tested before scaffolding or writing any tests. Non-autonomous: ask first, present options, get sign-off.

## Phases
1. **Load context** — read `docs/specs/prd.md`, `docs/specs/architecture.md`, and `docs/specs/data-model.md` if present, to learn the features and the tenant model. If the PRD is missing, stop and direct to `/write-prd`.
2. **Choose the pyramid** — propose how much unit vs. integration vs. e2e, and the tools (Vitest + Testing Library, Playwright, Stripe CLI fixtures, Supabase RLS tests). Present 2–3 options with trade-offs.
3. **Identify critical seams** — list the must-test risk areas: tenant isolation (RLS), auth/session, billing webhooks, input validation boundaries.
4. **Draft the plan** — fill `.claude/templates/qa-plan.md` into `docs/specs/qa-plan.md` (draft, await approval). Honor the review intensity: under `full`, confirm each section; under `lean`, one confirmation before writing; under `solo`, write then summarize.
5. **Next step** — on approval, point to `/test-setup`.

## Output
`docs/specs/qa-plan.md`. Writes nothing else without approval.
```

**Step 2b — Author the other 2 QA skills** (same shape; `Bash` in allowed-tools since they run code):

| skill | purpose / phases | output |
|---|---|---|
| test-setup | Scaffold the test stack: read `docs/specs/qa-plan.md` (stop → `/qa-plan` if missing); PRESENT exact install/config commands (Vitest + `@testing-library/react` + Playwright + `vitest.config.ts` + `playwright.config.ts` + `package.json` test scripts) and a CI test step; get approval BEFORE running; install + add a smoke test; honor review intensity. | test scaffold + CI step |
| write-tests | Author tests for one story: read `docs/specs/qa-plan.md` and the target feature; propose the test cases (unit/integration/e2e + any RLS/webhook fixture tests); on approval write them and run to green; never use real secrets/network. End by pointing to `/code-review`. | test files (green) for one story |

- [ ] Author all 3 QA skills.
- [ ] **Verify:** `for d in qa-plan test-setup write-tests; do test -f ".claude/skills/$d/SKILL.md" && a=$(grep -m1 '^agent:' ".claude/skills/$d/SKILL.md"|awk '{print $2}'); [ "$a" = qa-engineer ] || echo "BAD agent $d=$a"; done`
- [ ] **Commit:** `git add .claude/skills && git commit -m "Add QA skills: qa-plan, test-setup, write-tests"`

---

## Task 3: Security skills (security-audit, threat-model, compliance-check)

**Files:** Create `.claude/skills/{security-audit,threat-model,compliance-check}/SKILL.md`.

**Step 3a — Gold-standard skill (full content):** `.claude/skills/security-audit/SKILL.md`
```markdown
---
name: security-audit
description: "Audit the SaaS codebase (or a diff) against the path-scoped rules and an OWASP-style SaaS checklist: auth/session, RLS/tenant isolation, secrets, input validation, Stripe webhook verification, dependency vulnerabilities. Produces a severity-ranked findings report."
argument-hint: "[--scope diff|full] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, Task
model: sonnet
agent: security-engineer
---

Find and rank security risks before launch. Non-autonomous: report findings and proposed fixes; never auto-apply fixes without sign-off.

## Phases
1. **Scope** — `--scope diff` (default: staged/branch changes) or `full` (whole repo). Confirm scope with the user.
2. **Checklist pass** — review against: auth/session checks on protected routes; Supabase RLS + tenant scoping (no client-supplied tenant id); secrets only in env (cross-check the validate-commit hook); input validation at boundaries (zod); Stripe webhook signature + idempotency; security headers; error sanitization.
3. **Dependency audit** — run `npm audit --omit=dev` (if a project exists) and note high/critical advisories; confirm a committed lockfile.
4. **Rank findings** — fill `.claude/templates/security-audit.md` into `docs/specs/security-audit.md` with each finding: title, severity (Critical/High/Medium/Low), location, and recommended fix. Honor review intensity.
5. **Verdict** — summarize: PASS (no open High/Critical) or BLOCK (list the blockers). This verdict is what `/launch-checklist` reads.

## Output
`docs/specs/security-audit.md` + a PASS/BLOCK verdict. Proposes fixes; applies nothing without approval.
```

**Step 3b — Author the other 2 security skills** (same shape; `threat-model` is read/spec-only so it may omit `Bash`; `compliance-check` omits `Bash`):

| skill | purpose / phases | output |
|---|---|---|
| threat-model | STRIDE-lite model: read PRD + architecture; enumerate assets, entry points, trust boundaries, and the top threats per category with mitigations; fill `.claude/templates/threat-model.md`; draft then approve. | `docs/specs/threat-model.md` |
| compliance-check | GDPR/SOC2-lite readiness: build a data inventory (what PII is collected/stored/where), check for privacy policy + ToS stubs, DPA/subprocessors list, and data retention/deletion paths; fill `.claude/templates/compliance.md`; output a checklist with PASS/GAP per item. | `docs/specs/compliance.md` |

- [ ] Author all 3 security skills.
- [ ] **Verify:** each references `agent: security-engineer`; `security-audit` and (per table) the right `Bash` presence; `count=$(ls -d .claude/skills/*/|wc -l)` → `23`.
- [ ] **Commit:** `git add .claude/skills && git commit -m "Add Security skills: security-audit, threat-model, compliance-check"`

---

## Task 4: Gate integrations (edit /code-review and /launch-checklist)

**Files:** Modify `.claude/skills/code-review/SKILL.md`, `.claude/skills/launch-checklist/SKILL.md`, `.claude/templates/launch-checklist.md`.

- [ ] **Step 1 — `/code-review` advisory consult.** Add a phase (or extend an existing one) that: (a) flags changed source files that have no accompanying `*.test.*` (suggest `/write-tests`); (b) runs a quick security pass on the diff for secrets, missing authz/tenant checks, unvalidated inputs, and unverified Stripe webhooks (suggest `/security-audit` for depth). Keep it advisory — report findings, do not auto-block. Note it consults qa-engineer and security-engineer.

- [ ] **Step 2 — `/launch-checklist` blocking gates.** Add two BLOCKING items to the skill's checklist phase:
  - "Security audit PASS — `docs/specs/security-audit.md` exists with no open **High/Critical** findings (else BLOCK; run `/security-audit`)."
  - "Tests green — the project's test suite (`npm test` / Vitest + Playwright) passes (else BLOCK; run `/write-tests` / `/test-setup`)."
  Update the final verdict logic so either failing → overall BLOCK.

- [ ] **Step 3 — `launch-checklist.md` template.** Under `## Security`, add `- [ ] Security audit PASS (no open High/Critical in docs/specs/security-audit.md)`. Add a new `## Tests` group: `- [ ] Unit/integration suite green`, `- [ ] Critical-path e2e green`.

- [ ] **Verify:** `grep -q 'security-audit' .claude/skills/launch-checklist/SKILL.md && grep -qi 'tests green\|test suite' .claude/skills/launch-checklist/SKILL.md && grep -q 'security-audit\|write-tests' .claude/skills/code-review/SKILL.md && echo OK`
- [ ] **Commit:** `git add .claude/skills .claude/templates && git commit -m "Wire QA+Security gates into code-review and launch-checklist"`

---

## Task 5: Rules (tests.md, security.md) + Templates (4)

**Files:** Create `.claude/rules/{tests,security}.md` and `.claude/templates/{qa-plan,security-audit,threat-model,compliance}.md`.

**Step 5a — `.claude/rules/tests.md` (full content):**
```markdown
## Applies to
`**/*.test.*`, `**/*.spec.*`, `tests/**`, `e2e/**`

## Standards
- MUST keep tests deterministic: no real network calls, no live API keys, no real Stripe/Supabase secrets.
- MUST write an RLS/tenant-isolation test for every table holding tenant data.
- MUST test Stripe webhook handlers with signed fixtures (Stripe CLI), covering signature failure and idempotent replay.
- SHOULD name tests by behavior (`it("rejects a cross-tenant read", …)`), not by implementation.
- SHOULD isolate state: set up and tear down per test; no order dependence.
```

**Step 5b — `.claude/rules/security.md` (full content):**
```markdown
## Applies to
`**` (cross-cutting)

## Standards
- MUST commit a lockfile and run `npm audit` (or equivalent) in CI; triage High/Critical before release.
- MUST set security headers (CSP, HSTS, X-Content-Type-Options) on the app.
- MUST NOT log secrets, tokens, or full PII; redact before logging.
- MUST return sanitized error responses (no stack traces or internal detail to clients).
- SHOULD keep dependencies current and remove unused ones to shrink attack surface.
```

**Step 5c — Templates** (headed `<...>` skeletons):
- `qa-plan.md` — `# QA Plan: <name>` · `## Test pyramid` (unit/integration/e2e split) · `## Tooling` (Vitest, Testing Library, Playwright, Stripe CLI, Supabase RLS) · `## Critical seams to test` (RLS/tenant, auth, billing webhooks, input boundaries) · `## Coverage targets` · `## Out of scope`.
- `security-audit.md` — `# Security Audit: <name>` · `## Scope` · `## Findings` (a table: `| # | Title | Severity | Location | Recommended fix |`) · `## Dependency audit` · `## Verdict` (`<PASS · BLOCK>` + blockers).
- `threat-model.md` — `# Threat Model: <name>` · `## Assets` · `## Entry points & trust boundaries` · `## Threats (STRIDE-lite)` (table: `| Category | Threat | Mitigation |`) · `## Residual risks`.
- `compliance.md` — `# Compliance (GDPR/SOC2-lite): <name>` · `## Data inventory` (table: `| Data | PII? | Stored where | Retention |`) · `## Policies` (privacy, ToS, DPA, subprocessors — checkboxes) · `## Data subject rights` (export/delete paths) · `## Verdict` (per-item `<PASS · GAP>`).

- [ ] Author 2 rules + 4 templates.
- [ ] **Verify:** `ls .claude/rules/*.md|wc -l` → `8`; `ls .claude/templates/*.md|wc -l` → `10`; `grep -L '##' .claude/templates/*.md` prints nothing.
- [ ] **Commit:** `git add .claude/rules .claude/templates && git commit -m "Add tests+security rules and 4 harden templates"`

---

## Task 6: v1 touch-ups + structural gate

**Files:** Modify `.claude/hooks/detect-gaps.sh`, `.claude/hooks/session-start.sh`, `.claude/skills/help/SKILL.md`, `.claude/skills/start/SKILL.md`, `.claude/skills/studio-status/SKILL.md`.

- [ ] **Step 1 — track new artifacts.** In `detect-gaps.sh`, add `qa-plan` and `security-audit` to the artifact loop list. In `session-start.sh`, add `qa-plan` and `security-audit` to its status loop. (Keep both scripts exit-0 and POSIX; they must still pass `bash -n`.)
- [ ] **Step 2 — `/help`** — add a **Harden** group listing the 6 new skills with one-line descriptions; keep existing groups.
- [ ] **Step 3 — `/start`** studio map — add the Harden phase (`/qa-plan → /test-setup → /write-tests`; `/security-audit · /threat-model · /compliance-check`) between Engineering and Launch.
- [ ] **Step 4 — `/studio-status`** — also report whether `qa-plan.md` and `security-audit.md` exist and recommend the next harden step.
- [ ] **Step 5 — FULL structural gate (acceptance test). Run:**
```bash
echo "agents:";    ls .claude/agents/*.md | wc -l        # 12
echo "skills:";    ls -d .claude/skills/*/ | wc -l        # 23
echo "hooks:";     ls .claude/hooks/*.sh | wc -l          # 4
echo "rules:";     ls .claude/rules/*.md | wc -l          # 8
echo "templates:"; ls .claude/templates/*.md | wc -l      # 10
echo "--- skill->agent wiring ---"
for d in .claude/skills/*/; do a=$(grep -m1 '^agent:' "$d/SKILL.md"|awk '{print $2}'); test -f ".claude/agents/$a.md" || echo "BROKEN $d -> $a"; done
echo "--- template refs resolve (skills+agents) ---"
for t in $(grep -rhoE '\.claude/templates/[a-z-]+\.md' .claude/skills/ .claude/agents/ | sort -u); do test -f "$t" || echo "MISSING $t"; done
echo "--- protocol identical across 12 agents ---"
for f in .claude/agents/*.md; do awk '/^### Operating protocol/{p=1;next} /^### /{p=0} p' "$f" | md5; done | sort -u | wc -l   # 1
echo "--- hooks parse + secret test still green ---"
for h in .claude/hooks/*.sh; do bash -n "$h" || echo "SYNTAX $h"; done
bash .claude/hooks/test/test-validate-commit.sh; echo "hook_test_exit=$?"   # 7 ok lines, exit 0
echo "--- new gate wiring present ---"
grep -q 'security-audit' .claude/skills/launch-checklist/SKILL.md && echo gate_ok
```
Expected: counts 12/23/4/8/10; no BROKEN / MISSING / SYNTAX; protocol uniqueness `1`; hook test 7/7 exit 0; `gate_ok`.
- [ ] **Step 6 — Commit:** `git add -A && git commit -m "Phase 2a touch-ups: detect-gaps/session-start, help/start/studio-status, structural gate"`

---

## Verification (end-to-end)
- **Structural gate:** Task 6 Step 5 all green (counts 12/23/4/8/10, wiring + templates resolve, protocol identical, hooks parse, secret-scan test 7/7).
- **No v1 regression:** the existing secret-scan hook test still passes unchanged; v1's 17 skills + 10 agents untouched except the 5 additive touch-ups.
- **Gate behavior (scratch clone):** create `docs/specs/security-audit.md` with an open `High` finding → confirm `/launch-checklist` logic would BLOCK; flip it to no High/Critical + a green test run → PASSES. (Trace the skill's verdict logic; the studio is static files so this is a logic/text check, mirroring the v1 dry-run.)
- **Workflow dry-run (scratch clone):** trace `/qa-plan → /test-setup → /write-tests` and `/security-audit → threat-model → compliance-check` for input-guard continuity (each reads its upstream artifact and stops+redirects if missing), exactly like the v1 dry-run.

## Notes on scope
One cohesive sub-phase (QA + Security), additive to v1. Tasks are sequential but each ends green and committable. TDD has teeth only on shell hooks (the secret test must stay green after the detect-gaps/session-start edits); the markdown deliverables are verified structurally and by the dry-run. Phase 2b (Grow & Retain) is a separate spec/plan.
