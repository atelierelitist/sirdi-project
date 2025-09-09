
# Security Policy

- Please **do not** submit secrets (private keys, passphrases) in issues or PRs.
- Report vulnerabilities privately: **security@your-domain** (PGP preferred).
- Scope includes scripts and verification logic. Personal keys/files (e.g. `sirdi.sec`) are **out of scope** and never stored in this repo.
- To verify provenance locally:

```bash
signify-openbsd -V -p sirdi.pub -m first_log.txt -x first_log.txt.sig
```
