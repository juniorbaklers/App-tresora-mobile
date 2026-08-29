# SaaS Studio Phase 2a — "Harden & Operate" Design Spec

**Date:** 2026-06-10
**Status:** Approved
**Builds on:** [v1 design](2026-06-10-saas-studio-design.md)

## Context

v1 shipped a focused idea→ship studio (10 agents, 17 skills, 4 hooks, 6 rules, 6 templates) and is release-ready.
Phase 2 broadens the studio into the "run & grow" half of a SaaS company. Because that spans ~4 independent
subsystems, it is split into two independently-shippable sub-phases:

- **Phase 2a — "Harden & Operate"** (this spec): QA & Testing + Security & Compliance.
- **Phase 2b — "Grow & Retain"** (queued): Growth/Marketing/Analytics + Support/Live-ops.

2a is the natural follow-on to ship/launch: it makes what v1 produces **trustworthy** (tested) and **safe**
(audited). It is purely additive — v1's build loop stays intact.

### Locked decisions
- **Integration depth:** *hybrid* — new capabilities are standalone on-demand skills, wired into exactly **two
  gate points** (`/code-review` consults them; `/launch-checklist` blocks without them). v1's `/build-feature`
  stays largely untouched.
- **Opinionated test/security stack** (mirrors v1's stance): **Vitest + Testing Library** (unit/integration),
  **Playwright** (e2e), **Stripe CLI fixtures** (webhook tests), **Supabase RLS policy tests**; security anchored
  on **OWASP-style review for SaaS + dependency/secret audit + GDPR/SOC2-lite checklist**.
- Same studio conventions, non-autonomous protocol (ask → present → user decides → draft → approve), and
  `--review full|lean|solo` intensity as v1.

## New agents — 2 (Sonnet) → 12 total
- `qa-engineer` — test strategy, scaffolding, and authoring across Vitest/Testing Library/Playwright; Stripe CLI
  webhook fixtures; Supabase RLS policy tests. Reports to technical-director; coordinates with backend-engineer,
  frontend-engineer, database-engineer.
- `security-engineer` — OWASP-style security review for SaaS, threat modeling, dependency/secret audit depth,
  auth/RLS hardening review, GDPR/SOC2-lite compliance. Reports to technical-director; coordinates with
  database-engineer, billing-engineer, devops-engineer.

## New skills — 6 → 23 total
Slot in after `/build-feature`/`/code-review` and before `/launch-checklist` (the "Harden" phase).

| Phase | Skill | Agent | Purpose / output |
|---|---|---|---|
| QA | `/qa-plan` | qa-engineer | Define test strategy, pyramid, and tooling for the project → `docs/specs/qa-plan.md` |
| QA | `/test-setup` | qa-engineer | Scaffold Vitest + Testing Library + Playwright + test scripts + CI step; present commands, approve, then run |
| QA | `/write-tests` | qa-engineer | Author unit/integration/e2e tests for a given story, following the qa-plan; run them green |
| Security | `/security-audit` | security-engineer | Audit diff/codebase vs path-scoped rules + OWASP SaaS checklist (auth, RLS, secrets, input validation, webhook verification, deps) → `docs/specs/security-audit.md` with severity-ranked findings |
| Security | `/threat-model` | security-engineer | STRIDE-lite: assets, entry points, trust boundaries, mitigations → `docs/specs/threat-model.md` |
| Security | `/compliance-check` | security-engineer | GDPR/SOC2-lite readiness: data inventory, privacy policy, DPA/subprocessors, retention/deletion → `docs/specs/compliance.md` |

All keep the non-autonomous protocol and `--review` intensity. QA skills that run code include `Bash` in
`allowed-tools`; pure spec skills omit it.

## Gate integrations (the hybrid wiring — minimal edits to v1)
- **`/code-review`** (producer) — also consults qa-engineer + security-engineer: flag changed code lacking
  accompanying tests, and run a quick security pass on the diff (secrets, authz, input validation, webhook
  verification). Advisory: reports, does not auto-block.
- **`/launch-checklist`** (devops-engineer) — gains two **blocking** items: a passing `/security-audit` (no open
  high/critical findings) and a green test run. This is where quality is enforced. Update both the skill and
  `.claude/templates/launch-checklist.md`.

## New rules — 2 → 8 total
- `tests.md` — applies to `**/*.test.*`, `tests/**`, `e2e/**`: test naming; no real secrets/network in tests;
  RLS tests required for tenant tables; e2e isolation/teardown.
- `security.md` — repo-wide cross-cutting: dependency hygiene (lockfile committed, `npm audit` in CI), security
  headers, no secrets in logs, sanitized error responses.

## New templates — 4 → 10 total
`qa-plan.md`, `security-audit.md` (findings table with severity), `threat-model.md` (STRIDE-lite),
`compliance.md` (GDPR/SOC2-lite checklist).

## v1 touch-ups (additive, low-risk)
- `.claude/hooks/detect-gaps.sh` + `session-start.sh` — also track `qa-plan` and `security-audit` artifacts.
- `/help` and `/start` studio map — list the 6 new skills under a **Harden** phase.
- `/studio-status` — report QA/security artifact status.

## Net change
+2 agents (→12), +6 skills (→23), +2 edited skills (code-review, launch-checklist), +2 rules (→8),
+4 templates (→10), 3 minor v1 file touch-ups.

## Verification
- **Structural gate:** counts 12/23/4/8/10; every new skill references a real agent; new templates referenced by
  skills resolve; hooks still pass `bash -n` and the secret-scan test stays green.
- **Gate behavior:** `/launch-checklist` BLOCKS when `security-audit.md` has an open high/critical finding or the
  test run is red; PASSES when both are clean (verify in a scratch clone with fixture artifacts).
- **Workflow dry-run (scratch clone):** `/qa-plan` → `/test-setup` → `/write-tests` produces a runnable test
  scaffold; `/security-audit` produces a severity-ranked report; each follows ask→approve and writes nothing
  unapproved.
- **No regressions:** v1's existing structural gate + secret-scan test still pass unchanged.

## Out of scope (deferred to 2b)
Growth/marketing/SEO, lifecycle email, product analytics/event tracking, customer support runbooks, help docs,
live-ops (incident/hotfix, changelog, feature flags).
