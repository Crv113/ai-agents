# Prérequis du connecteur Claude Code. Chargé par install.sh (bash 3.2 compatible).
# Fournit : find_node20, find_chrome, prereqs_report.

# Version majeure d'un exécutable node, ou vide.
node_major() {
  "$1" -v 2>/dev/null | sed -E 's/^v([0-9]+).*/\1/'
}

# Dossier bin d'un Node >= 20 : celui du PATH s'il convient (NODE_FROM=path),
# sinon le plus récent trouvé dans nvm, fnm, volta, asdf ou Homebrew (NODE_FROM=autre).
find_node20() {
  NODE_BIN=""; NODE_FROM=""; NODE_VERSION=""
  local n m best="" bestm=0
  n="$(command -v node 2>/dev/null || true)"
  if [ -n "$n" ]; then
    m="$(node_major "$n")"
    if [ -n "$m" ] && [ "$m" -ge 20 ]; then
      NODE_BIN="$(dirname "$n")"; NODE_FROM="path"; NODE_VERSION="$("$n" -v)"; return 0
    fi
  fi
  for n in "$HOME"/.nvm/versions/node/*/bin/node \
           "$HOME"/.local/share/fnm/node-versions/*/installation/bin/node \
           "$HOME"/Library/Application\ Support/fnm/node-versions/*/installation/bin/node \
           "$HOME"/.fnm/node-versions/*/installation/bin/node \
           "$HOME"/.volta/tools/image/node/*/bin/node \
           "$HOME"/.asdf/installs/nodejs/*/bin/node \
           /opt/homebrew/opt/node*/bin/node /opt/homebrew/bin/node \
           /usr/local/opt/node*/bin/node /usr/local/bin/node; do
    [ -x "$n" ] || continue
    m="$(node_major "$n")"
    [ -n "$m" ] || continue
    if [ "$m" -ge 20 ] && [ "$m" -gt "$bestm" ]; then best="$n"; bestm="$m"; fi
  done
  if [ -n "$best" ]; then
    NODE_BIN="$(dirname "$best")"; NODE_FROM="autre"; NODE_VERSION="$("$best" -v)"; return 0
  fi
  return 1
}

# Google Chrome installé (navigateur utilisé par défaut par Playwright MCP).
find_chrome() {
  [ -d "/Applications/Google Chrome.app" ] && return 0
  [ -d "$HOME/Applications/Google Chrome.app" ] && return 0
  command -v google-chrome >/dev/null 2>&1 && return 0
  command -v google-chrome-stable >/dev/null 2>&1 && return 0
  return 1
}

# Chromium de Playwright déjà téléchargé.
find_playwright_chromium() {
  ls -d "$HOME"/Library/Caches/ms-playwright/chromium-* "$HOME"/.cache/ms-playwright/chromium-* >/dev/null 2>&1
}

# Bilan affiché en fin d'installation. Utilise NODE_* et BROWSER_MODE (chrome|chromium|absent).
prereqs_report() {
  say ""
  say "Prérequis"
  if command -v git >/dev/null 2>&1; then say "  ✓ git"; else say "  ✗ git : indispensable (branches, commits, diff). À installer."; fi
  if [ -n "$NODE_BIN" ]; then
    if [ "$NODE_FROM" = "path" ]; then
      say "  ✓ Node $NODE_VERSION (navigateur du tester)"
    else
      say "  ✓ Node $NODE_VERSION trouvé dans $NODE_BIN, utilisé pour le navigateur du tester uniquement (ton Node par défaut n'est pas modifié)"
    fi
  else
    say "  ✗ Node >= 20 : absent. Le tester marquera les critères d'interface « non testé ». Installer Node 20+ (https://nodejs.org ou nvm), puis relancer ./install.sh"
  fi
  case "${BROWSER_MODE:-absent}" in
    chrome) say "  ✓ Google Chrome (navigateur du tester)" ;;
    chromium) say "  ✓ Chromium de Playwright (navigateur du tester, Chrome absent)" ;;
    *) say "  ✗ Navigateur : ni Chrome ni Chromium de Playwright. Le tester essaiera de l'installer au premier test, sinon « non testé ». Relancer ./install.sh pour le télécharger (~150 Mo)" ;;
  esac
  if command -v python3 >/dev/null 2>&1; then say "  ✓ python3 (hooks du dashboard)"; else say "  ✗ python3 : absent. Les hooks du dashboard ne feront rien (le reste fonctionne)."; fi
  if command -v gh >/dev/null 2>&1; then
    if gh auth status >/dev/null 2>&1; then say "  ✓ gh, connecté (création des PR)"; else say "  ✗ gh non connecté : lancer « gh auth login », sinon créer les PR à la main"; fi
  else
    say "  ✗ gh : absent. /feature ne pourra pas créer la PR (à faire à la main). https://cli.github.com"
  fi
}
