#!/usr/bin/env bash
# Retire ce qu'install.sh a mis en place et restaure les sauvegardes.
# Ne touche qu'aux éléments enregistrés dans l'état d'installation.
set -eu

DRY=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    -h|--help) echo "Usage : ./uninstall.sh [--dry-run]"; exit 0 ;;
    *) echo "Option inconnue : $arg" >&2; exit 1 ;;
  esac
done

REPO="$(cd "$(dirname "$0")" && pwd -P)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
STATE_DIR="$CLAUDE_DIR/ai-agents"
STATE="$STATE_DIR/state"
BUILD="$REPO/connectors/claude/build"

say() { printf '%s\n' "$*"; }
do_() { if [ "$DRY" = 1 ]; then say "  [dry-run] $*"; else "$@"; fi; }

if [ ! -f "$STATE" ]; then
  say "Aucune installation trouvée ($STATE absent). Rien à faire."
  exit 0
fi

STATE_REPO="$(sed -n 's/^repo=//p' "$STATE" | head -n 1)"

# 1. Liens : retirés seulement s'ils pointent encore vers le dépôt installé
sed -n 's/^link=//p' "$STATE" | while IFS= read -r dest; do
  if [ -L "$dest" ]; then
    t="$(readlink "$dest")"
    case "$t" in
      "$STATE_REPO"/*|"$REPO"/*) say "retrait du lien : $dest"; do_ rm "$dest" ;;
      *) say "ignoré (ne pointe plus vers ai-agents) : $dest" ;;
    esac
  fi
done

# 2. Sauvegardes : restaurées si l'emplacement est libre
sed -n 's/^backup=//p' "$STATE" | while IFS='|' read -r dest saved; do
  if [ ! -e "$saved" ] && [ ! -L "$saved" ]; then
    say "sauvegarde introuvable, ignorée : $saved"
  elif [ -e "$dest" ] || [ -L "$dest" ]; then
    say "emplacement occupé, sauvegarde conservée : $saved (à restaurer à la main vers $dest)"
  else
    say "restauration : $saved → $dest"
    do_ mv "$saved" "$dest"
  fi
done

# 3. Dossiers créés par install.sh : supprimés seulement s'ils sont vides
sed -n 's/^created_dir=//p' "$STATE" | while IFS= read -r d; do
  if [ -d "$d" ] && [ -z "$(ls -A "$d")" ]; then
    say "suppression du dossier vide : $d"
    do_ rmdir "$d"
  elif [ -d "$d" ]; then
    say "dossier conservé (non vide) : $d"
  fi
done

# 4. Fichiers générés et état
if [ -d "$BUILD" ]; then
  say "suppression des agents générés : $BUILD"
  for f in "$BUILD"/agents/*.md; do [ -f "$f" ] && do_ rm -f "$f"; done
  do_ rmdir "$BUILD/agents" 2>/dev/null || true
  do_ rmdir "$BUILD" 2>/dev/null || true
fi
do_ rm -f "$STATE"
if [ "$DRY" = 0 ]; then
  find "$STATE_DIR/backups" -type d -empty -delete 2>/dev/null || true
  rmdir "$STATE_DIR" 2>/dev/null || say "conservé (contient des sauvegardes non restaurées) : $STATE_DIR"
fi

say ""
say "Désinstallation terminée$( [ "$DRY" = 1 ] && echo ' (dry-run, rien n’a été modifié)'). Redémarrer Claude Code."
