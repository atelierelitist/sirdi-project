#!/usr/bin/env python3
import os, sys, json, hashlib, datetime, pathlib
from stellar_sdk import Keypair, Server, Network, TransactionBuilder, MemoHash
from stellar_sdk.operation.bump_sequence import BumpSequence

def canon_bytes(obj) -> bytes:
    return json.dumps(obj, sort_keys=True, separators=(",", ":")).encode("utf-8")

def now_iso():
    return datetime.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"

def main():
    if len(sys.argv) != 2:
        print("Usage: badge_mint_anchored.py <ATTESTATION_JSON>", file=sys.stderr)
        sys.exit(1)

    att_path = pathlib.Path(sys.argv[1]).resolve()
    if not att_path.exists():
        print(f"Attestation not found: {att_path}", file=sys.stderr)
        sys.exit(1)

    # Env (already set by .env)
    STELLAR_SECRET = os.getenv("STELLAR_SECRET")
    STELLAR_PUBLIC = os.getenv("STELLAR_PUBLIC")
    HORIZON = os.getenv("STELLAR_HORIZON", "https://horizon-testnet.stellar.org")
    NET = os.getenv("STELLAR_NETWORK", "TESTNET").upper()

    if not STELLAR_SECRET or not STELLAR_PUBLIC:
        print("Missing STELLAR_SECRET or STELLAR_PUBLIC in environment.", file=sys.stderr)
        sys.exit(1)

    if NET != "TESTNET":
        passphrase = Network.PUBLIC_NETWORK_PASSPHRASE
    else:
        passphrase = Network.TESTNET_NETWORK_PASSPHRASE

    # Load attestation
    att = json.loads(att_path.read_text())
    learner = att.get("learner", "anonymous")
    quest   = att.get("quest", "sovereign-citizen-primer")
    issued  = att.get("issued_at") or now_iso()

    # Build badge metadata (pre-anchor)
    meta = {
        "type": "sovereign_skill_badge",
        "name": f"{quest} — Verified",
        "description": "Verifiable Sovereign Skill Badge anchored on Stellar.",
        "learner": learner,
        "quest": quest,
        "attestation_path": str(att_path.relative_to(pathlib.Path.cwd())),
        "attestation_sha256": hashlib.sha256(att_path.read_bytes()).hexdigest(),
        "issued_at": issued,
        "issuer": "SIRDI",
        "chain_anchor": None  # will be filled after tx
    }

    # Canonical hash for memo
    digest = hashlib.sha256(canon_bytes(meta)).digest()

    # Build + submit Stellar tx with MemoHash + BumpSequence(no-op)
    server = Server(horizon_url=HORIZON)
    kp = Keypair.from_secret(STELLAR_SECRET)
    account = server.load_account(kp.public_key)
    base_fee = 100

    tx = (
        TransactionBuilder(
            source_account=account,
            network_passphrase=passphrase,
            base_fee=base_fee,
        )
        .add_memo(MemoHash(digest))
        .append_operation(BumpSequence(bump_to=int(account.sequence) + 1))
        .set_timeout(120)
        .build()
    )
    tx.sign(kp)
    resp = server.submit_transaction(tx)
    tx_id = resp["hash"]

    meta["chain_anchor"] = {
        "network": NET,
        "horizon": HORIZON,
        "tx_id": tx_id,
        "memo_hash_hex": hashlib.sha256(canon_bytes(meta)).hexdigest(),
        "anchored_at": now_iso(),
    }

    # Save badge JSON
    out_dir = pathlib.Path("veritas/badges")
    out_dir.mkdir(parents=True, exist_ok=True)
    stamp = datetime.datetime.utcnow().strftime("%Y%m%d-%H%M%S")
    safe_learner = "".join(c for c in learner if c.isalnum() or c in ("-", "_")).strip() or "anon"
    out_path = out_dir / f"{stamp}_{quest}_{safe_learner}_badge.json"
    out_path.write_text(json.dumps(meta, indent=2))
    print(f"✅ Anchored. Badge written: {out_path}")
    print(f"🔗 Stellar tx: {tx_id}")

if __name__ == "__main__":
    main()
