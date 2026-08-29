#!/usr/bin/env bash
# Bloque les commits qui introduisent un secret ou un .env tracké. Reçoit le
# payload PreToolUse Bash sur stdin (JSON, ou une commande brute en test) ;
# n'agit que sur `git commit`. Honore DIFF_FILE (contenu du diff) et
# DIFF_NAMES (noms des fichiers stagés) pour les tests.
#
# Repris tel quel du kit Claude-Code-SaaS-Studio
# (evgenii-studitskikh/Claude-Code-SaaS-Studio) — générique git, aucune
# dépendance à la stack. Les patterns Stripe (sk_live_/sk_test_/rk_live_)
# sont gardés même si Trésora n'a pas encore de facturation : ça ne coûte
# rien tant qu'il n'y a rien à matcher, et ça sert le jour où l'abonnement
# par espace sera activé (cf. docs/saas-studio-adaptation.md).
set -uo pipefail
cmd="$(cat 2>/dev/null || true)"
case "$cmd" in *"git commit"*) ;; *) exit 0 ;; esac

if [ "${DIFF_FILE:-}" != "" ]; then
  content="$(cat "$DIFF_FILE")"
else
  content="$(git diff --cached 2>/dev/null || true)"
fi

if [ "${DIFF_NAMES:-}" != "" ]; then
  names="$DIFF_NAMES"
else
  names="$(git diff --cached --name-only 2>/dev/null || true)"
fi

# Motifs de secrets. La clé service_role Supabase est explicitement
# matchée (jamais côté client, mobile ou web) ; la clé publique anon
# n'est volontairement PAS bloquée, elle a sa place dans
# lib/config/supabase_config.dart et un éventuel .env.example.
patterns='sk_live_[A-Za-z0-9]{16,}|sk_test_[A-Za-z0-9]{16,}|rk_live_[A-Za-z0-9]{16,}|SUPABASE_SERVICE_ROLE_KEY=.+|-----BEGIN [A-Z ]*PRIVATE KEY-----'
if printf '%s' "$content" | grep -Eq "$patterns"; then
  echo "BLOQUÉ : secret potentiel dans les changements stagés. Utilise une variable d'environnement, ne commit jamais de clé." >&2
  exit 1
fi
if printf '%s\n' "$names" | grep -E '(^|/)\.env($|\.)' | grep -qv '\.env\.example$'; then
  echo "BLOQUÉ : un vrai fichier .env est stagé. Ne commit que .env.example ; garde les secrets dans un .env non tracké." >&2
  exit 1
fi
exit 0
