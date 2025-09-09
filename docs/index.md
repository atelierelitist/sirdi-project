
# SIRDI Project — Public Genesis

**SIRDI** = *Sentient Intelligence for Real-time Dialogue & Insight*

This repo publishes the **verifiable genesis** of the SIRDI stack and a minimal, safe
project skeleton (no secrets).

---

## 🧾 What's in here

- `first_log.txt` — the genesis log (read-only)
- `first_log.txt.sig` — signature for the genesis log
- `sirdi.pub` — public key used to verify signatures
- `bin/` — executable rituals (automation scripts)
- `brain/` — HOW-TO knowledge (self-teaching docs)
- `.auggie/tasks.yaml` — Auggie task library (automation entrypoints)

Private artifacts like `sirdi.sec` (secret key) and runtime logs are **not** included.

---

## ✅ Verify the Genesis (any Linux/macOS with signify-openbsd)

```bash
# Clone this repo, cd into it, then run:
signify-openbsd -V -p sirdi.pub -m first_log.txt -x first_log.txt.sig
```

[\![Verify Genesis](https://github.com/<USER>/<REPO>/actions/workflows/verify-genesis.yml/badge.svg)](https://github.com/<USER>/<REPO>/actions/workflows/verify-genesis.yml)
