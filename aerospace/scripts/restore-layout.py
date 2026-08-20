#!/usr/bin/env python3
"""Moves currently-open windows back to the workspace they were on in the
last saved snapshot (workspace-state.json). Matches windows to saved slots
by app bundle-id and position in AeroSpace's own listing order -- there's
no persistent per-window identity across a relaunch, so with N windows of
the same app this is a best-effort assignment, not a guaranteed exact
mapping back to the original window.

Safe to run repeatedly: a window already on its saved workspace is a
no-op. restore-layout-loop.sh calls this every few seconds for a while
after AeroSpace starts, since macOS relaunches login-item apps gradually
rather than all at once.
"""
import json
import os
import subprocess
import sys

STATE_FILE = os.path.expanduser("~/.config/aerospace/workspace-state.json")
# Same reasoning as save-layout.sh: don't rely on PATH containing homebrew.
AEROSPACE = "/opt/homebrew/bin/aerospace"


def main():
    if not os.path.exists(STATE_FILE):
        return

    try:
        with open(STATE_FILE) as f:
            saved = json.load(f)
    except (OSError, json.JSONDecodeError):
        return

    out = subprocess.run(
        [AEROSPACE, "list-windows", "--all", "--format",
         "%{app-bundle-id}|%{window-id}|%{workspace}"],
        capture_output=True, text=True,
    )

    current = {}
    for line in out.stdout.splitlines():
        parts = line.split("|")
        if len(parts) != 3:
            continue
        bid, wid, ws = parts
        current.setdefault(bid, []).append((wid, ws))

    for bid, target_list in saved.items():
        windows = current.get(bid, [])
        for i, (wid, cur_ws) in enumerate(windows):
            if i >= len(target_list):
                break
            target_ws = target_list[i]
            if cur_ws != target_ws:
                subprocess.run(
                    [AEROSPACE, "move-node-to-workspace", target_ws,
                     "--window-id", wid],
                    capture_output=True,
                )


if __name__ == "__main__":
    main()
