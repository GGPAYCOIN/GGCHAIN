# GGCHAIN Mining Guide

GGCHAIN uses **Ethash** Proof-of-Work consensus. Anyone can mine GG with consumer hardware.

## Requirements

- Linux/Mac/Windows machine
- 8+ GB RAM (Ethash DAG ~5GB)
- CPU or GPU (NVIDIA/AMD)
- 50+ GB free disk (for chain data)
- Geth (Go-Ethereum) v1.13.15 or earlier (PoW supported)

## Setup with Geth

### 1. Install Geth

```bash
# Ubuntu/Debian
add-apt-repository -y ppa:ethereum/ethereum
apt-get update && apt-get install -y ethereum
```

### 2. Create Mining Account

```bash
geth --datadir ~/.ggchain account new
```
Save the address and password securely!

### 3. Start Mining Node

```bash
geth --networkid 2121217 \
     --datadir ~/.ggchain \
     --syncmode full \
     --gcmode archive \
     --mine --miner.threads 4 \
     --miner.etherbase 0xYOUR_ADDRESS \
     --http --http.addr 0.0.0.0 --http.port 8545 \
     --http.api eth,net,web3,personal,miner \
     --bootnodes "ENODE_URL_HERE"
```

## Run as systemd Service

Save as `/etc/systemd/system/ggchain-geth.service`:

```ini
[Unit]
Description=GGCHAIN Geth Node
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/geth \
  --networkid 2121217 \
  --datadir /root/.ggchain \
  --syncmode full --gcmode archive \
  --mine --miner.threads 4 \
  --miner.etherbase 0xYOUR_ADDRESS \
  --http --http.addr 0.0.0.0 --http.port 8545
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
systemctl daemon-reload
systemctl enable --now ggchain-geth
journalctl -u ggchain-geth -f
```

## Verify Mining

```bash
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_mining","params":[],"id":1}'
```

Should return `"result":true`.

## Block Reward

- **3 GG per block** auto-credited to `--miner.etherbase`
- Block time: ~15 seconds
- Approx. daily rewards: `3 × (86400/15) ≈ 17,280 GG/day` (network-wide, split among all miners)

## Tips

- Use **4-8 mining threads** for CPU mining
- Run on **dedicated server/VPS** for 24/7 uptime
- Connect to **archive mode** for full history (`--gcmode archive`)
- Monitor with [explorer.gghyper.net](https://explorer.gghyper.net)
