#!/bin/sh
# Hook Claude Code : envoie l'événement au dashboard ai-agents s'il tourne.
# Silencieux, ne bloque jamais, sort toujours avec le code 0.
command -v python3 >/dev/null 2>&1 || exit 0
python3 -I "$(dirname "$0")/emit.py" >/dev/null 2>&1
exit 0
