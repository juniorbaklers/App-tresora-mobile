# Claude Code SaaS Studio — Build a SaaS with an AI Agent Team

**Turn one Claude Code session into a full SaaS studio: 12 specialized AI agents, 23 slash-command skills, protective hooks, and a disciplined workflow that takes you from raw idea to production launch — with you in control at every step.**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](#contributing)

---

## Why this exists

Everyone is "vibe coding" SaaS apps with AI right now — and most of those projects collapse the same way: the model races ahead, makes silent architectural decisions, skips tests, hardcodes secrets, and ships something nobody validated. AI-assisted development is fast, but speed without structure is how you end up with an unmaintainable codebase and a leaked Stripe key.

**Claude Code SaaS Studio is the antidote.** It's a free, open-source template repository that transforms a single [Claude Code](https://claude.com/claude-code) session into a structured, multi-agent product team: directors who gate decisions, specialist engineers who execute, path-scoped engineering rules, and git hooks that physically block secret leaks. Instead of re-pasting the same prompts forever, you clone the repo and get an opinionated AI development workflow out of the box.

**The core discipline:** ask → present options → user decides → draft → approve. No file is created or changed without that loop. You are the founder; the agents are your team.

## What you get

- **12 AI agents** organized in director / specialist tiers — product, UX, frontend, backend, database, billing, QA, security, and DevOps
- **23 slash-command skills** covering the entire SaaS lifecycle: idea validation, PRD writing, architecture, schema design, feature building, Stripe billing, testing, security audits, and launch
- **Protective hooks** — a pre-commit hook that blocks secrets and `.env` files from ever being committed, a push guard that warns before pushing to `main`, and a gap detector that reports missing spec artifacts
- **Path-scoped engineering rules** (`.claude/rules/`) that enforce Row Level Security, Stripe webhook signature verification, input validation, server-only secrets, and deterministic tests — automatically, on every file the agents touch
- **Document templates** for PRDs, ADRs, data models, pricing, QA plans, threat models, security audits, and launch checklists

## Default tech stack

A production-ready, batteries-included SaaS starter stack — fully swappable (see [Swapping the stack](#swapping-the-stack)):

| Layer | Technology |
|-------|------------|
| Framework | Next.js (App Router) + TypeScript |
| Database / Auth / Storage | Supabase (Postgres, Auth, Storage) |
| Payments | Stripe |
| UI | Tailwind CSS + shadcn/ui |
| Hosting | Vercel |

## Quick start

```bash
git clone https://github.com/evgenii-studitskikh/Claude-Code-SaaS-Studio my-saas
cd my-saas
claude
```

Once inside the Claude Code session, run:

```
/start
```

The `/start` skill detects where you are in the build lifecycle and routes you to the right phase automatically. Five minutes from `git clone` to a working AI product team.

## Example prompts

Not sure what to say after `/start`? These are real prompts the studio is designed for — copy, paste, adapt:

**Day one — validate and spec:**

```
/validate-idea I want to build a tool that helps freelance designers send invoices and get paid faster
```

```
/write-prd — keep it to a 2-week MVP scope, solo founder, no team features in v1
```

```
/map-flows focus on the signup → first invoice → payment received journey
```

**Building:**

```
/setup-stack
```

```
/design-schema I need workspaces, members, invoices, and payments — multi-tenant from day one
```

```
/build-feature invoice creation form with line items and PDF preview --review lean
```

```
/code-review
```

**Money and hardening:**

```
/design-pricing freemium with a $19/mo Pro tier, metered by invoices sent
```

```
/setup-billing
```

```
/threat-model focus on the public invoice-sharing links
```

```
/security-audit the diff from this week before I merge
```

**Or just talk to the team in plain English:**

```
Ask the technical-director whether we should use Supabase Realtime or polling for invoice status updates
```

```
What's left before I can launch? Run the gap check.
```

```
/scope-check I'm tempted to add a client portal — is that in scope for the MVP?
```

## The agent team

Twelve agents in two tiers handle everything from idea validation to production launch.

### Directors (Claude Opus) — strategy, gates, sign-off

| Agent | Role |
|-------|------|
| `product-director` | Owns product vision, validates ideas, approves PRDs and pricing strategy |
| `technical-director` | Owns architecture and engineering standards, approves technical decisions |
| `producer` | Orchestrates the full studio session, routes tasks, tracks phase progress |

### Specialists (Claude Sonnet) — execution

| Agent | Role |
|-------|------|
| `product-manager` | Writes PRDs, user stories, acceptance criteria |
| `ux-designer` | Maps user flows, designs screens, produces UI specs |
| `frontend-engineer` | Builds Next.js pages, components, and client logic |
| `backend-engineer` | Builds API routes, server actions, and business logic |
| `database-engineer` | Designs Supabase schema, migrations, and RLS policies |
| `billing-engineer` | Integrates Stripe, builds billing portal and webhook handlers |
| `qa-engineer` | Owns test strategy; scaffolds the test stack and writes unit/integration/e2e tests |
| `security-engineer` | Runs security audits, threat models, dependency audits, and GDPR/SOC 2-lite checks |
| `devops-engineer` | Configures Vercel deployments, env vars, CI, and monitoring |

## Workflow: idea → launch in six phases

```
/start  →  detects stage, routes to the right phase

Navigation (any time)
   /start              Detect project stage and route to the right skill
   /help               List all skills and agents with descriptions
   /studio-status      Show current phase, existing artifacts, and what's next
   /scope-check        Verify a proposed change is in scope for the PRD

1. Product & UX
   /validate-idea      Pressure-test the idea; PROCEED/PIVOT/KILL verdict
   /write-prd          Draft a full Product Requirements Document
   /map-flows          Map user journeys and the full screen list
   /design-ui          Produce Tailwind/shadcn UI component specs

2. Engineering
   /setup-stack        Scaffold Next.js + Supabase + Stripe project
   /design-architecture  Document system architecture and ADRs
   /design-schema      Design Postgres schema, migrations, and RLS policies
   /build-feature      Implement a scoped feature end-to-end
   /code-review        Review the diff against project rules and security checks

3. Billing
   /design-pricing     Design pricing tiers mapped to Stripe products
   /setup-billing      Integrate Stripe checkout, webhooks, and customer portal

4. Harden
   /qa-plan            Define the test strategy and tooling
   /test-setup         Scaffold Vitest + Testing Library + Playwright + CI
   /write-tests        Author tests for a user story (incl. RLS and webhook fixtures)
   /security-audit     OWASP-style audit with a severity-ranked findings report
   /threat-model       STRIDE-lite threat model for multi-tenant SaaS
   /compliance-check   GDPR / SOC 2-lite readiness with a PASS/GAP report

5. Infra & Launch
   /setup-deploy       Configure Vercel project, env vars, and CI
   /launch-checklist   Pre-launch gate: secrets, RLS, Stripe live mode, monitoring
```

Each skill is an explicit, user-invocable command. Nothing runs automatically. You invoke what you need, when you need it.

## Guardrails that actually guard

Most AI coding templates are just prompts. This one ships enforcement:

- **Secret-blocking commit hook** — `git commit` is intercepted; diffs containing API keys, tokens, or a tracked `.env` file are rejected before they ever reach history
- **Push guard** — pushing to `main` triggers a warning so accidental direct pushes don't slip through
- **Path-scoped rules** — when an agent touches `**/stripe/**` it must verify webhook signatures and never trust client-sent amounts; when it touches Supabase code it must enable RLS and scope every query by tenant. The rules travel with the paths, so they apply no matter which agent is working
- **Gap detection** — `detect-gaps.sh` reports which lifecycle artifacts (PRD, architecture, data model, pricing, QA plan, security audit…) are still missing, so nothing ships half-specified

## Review intensity

Every skill that produces artifacts accepts a `--review` flag controlling how many director gates fire:

| Mode | Behavior |
|------|----------|
| `full` | All director gates active — directors approve every phase transition (default for production work) |
| `lean` | Phase gates only — directors approve at phase boundaries, not within phases (good for iteration sprints) |
| `solo` | No gates — skills run straight through without approval pauses (for experienced users who know what they want) |

```
/build-feature auth --review lean
/design-schema --review full
/write-prd --review solo
```

If omitted, the producer agent picks a sensible default based on the current phase.

## Swapping the stack

The default stack lives primarily in the path-scoped rules and the setup skills, but the engineering agents also contain stack-specific guidance — update those too for a full stack swap.

| What to change | File(s) to edit |
|----------------|-----------------|
| Database / auth provider (e.g. PlanetScale, Neon, Firebase) | `.claude/rules/data.md`, `.claude/skills/design-schema/SKILL.md`, `.claude/agents/` (database-engineer, backend-engineer) |
| Payment provider (e.g. Paddle, LemonSqueezy) | `.claude/rules/billing.md`, `.claude/skills/setup-billing/SKILL.md`, `.claude/skills/design-pricing/SKILL.md`, `.claude/agents/` (billing-engineer) |
| Framework / hosting | `.claude/skills/setup-stack/SKILL.md`, `.claude/skills/setup-deploy/SKILL.md`, `.claude/agents/` (frontend-engineer, devops-engineer) |

Edit those files to describe your preferred tools and conventions.

## Who is this for?

- **Solo founders and indie hackers** who want to ship a SaaS MVP with AI without losing architectural control
- **Developers exploring Claude Code agents, skills, and hooks** who want a complete, working reference for multi-agent orchestration
- **Teams prototyping** who need AI speed with real engineering guardrails: tenant isolation, webhook verification, secret hygiene, and a test strategy from day one

If you've ever asked "how do I build a SaaS with Claude Code?" or "how do I stop my AI coding agent from going rogue?" — this repo is the answer to both.

## Contributing

Contributions are very welcome! This is a community template, and it gets better with every new skill, rule, agent, and stack variant.

Good first contributions:

- **New skills** — e.g. analytics setup, email/transactional messaging, i18n, admin dashboards
- **Stack variants** — rules and setup skills for Paddle, Neon, Drizzle, Clerk, Railway, etc.
- **Sharper rules** — tighter security/RLS/billing standards in `.claude/rules/`
- **Hook improvements** — better secret patterns, additional pre-commit checks
- **Docs and examples** — real-world walkthroughs of building an app with the studio

To contribute: fork the repo, create a feature branch, and open a pull request with a clear description of what your change does and why. For new skills, follow the existing `SKILL.md` frontmatter format under `.claude/skills/`, and keep the studio's core contract intact: **draft → approve, never act without sign-off.** Found a bug or have an idea? [Open an issue](../../issues) — even a rough sketch helps.

## License

MIT — see [LICENSE](LICENSE). Free for personal and commercial use.

---

**Keywords:** Claude Code template · AI agents for software development · build a SaaS with AI · multi-agent AI development · Claude Code skills and hooks · Next.js SaaS starter · Supabase + Stripe SaaS template · AI pair programming workflow · agentic coding with guardrails
