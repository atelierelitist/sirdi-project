    #\!/usr/bin/env bash
    set -euo pipefail
    cd ~/sirdi-project
    echo "== Git status (public-safe) =="
    git status -s || git init
    git add first_log.txt first_log.txt.sig sirdi.pub .gitignore bin/ brain/
    git commit -m "doc: update HOW-TOs & public artifacts" || echo "Nothing to commit."
    git log --oneline -n 3 || true
