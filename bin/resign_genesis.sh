    #\!/usr/bin/env bash
    set -euo pipefail
    cd ~/sirdi-project
    sudo chattr -i first_log.txt first_log.txt.sig 2>/dev/null || true
    chmod u+w first_log.txt first_log.txt.sig 2>/dev/null || true
    signify-openbsd -S -s sirdi.sec -m first_log.txt
    signify-openbsd -V -p sirdi.pub -m first_log.txt -x first_log.txt.sig
    chmod 0444 first_log.txt first_log.txt.sig
    sudo chattr +i first_log.txt first_log.txt.sig 2>/dev/null || true
    echo "✅ Genesis log re-signed, verified, and locked."
