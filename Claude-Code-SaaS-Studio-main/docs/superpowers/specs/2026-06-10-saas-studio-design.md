# Claude Code SaaS Studio — v1 Design Spec

**Date:** 2026-06-10
**Status:** Approved

## Context

Build a publishable Claude Code **template** that does for building SaaS products what
[Claude-Code-Game-Studios](https://github.com/Donchitos/Claude-Code-Game-Studios) does for games: turn a single
Claude Code session into a structured "studio" of specialized agents, slash-command skills, automated hooks, and
path-scoped rules, operating under a strict non-autonomous protocol (agents *ask → present options → user
decides → draft → approve*).

The game template is large (49 agents, 73 skills, 12 hooks). v1 is deliberately scoped as a **focused, complete
vertical slice** — a coherent idea→ship loop — designed to grow later. The target repo
(`Claude-Code-SaaS-Studio`) starts empty.

**Framing:** we are building a *template repo* — markdown agent files, skill commands, shell hooks, rule files,
and doc templates. We are **not** building a SaaS app. The template's agents/skills/rules *target* a default
stack an end-user's SaaS would be built in.

### Locked decisions
- **Goal:** reusable, publishable, open-source-ready template (general enough for *any* SaaS).
- **Scope:** focused MVP, built to expand.
- **Pillars (all four):** Product & UX · Full-stack Engineering · Billing & Monetization · Infra/DevOps & Launch.
- **Stack stance:** opinionated default + documented swap points.
- **Default stack:** Next.js (App Router) + TypeScript · Supabase (Postgres/auth/storage) · Stripe ·
  Tailwind/shadcn · deploy on Vercel.

## Studio philosophy
- Non-autonomous protocol: **ask → present options → user decides → draft → approve**. Nothing written without
  sign-off.
- Tunable review intensity: `full` / `lean` / `solo`.

## Agents — 10 total (3 directors + 7 specialists)

**Tier 1 — Directors (Opus):**
- `product-director` — vision, target user, scope guardian, roadmap.
- `technical-director` — architecture, stack decisions, data model & multi-tenancy strategy.
- `producer` — phase coordination, sprint planning, enforces the ask→approve protocol.

**Tier 2/3 — Specialists (Sonnet/Haiku):**
- `product-manager` — PRDs, user stories, scope checks.
- `ux-designer` — user flows, screens, UI via shadcn/Tailwind.
- `frontend-engineer` — Next.js routes/components, client/server boundaries.
- `backend-engineer` — API routes, server actions, business logic.
- `database-engineer` — Supabase schema, RLS, multi-tenancy & auth.
- `billing-engineer` — pricing model, Stripe products/checkout/webhooks/customer portal.
- `devops-engineer` — Vercel deploy, CI/CD, envs, observability, launch.

QA & security in v1 live as skills + hooks (`/code-review`, `/launch-checklist`, secret-scanning hook), not
dedicated agents. They graduate to agents when the template grows.

## Workflow (4 phases)
```
/start → detects stage, routes
  ① Product & UX     /validate-idea → /write-prd → /map-flows → /design-ui
  ② Engineering      /setup-stack → /design-architecture → /design-schema → /build-feature → /code-review
  ③ Billing          /design-pricing → /setup-billing
  ④ Infra & Launch   /setup-deploy → /launch-checklist
  cross-cutting      /studio-status, /scope-check, /help
```

## Skills — ~16
| Phase | Skills |
|---|---|
| Navigation | `/start`, `/help`, `/studio-status`, `/scope-check` |
| Product & UX | `/validate-idea`, `/write-prd`, `/map-flows`, `/design-ui` |
| Engineering | `/setup-stack`, `/design-architecture`, `/design-schema`, `/build-feature`, `/code-review` |
| Billing | `/design-pricing`, `/setup-billing` |
| Infra & Launch | `/setup-deploy`, `/launch-checklist` |

## Hooks — 4
- `validate-commit.sh` — **block committed secrets** (Stripe/Supabase keys, `.env`), enforce env usage. Highest-value hook for SaaS.
- `session-start.sh` — show branch, recent commits, current studio stage.
- `detect-gaps.sh` — flag missing PRD / architecture / schema docs.
- `validate-push.sh` — warn on pushes to `main`.

## Path-scoped rules — ~6
- `app/**` — server components by default, no secrets in client code, validate inputs.
- `**/db|supabase/**` — RLS required, tenant-scoped queries, service-role key server-only.
- `**/billing|stripe/**` — verify webhook signatures, idempotency, price IDs from config not hardcoded.
- `**/auth/**` — session + tenant checks enforced.
- `docs/specs/**` — PRD/ADR required sections.
- env/config — secrets via env only.

## Doc templates — ~6
Idea-validation canvas · PRD · ADR (architecture decision) · Data-model/schema doc · Pricing & plans spec ·
Launch checklist.

## Repo structure
```
.claude/
  agents/      # 10 agent .md files
  skills/      # 16 slash-command skills
  hooks/       # 4 shell hooks
  rules/       # 6 path-scoped rule files
  templates/   # 6 doc templates
docs/specs/    # where generated PRDs/ADRs/specs land
README.md      # pitch + getting-started + swap-stack guide
```

## Build phases (each independently reviewable)
1. **Skeleton & conventions** — directory tree, `README.md`, agent/skill file format conventions.
2. **Agents (10)** — role, model tier, ask→approve protocol, SaaS-stack context.
3. **Skills (16)** — slash commands wired to the right agent(s) and phase.
4. **Hooks (4)** — POSIX shell; prioritize `validate-commit.sh` secret-scanning.
5. **Rules (6) & templates (6)** — path-scoped rule files and doc templates.
6. **Polish** — `/start` routing, review-intensity wiring, cross-links, final README pass.

## Verification
- **Structural:** every skill references a real agent; agent model tiers valid; hooks executable, pass `bash -n` / `shellcheck`.
- **Secret-scan hook:** staged fake `.env`/Stripe key is blocked; clean commit passes.
- **Workflow dry-run:** `/start` then a thin path (`/validate-idea` → `/write-prd` → `/design-schema` →
  `/setup-billing` → `/launch-checklist`), confirming correct agent invocation and the ask→approve protocol.
- **README check:** a new user can clone, find `/start`, and locate swap-stack docs.
