const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const StellarSdk = require('stellar-sdk');
const {Keypair, Networks, TransactionBuilder, Operation, Asset, Memo} = StellarSdk;
const {Server} = StellarSdk.Horizon;

(async () => {
const anchorsDir = path.join(process.cwd(), 'anchors');

// pick file from arg or use the newest *_anchor.json
let file = process.argv[2];
if (!file || file === 'latest') {
const files = fs.readdirSync(anchorsDir).filter(f => f.endsWith('_anchor.json')).sort();
if (!files.length) throw new Error('No anchor manifests found in anchors/');
file = path.join(anchorsDir, files[files.length - 1]);
} else {
file = path.isAbsolute(file) ? file : path.join(process.cwd(), file);
}

const data = fs.readFileSync(file);
const sha = crypto.createHash('sha256').update(data).digest(); // 32 bytes
const shaHex = sha.toString('hex');

const server = new Server('https://horizon-testnet.stellar.org');
const kp = Keypair.random();

// fund the account on testnet
const fb = await fetch(`https://friendbot.stellar.org?addr=${kp.publicKey()}`);
if (!fb.ok) throw new Error('Friendbot funding failed');
await fb.text();

// memo = SHA256(anchor.json) -> immutable anchor
const account = await server.loadAccount(kp.publicKey());
const fee = await server.fetchBaseFee();
const tx = new TransactionBuilder(account, {
fee,
networkPassphrase: Networks.TESTNET,
memo: Memo.hash(sha)
})
.addOperation(Operation.payment({
destination: kp.publicKey(),
asset: Asset.native(),
amount: '0.00001' // dust self-payment; memo carries the proof
}))
.setTimeout(180)
.build();

tx.sign(kp);
const res = await server.submitTransaction(tx);

// augment the manifest with on-chain proof
const j = JSON.parse(data.toString());
j.stellar_anchor = {
network: 'TESTNET',
txid: res.hash,
memo_sha256: shaHex,
anchored_at_utc: new Date().toISOString()
};
fs.writeFileSync(file, JSON.stringify(j, null, 2));

console.log('\nAnchored ✔');
console.log('Manifest:', file);
console.log('TXID:', res.hash);
console.log('Explorer:', `https://stellar.expert/explorer/testnet/tx/${res.hash}`);
})();
