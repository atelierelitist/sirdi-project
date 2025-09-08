    #\!/usr/bin/env bash
    set -euo pipefail
    cd ~/sirdi-project
    lesson="${1:-lesson}"; shift || true
    ts="$(date +%Y-%m-%d_%H-%M-%S)"
    log="logs/${ts}__${lesson}.log"
    ( set -x; "$@" ) 2>&1 | tee "$log"
    if [[ -f sirdi.sec ]]; then
    signify-openbsd -S -s sirdi.sec -m "$log" 2>/dev/null || true
    fi
    note="brain/howto_${lesson}.md"
    {
    echo "# HOW-TO: ${lesson//-/ }"
    echo
    echo "## Command"
    printf '`bash\\n%s\\n`\n' "$*"
    echo "## Log"
    echo "File: $log"
    [[ -f ${log}.sig ]] && echo "Signature: ${log}.sig"
    [[ -f ${log}.sig ]] && \
    echo "Verify: signify-openbsd -V -p sirdi.pub -m $log -x ${log}.sig"
    } > "$note"
    echo "🧠 Knowledge stored: $note"
    echo "🗒 Log: $log"
