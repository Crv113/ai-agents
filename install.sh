#!/usr/bin/env bash
# Connecteur Claude Code : génère les agents et les lie dans ~/.claude (ou $CLAUDE_CONFIG_DIR).
# Relançable sans risque. Sauvegarde avant de remplacer, demande avant de supprimer.
set -eu

DRY=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    -h|--help) echo "Usage : ./install.sh [--dry-run]"; exit 0 ;;
    *) echo "Option inconnue : $arg" >&2; exit 1 ;;
  esac
done

REPO="$(cd "$(dirname "$0")" && pwd -P)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
STATE_DIR="$CLAUDE_DIR/ai-agents"
STATE="$STATE_DIR/state"
BUILD="$REPO/connectors/claude/build/agents"
CONF="$REPO/connectors/claude/agents.conf"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$STATE_DIR/backups/$STAMP"

say() { printf '%s\n' "$*"; }
do_() { if [ "$DRY" = 1 ]; then say "  [dry-run] $*"; else "$@"; fi; }

ask() {
  if [ "$DRY" = 1 ]; then say "  [dry-run] question : $1 → réponse supposée : non"; return 1; fi
  if [ ! -t 0 ]; then say "  (non interactif) $1 → non"; return 1; fi
  printf '%s [y/N] ' "$1"
  read -r reply
  case "$reply" in y|Y|o|O|yes|oui) return 0 ;; *) return 1 ;; esac
}

# --- État précédent -------------------------------------------------------
OLD_REPO=""
CREATED_DIRS=""
BACKUPS=""
if [ -f "$STATE" ]; then
  while IFS= read -r line; do
    case "$line" in
      repo=*) OLD_REPO="${line#repo=}" ;;
      created_dir=*) CREATED_DIRS="$CREATED_DIRS${line#created_dir=}
" ;;
      backup=*) BACKUPS="$BACKUPS${line#backup=}
" ;;
    esac
  done < "$STATE"
fi
LINKS=""

if [ -n "$OLD_REPO" ] && [ "$OLD_REPO" != "$REPO" ]; then
  say "Le dépôt a été déplacé : $OLD_REPO → $REPO (les liens seront redirigés)."
fi

