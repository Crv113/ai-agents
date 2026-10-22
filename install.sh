#!/usr/bin/env bash
# Connecteur Claude Code : génère les agents et les lie dans ~/.claude (ou $CLAUDE_CONFIG_DIR).
# Relançable sans risque. Sauvegarde avant de remplacer, demande avant de supprimer.
set -eu

DRY=0
HOOKS=1
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --no-hooks) HOOKS=0 ;;
    -h|--help) echo "Usage : ./install.sh [--dry-run] [--no-hooks]"; exit 0 ;;
    *) echo "Option inconnue : $arg" >&2; exit 1 ;;
  esac
done

REPO="$(cd "$(dirname "$0")" && pwd -P)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
STATE_DIR="$CLAUDE_DIR/ai-agents"
STATE="$STATE_DIR/state"
CONNECTOR="$REPO/connectors/claude"
BUILD="$CONNECTOR/build/agents"
SKILLS_BUILD="$CONNECTOR/build/skills"
AGENTS_CONF="$CONNECTOR/agents.conf"
SKILLS_CONF="$CONNECTOR/skills.conf"
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

# --- Génération --------------------------------------------------------------
# Lignes "<nom>.<champ>=<valeur>" du fichier de conf, converties en "champ: valeur".
conf_fields() { # $1 = fichier conf, $2 = nom
  [ -f "$1" ] || return 0
  grep -E "^$2\.[A-Za-z-]+=" "$1" | sed -E "s/^$2\.([A-Za-z-]+)=/\1: /" || true
}

# Écrit $3 = frontmatter neutre de $1 + champs Claude de $2 + corps de $1.
gen_md() { # $1 = source, $2 = champs à ajouter, $3 = sortie
  first="$(head -n 1 "$1")"
  if [ "$first" != "---" ]; then echo "Erreur : $1 n'a pas de frontmatter." >&2; exit 1; fi
  front="$(awk 'NR==1{next} /^---$/{exit} {print}' "$1")"
  body="$(awk 'NR==1{next} f{print} /^---$/ && !f{f=1}' "$1")"
  printf '%s\n' "$front" | grep -q '^name:' || { echo "Erreur : 'name' manquant dans $1" >&2; exit 1; }
  printf '%s\n' "$front" | grep -q '^description:' || { echo "Erreur : 'description' manquant dans $1" >&2; exit 1; }
  if [ "$DRY" = 1 ]; then say "  [dry-run] écrire $3"; return; fi
  {
    echo "---"
    printf '%s\n' "$front"
    [ -n "$2" ] && printf '%s\n' "$2"
    echo "---"
    printf '%s\n' "$body"
  } > "$3.tmp"
  mv "$3.tmp" "$3"
}

say "Génération des agents → connectors/claude/build/agents/"
do_ mkdir -p "$BUILD"
for src in "$REPO"/agents/*.md; do
  [ -f "$src" ] || continue
  name="$(basename "$src" .md)"
  gen_md "$src" "$(conf_fields "$AGENTS_CONF" "$name")" "$BUILD/$name.md"
done
# Agents générés devenus orphelins (agent supprimé du dépôt)
if [ -d "$BUILD" ]; then
  for f in "$BUILD"/*.md; do
    [ -f "$f" ] || continue
    [ -f "$REPO/agents/$(basename "$f")" ] || do_ rm -f "$f"
  done
fi

# Skills : générés seulement s'ils ont des champs dans skills.conf, sinon liés directement.
say "Génération des skills ayant des champs Claude → connectors/claude/build/skills/"
for src in "$REPO"/skills/*/; do
  [ -f "$src/SKILL.md" ] || continue
  name="$(basename "$src")"
  out="$SKILLS_BUILD/$name"
  fields="$(conf_fields "$SKILLS_CONF" "$name")"
  if [ -z "$fields" ]; then
    [ -d "$out" ] && do_ rm -rf "$out"
    continue
  fi
  [ -d "$out" ] && do_ rm -rf "$out"
  do_ mkdir -p "$out"
  gen_md "$src/SKILL.md" "$fields" "$out/SKILL.md"
  for f in "$REPO/skills/$name"/*; do
    [ "$(basename "$f")" = "SKILL.md" ] && continue
    [ -e "$f" ] && do_ ln -s "$f" "$out/$(basename "$f")"
  done
done
# Skills générés devenus orphelins (skill supprimé du dépôt)
if [ -d "$SKILLS_BUILD" ]; then
  for d in "$SKILLS_BUILD"/*/; do
    [ -d "$d" ] || continue
    [ -d "$REPO/skills/$(basename "$d")" ] || do_ rm -rf "$d"
  done
fi

skill_source() { # dossier que ~/.claude/skills/<nom> doit viser
  if [ -n "$(conf_fields "$SKILLS_CONF" "$1")" ]; then echo "$SKILLS_BUILD/$1"; else echo "$REPO/skills/$1"; fi
}

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
  link_one "$CLAUDE_DIR/skills/$name" "$(skill_source "$name")"
done

remove_orphans "$CLAUDE_DIR/agents"
remove_orphans "$CLAUDE_DIR/skills"

# --- Hooks d'événements (settings.json) ------------------------------------
SETTINGS="$CLAUDE_DIR/settings.json"
EMIT="$CONNECTOR/hooks/emit.sh"
if [ "$HOOKS" = 0 ]; then
  say "Hooks : ignorés (--no-hooks)."
elif ! command -v python3 >/dev/null 2>&1; then
  say "Hooks : python3 introuvable, étape ignorée (les agents et skills fonctionnent sans)."
else
  say "Hooks d'événements → $SETTINGS"
  rc=0
  python3 -I "$CONNECTOR/hooks/settings_merge.py" install "$SETTINGS" "$EMIT" --dry-run >/dev/null || rc=$?
  if [ "$rc" = 10 ]; then
    if [ "$DRY" = 1 ]; then
      python3 -I "$CONNECTOR/hooks/settings_merge.py" install "$SETTINGS" "$EMIT" --dry-run || true
    else
      if [ -f "$SETTINGS" ]; then
        mkdir -p "$BACKUP_DIR"
        cp -p "$SETTINGS" "$BACKUP_DIR/settings.json"
        say "  sauvegarde : $BACKUP_DIR/settings.json"
      fi
      python3 -I "$CONNECTOR/hooks/settings_merge.py" install "$SETTINGS" "$EMIT" || true
    fi
  elif [ "$rc" != 0 ]; then
    say "  settings.json illisible (JSON invalide ?) : laissé tel quel, hooks non installés."
  fi
fi

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
