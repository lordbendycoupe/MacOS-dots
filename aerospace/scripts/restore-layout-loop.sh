#!/usr/bin/env zsh
# Run from AeroSpace's after-startup-command. A single restore pass at
# startup misses apps macOS is still relaunching from the login-item list
# (Chrome, Discord etc. can take well past AeroSpace's own startup to
# reopen), so this retries for a couple minutes to catch them as they
# appear.
SCRIPT_DIR="${0:A:h}"

for _ in {1..40}; do
  "$SCRIPT_DIR/restore-layout.py"
  sleep 3
done