# Un lien est "à nous" s'il pointe dans ce dépôt ou dans son ancien emplacement.
is_ours() {
  [ -L "$1" ] || return 1
  t="$(readlink "$1")"
  case "$t" in "$REPO"/*) return 0 ;; esac
  if [ -n "$OLD_REPO" ]; then case "$t" in "$OLD_REPO"/*) return 0 ;; esac; fi
  return 1
}

# --- Génération des agents -----------------------------------------------
say "Génération des agents → connectors/claude/build/agents/"
do_ mkdir -p "$BUILD"
for src in "$REPO"/agents/*.md; do
  [ -f "$src" ] || continue
  name="$(basename "$src" .md)"
  first="$(head -n 1 "$src")"
  if [ "$first" != "---" ]; then echo "Erreur : $src n'a pas de frontmatter." >&2; exit 1; fi
  front="$(awk 'NR==1{next} /^---$/{exit} {print}' "$src")"
  body="$(awk 'NR==1{next} f{print} /^---$/ && !f{f=1}' "$src")"
  printf '%s\n' "$front" | grep -q '^name:' || { echo "Erreur : 'name' manquant dans $src" >&2; exit 1; }
  printf '%s\n' "$front" | grep -q '^description:' || { echo "Erreur : 'description' manquant dans $src" >&2; exit 1; }
  extra=""
  if [ -f "$CONF" ]; then
    extra="$(grep -E "^$name\.[A-Za-z]+=" "$CONF" | sed -E "s/^$name\.([A-Za-z]+)=/\1: /" || true)"
  fi
  out="$BUILD/$name.md"
  if [ "$DRY" = 1 ]; then
    say "  [dry-run] écrire $out"
  else
    {
      echo "---"
      printf '%s\n' "$front"
      [ -n "$extra" ] && printf '%s\n' "$extra"
      echo "---"
      printf '%s\n' "$body"
    } > "$out.tmp"
    mv "$out.tmp" "$out"
  fi
done

# Agents générés devenus orphelins (agent supprimé du dépôt)
if [ -d "$BUILD" ]; then
  for f in "$BUILD"/*.md; do
    [ -f "$f" ] || continue
    [ -f "$REPO/agents/$(basename "$f")" ] || do_ rm -f "$f"
  done
fi

# --- Liens ------------------------------------------------------------------
link_one() { # $1 = destination, $2 = source
  dest="$1"; src="$2"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    LINKS="$LINKS$dest
"; return
  fi
  if is_ours "$dest"; then
    say "  mise à jour : $dest → $src"
    do_ ln -sfn "$src" "$dest"
    LINKS="$LINKS$dest
"; return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    say "  existe déjà et n'est pas géré par ai-agents : $dest"
    if ask "  Le sauvegarder dans $BACKUP_DIR puis le remplacer ?"; then
      kind="$(basename "$(dirname "$dest")")"
      mkdir -p "$BACKUP_DIR/$kind"
      mv "$dest" "$BACKUP_DIR/$kind/"
      BACKUPS="$BACKUPS$dest|$BACKUP_DIR/$kind/$(basename "$dest")
"
      ln -s "$src" "$dest"
      LINKS="$LINKS$dest
"
      say "  sauvegardé et remplacé : $dest"
    else
      say "  laissé tel quel : $dest"
    fi
    return
  fi
  say "  création : $dest → $src"
  do_ ln -s "$src" "$dest"
  LINKS="$LINKS$dest
"
}

ensure_dir() {
  if [ ! -d "$1" ]; then
    say "Création du dossier $1"
    do_ mkdir -p "$1"
    case "$CREATED_DIRS" in *"$1
"*) ;; *) CREATED_DIRS="$CREATED_DIRS$1
" ;; esac
  fi
}

remove_orphans() { # $1 = dossier, $2 = test d'existence de la source (fichier|dossier)
  [ -d "$1" ] || return 0
  for dest in "$1"/*; do
    is_ours "$dest" || continue
    t="$(readlink "$dest")"
    case "$t" in "$REPO"/*) ;; *) continue ;; esac   # liens d'un ancien emplacement : déjà redirigés
    if [ ! -e "$t" ]; then
      say "  lien orphelin (source supprimée du dépôt) : $dest"
      if ask "  Retirer ce lien ?"; then rm "$dest"; say "  retiré : $dest"; fi
    fi
  done
}

say "Agents → $CLAUDE_DIR/agents/"
ensure_dir "$CLAUDE_DIR/agents"
for src in "$REPO"/agents/*.md; do
  [ -f "$src" ] || continue
  link_one "$CLAUDE_DIR/agents/$(basename "$src")" "$BUILD/$(basename "$src")"
done

say "Skills → $CLAUDE_DIR/skills/"
ensure_dir "$CLAUDE_DIR/skills"
for src in "$REPO"/skills/*/; do
  [ -f "$src/SKILL.md" ] || continue
  name="$(basename "$src")"
  link_one "$CLAUDE_DIR/skills/$name" "$REPO/skills/$name"
done

remove_orphans "$CLAUDE_DIR/agents"
remove_orphans "$CLAUDE_DIR/skills"

# --- Écriture de l'état -----------------------------------------------------
if [ "$DRY" = 0 ]; then
  mkdir -p "$STATE_DIR"
  {
    echo "repo=$REPO"
    printf '%s' "$CREATED_DIRS" | sed '/^$/d; s/^/created_dir=/'
    printf '%s' "$LINKS" | sed '/^$/d; s/^/link=/'
    printf '%s' "$BACKUPS" | sed '/^$/d; s/^/backup=/'
  } > "$STATE.tmp"
  mv "$STATE.tmp" "$STATE"
fi

say ""
say "Terminé$( [ "$DRY" = 1 ] && echo ' (dry-run, rien n’a été modifié)')."
say "Redémarrer Claude Code pour prendre en compte les agents et skills."
