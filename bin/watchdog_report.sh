    #\!/usr/bin/env bash
    set -euo pipefail
    cd ~/sirdi-project
    echo "== SIRDI Watchdog =="
    date
    ps aux | grep -i sirdi_watchdog | grep -v grep || true
    tail -n 40 sirdi_watchdog.log 2>/dev/null || echo "No watchdog log yet."
    echo
    echo "== Genesis signature check =="
    signify-openbsd -V -p sirdi.pub -m first_log.txt -x first_log.txt.sig && echo "Signature Verified"
