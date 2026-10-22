"""Ajoute ou retire les hooks ai-agents dans un settings.json de Claude Code.

Usage : settings_merge.py install|uninstall <settings.json> <chemin emit.sh> [--dry-run]
Ne touche qu'aux entrées dont la commande finit par /connectors/claude/hooks/emit.sh.
Affiche une ligne par changement. Code de sortie : 0 = rien à faire, 10 = modifié (ou à modifier en dry-run).
"""
import json
import os
import sys

EVENTS = ["SubagentStart", "SubagentStop", "PreToolUse", "PostToolUse", "Stop"]
SUFFIX = "/connectors/claude/hooks/emit.sh"


def is_ours(handler):
    return isinstance(handler, dict) and str(handler.get("command", "")).endswith(SUFFIX)


# Stop est synchrone : un hook async lancé en fin de tour peut être tué si la session se termine
# juste après (mode non interactif), et le dernier tour serait perdu. Sans dashboard, il sort en 0,2 s.
SYNC_EVENTS = {"Stop"}


def our_handler(emit, event):
    return {"type": "command", "command": emit, "async": event not in SYNC_EVENTS, "timeout": 5}


def install(settings, emit):
    changes = []
    hooks = settings.setdefault("hooks", {})
    for event in EVENTS:
        groups = hooks.setdefault(event, [])
        found = False
        for group in groups:
            for i, handler in enumerate(group.get("hooks", [])):
                if is_ours(handler):
                    found = True
                    if handler != our_handler(emit, event):
                        group["hooks"][i] = our_handler(emit, event)
                        changes.append(f"mise à jour du hook {event}")
        if not found:
            groups.append({"matcher": "*", "hooks": [our_handler(emit, event)]})
            changes.append(f"ajout du hook {event}")
    return changes


def uninstall(settings):
    changes = []
    hooks = settings.get("hooks")
    if not isinstance(hooks, dict):
        return changes
    for event in list(hooks):
        groups = hooks[event]
        if not isinstance(groups, list):
            continue
        for group in list(groups):
            handlers = group.get("hooks", [])
            kept = [h for h in handlers if not is_ours(h)]
            if len(kept) != len(handlers):
                changes.append(f"retrait du hook {event}")
                if kept:
                    group["hooks"] = kept
                else:
                    groups.remove(group)
        if not groups:
            del hooks[event]
    if not hooks:
        del settings["hooks"]
    return changes


def main():
    action, path = sys.argv[1], sys.argv[2]
    emit = sys.argv[3] if len(sys.argv) > 3 and not sys.argv[3].startswith("--") else ""
    dry = "--dry-run" in sys.argv
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            text = f.read()
        settings = json.loads(text) if text.strip() else {}
    elif action == "uninstall":
        return 0
    else:
        settings = {}
    changes = install(settings, emit) if action == "install" else uninstall(settings)
    for c in changes:
        print(("  [dry-run] " if dry else "  ") + c)
    if not changes:
        return 0
    if not dry:
        tmp = path + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(settings, f, indent=2, ensure_ascii=False)
            f.write("\n")
        os.replace(tmp, path)
    return 10


if __name__ == "__main__":
    sys.exit(main())
