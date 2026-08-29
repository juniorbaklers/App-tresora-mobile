#!/usr/bin/env bash
# Avertit (sans bloquer) lors d'un push vers main. Reçoit le payload
# PreToolUse Bash sur stdin (JSON, ou une commande brute en test). Ne
# matche qu'un vrai appel `git push`, pas un message de commit qui
# contiendrait juste les mots « git push ».
#
# Repris tel quel du kit Claude-Code-SaaS-Studio — générique git, aucune
# dépendance à la stack.
set -uo pipefail
cmd="$(cat 2>/dev/null || true)"
case "$cmd" in
  *'"command":"git push'*|*'"command": "git push'*|"git push"*|*'&& git push'*|*'; git push'*|*';git push'*)
    b="$(git branch --show-current 2>/dev/null || true)"
    if [ "$b" = "main" ]; then echo "⚠️  Push vers main. Confirme que c'est voulu." >&2; fi
    ;;
esac
exit 0
