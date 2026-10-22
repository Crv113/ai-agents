"""Hook ai-agents : lit l'événement Claude Code sur stdin et l'envoie au dashboard.

Ne fait rien si le dashboard n'écoute pas. N'affiche rien, ne lève jamais d'erreur.
Format de l'événement : docs/EVENTS.md.
"""
import json
import os
import re
import socket
import subprocess
import sys
import urllib.parse
import urllib.request
from datetime import datetime, timezone

URL = os.environ.get("AI_AGENTS_DASHBOARD_URL", "http://127.0.0.1:7337/events")


def dashboard_up():
    u = urllib.parse.urlparse(URL)
    try:
        with socket.create_connection((u.hostname or "127.0.0.1", u.port or 80), timeout=0.2):
            return True
    except OSError:
        return False


def git(cwd, *args):
    try:
        out = subprocess.run(["git", "-C", cwd, *args], capture_output=True, text=True, timeout=1)
        return out.stdout.strip() if out.returncode == 0 else ""
    except Exception:
        return ""


def project_info(cwd):
    root = git(cwd, "rev-parse", "--show-toplevel") or cwd
    name = os.path.basename(root.rstrip("/")) or root
    try:
        with open(os.path.join(root, "CLAUDE.md"), encoding="utf-8") as f:
            m = re.search(r"^Nom du projet\s*:\s*(.+?)\s*$", f.read(), re.M)
            if m:
                name = m.group(1)
    except OSError:
        pass
    return {"root": root, "name": name}


def is_prompt(entry):
    """Vrai pour un message de l'utilisateur qui ouvre un tour (pas un résultat d'outil)."""
    if entry.get("type") != "user" or entry.get("isMeta") or entry.get("isSidechain"):
        return False
    content = (entry.get("message") or {}).get("content")
    if isinstance(content, str):
        return True
    if isinstance(content, list):
        return not any(isinstance(b, dict) and b.get("type") == "tool_result" for b in content)
    return False


def tokens(path, last_turn=False):
    """Somme des usages du fichier de session, ou du dernier tour seulement.

    Un même message apparaît sur plusieurs lignes : on garde sa dernière usage.
    """
    usages = {}
    model = None
    try:
        with open(os.path.expanduser(path), encoding="utf-8") as f:
            for n, line in enumerate(f):
                try:
                    entry = json.loads(line)
                except ValueError:
                    continue
                if last_turn and is_prompt(entry):
                    usages = {}
                    continue
                if last_turn and entry.get("isSidechain"):
                    continue
                msg = entry.get("message") or {}
                usage = msg.get("usage")
                if not isinstance(usage, dict):
                    continue
                usages[msg.get("id") or f"ligne-{n}"] = usage
                model = msg.get("model") or model
    except OSError:
        return None
    total = {"input": 0, "output": 0, "cache_creation": 0, "cache_read": 0, "model": model}
    for usage in usages.values():
        total["input"] += usage.get("input_tokens", 0) or 0
        total["output"] += usage.get("output_tokens", 0) or 0
        total["cache_creation"] += usage.get("cache_creation_input_tokens", 0) or 0
        total["cache_read"] += usage.get("cache_read_input_tokens", 0) or 0
    return total


def current_feature(root, branch):
    """Feature en cours : fichier .ai-agents/current écrit par /feature, sinon la branche."""
    try:
        with open(os.path.join(root, ".ai-agents", "current"), encoding="utf-8") as f:
            m = re.search(r"F-\d{8}-\d{3}", f.read())
            if m:
                return m.group(0)
    except OSError:
        pass
    m = re.search(r"F-\d{8}-\d{3}", branch or "")
    return m.group(0) if m else None


def build_event(data):
    cwd = data.get("cwd") or os.getcwd()
    branch = git(cwd, "branch", "--show-current")
    project = project_info(cwd)
    name = data.get("hook_event_name")
    event = {
        "v": 1,
        "ts": datetime.now(timezone.utc).isoformat(),
        "event": name,
        "session_id": data.get("session_id"),
        "agent_id": data.get("agent_id"),
        "agent_type": data.get("agent_type"),
        "project": project,
        "branch": branch or None,
        "feature_id": current_feature(project["root"], branch),
    }
    if data.get("tool_name"):
        event["tool"] = {
            "name": data.get("tool_name"),
            "use_id": data.get("tool_use_id"),
            "duration_ms": data.get("duration_ms"),
        }
    if name == "SubagentStop" and data.get("agent_transcript_path"):
        event["tokens"] = tokens(data["agent_transcript_path"])
    if name == "Stop" and data.get("transcript_path"):
        event["tokens"] = tokens(data["transcript_path"], last_turn=True)
    return event


def main():
    if not dashboard_up():
        return
    data = json.load(sys.stdin)
    body = json.dumps(build_event(data)).encode("utf-8")
    req = urllib.request.Request(URL, data=body, headers={"Content-Type": "application/json"}, method="POST")
    urllib.request.urlopen(req, timeout=1).close()


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
    sys.exit(0)
