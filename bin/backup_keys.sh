#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

BASE="$HOME/sirdi-project"
cd "$BASE"

log(){ printf "[%s] %s\n" "$(date '+%F %T')" "$*"; }

# -- Preconditions -----------------------------------------------------------

[[ -f sirdi.sec ]] || { echo "❌ Missing $BASE/sirdi.sec"; exit 1; }
command -v openssl >/dev/null || {
echo "⚠️  openssl not found; installing…"
sudo apt-get update -y && sudo apt-get install -y openssl
}

# -- 1) Ensure encrypted backup exists --------------------------------------

if [[ ! -f sirdi.sec.enc ]]; then
echo "🔐 Creating encrypted backup (AES-256, PBKDF2)…"
read -s -p "Enter passphrase: " PASS; echo
read -s -p "Confirm passphrase: " PASS2; echo
[[ "$PASS" == "$PASS2" ]] || { echo "❌ Passphrases do not match"; exit 1; }

# Sensitive block: no echoing

set +x
printf "%s" "$PASS" | \
openssl enc -aes-256-cbc -pbkdf2 -iter 250000 -salt \
-in sirdi.sec -out sirdi.sec.enc -pass stdin
unset PASS PASS2
set -x || true
set +x || true
echo "✅ Encrypted backup created: $BASE/sirdi.sec.enc"
else
echo "ℹ️  Using existing encrypted backup: $BASE/sirdi.sec.enc"
fi

# -- 2) Create/refresh checksum ---------------------------------------------

sha256sum sirdi.sec.enc | tee sirdi.sec.enc.sha256 >/dev/null
echo "🧾 Checksum written: $BASE/sirdi.sec.enc.sha256"

# Helper: copy + verify

copy_and_verify () {
local dest="$1"
mkdir -p "$dest"
cp sirdi.sec.enc sirdi.sec.enc.sha256 "$dest/"
( cd "$dest" && sha256sum -c sirdi.sec.enc.sha256 )
echo "✅ Verified copy at: $dest"
}

# -- 3) Copy to USB (you can change drive letter) ---------------------------

read -r -p "Copy to USB? [Y/n] " A; A=${A:-Y}
if [[ "$A" =~ ^[Yy]$ ]]; then
read -r -p "USB vault dir [/mnt/d/SIRDI-VAULT]: " USB_DIR
USB_DIR=${USB_DIR:-/mnt/d/SIRDI-VAULT}
copy_and_verify "$USB_DIR"
fi

# -- 4) Copy to cloud-synced folder (OneDrive by default) -------------------

read -r -p "Copy to cloud folder? [Y/n] " B; B=${B:-Y}
if [[ "$B" =~ ^[Yy]$ ]]; then

# Try to detect a Windows user with OneDrive, fallback to admin

WINUSER="$(ls -1 /mnt/c/Users 2>/dev/null | grep -v 'Public' | head -n1 || echo admin)"
DEFAULT_CLOUD="/mnt/c/Users/${WINUSER}/OneDrive/SIRDI-VAULT"
read -r -p "Cloud vault dir [${DEFAULT_CLOUD}]: " CLOUD_DIR
CLOUD_DIR=${CLOUD_DIR:-$DEFAULT_CLOUD}
copy_and_verify "$CLOUD_DIR"
fi

# -- 5) Optional restore self-test (no files kept) --------------------------

read -r -p "Run a restore self-test (decrypt to /tmp and compare)? [y/N] " C; C=${C:-N}
if [[ "$C" =~ ^[Yy]$ ]]; then
read -s -p "Enter passphrase to test decrypt: " TESTPASS; echo
set +x
printf "%s" "$TESTPASS" | \
openssl enc -d -aes-256-cbc -pbkdf2 -in sirdi.sec.enc -out /tmp/sirdi.sec.test -pass stdin
set -x || true
set +x || true
if diff -q /tmp/sirdi.sec.test sirdi.sec >/dev/null; then
echo "🧪 Restore test: OK"
else
echo "❌ Restore test FAILED (diff mismatch)"
fi
shred -u /tmp/sirdi.sec.test
unset TESTPASS
fi

echo "🎯 Done. Keep the passphrase in a password manager and (optionally) a sealed paper copy."
