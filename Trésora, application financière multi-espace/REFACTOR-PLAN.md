# Trésora — shadcn/ui refactor plan

Decisions confirmed 2026-08-27.

## 1. Theme
Keep the existing identity exactly: gradient `#FFC220 → #F26522`, graphite neutrals.
No new color system — translate to shadcn HSL tokens in `app/globals.css`:

```css
:root {
  --primary: 38 100% 56%;        /* #FFC220 */
  --primary-foreground: 220 9% 12%;
  --accent: 20 89% 54%;          /* #F26522 */
  --accent-foreground: 0 0% 100%;
  --ring: 20 89% 54%;
  /* graphite neutrals */
  --background: 0 0% 100%;
  --foreground: 220 9% 12%;
  --muted: 220 14% 96%;
  --muted-foreground: 220 9% 46%;
  --border: 220 13% 91%;
}
```
Gradient stays a utility (`bg-gradient-to-r from-[hsl(var(--primary))] to-[hsl(var(--accent))]`),
so brand buttons/headers keep the current look while everything else is token-driven.

## 2. Stack
Next.js (App Router) + TypeScript + Tailwind + shadcn/ui, run locally by the user.
21st.dev patterns for animated menus, dropdowns, dialogs. Framer Motion for transitions.

## 3. Surfaces
- Website: responsive shadcn components (covers mobile browser).
- Native app: Flutter, coded separately. Canvas mobile screens = visual reference only,
  no shadcn code reuse.

## 4. Screen order
1. Authentication
2. Dashboard (shell + 12-section nav)
3. New expense (finish in shadcn — toggles, conditional logic, live recap)
4. Collect / Payments (5 methods incl. Stripe + Mobile Money scanner)
5. Reports (PDF / Excel / Word export)

Source of truth for content and layout: existing `Tresora.dc.html` mockups.

## 5. Roles
Single shared component tree, role-gated.
- `RoleContext` provides `role: 'member' | 'admin'` + `can(permission)`.
- Nav items, table row actions, and form sections declare required permissions;
  gating happens at render, not by forking components.
- Both member/admin views are still empty in the canvas → build with gating from the start.
