# GGPAY Mainnet (GGCHAIN)

<p align="center">
  <img src="https://copper-gentle-roadrunner-403.mypinata.cloud/ipfs/bafybeigaegrb7lxyeeclrgjsu5griupp22c2z7sb4caq7x3n3mhqzanu3i" width="180" alt="GGPAY Logo"/>
</p>

<h3 align="center">The Next Generation Blockchain Payment Ecosystem</h3>

<p align="center">
  <a href="https://gghyper.net"><img alt="Website" src="https://img.shields.io/badge/Website-gghyper.net-amber?style=flat-square"></a>
  <a href="https://explorer.gghyper.net"><img alt="Explorer" src="https://img.shields.io/badge/Explorer-Blockscout-green?style=flat-square"></a>
  <a href="https://t.me/GGWPAYCOIN"><img alt="Telegram" src="https://img.shields.io/badge/Telegram-Join-blue?style=flat-square"></a>
  <a href="https://x.com/GGPAYCOIN"><img alt="Twitter" src="https://img.shields.io/badge/Twitter-Follow-1DA1F2?style=flat-square"></a>
</p>

---

## 🌐 Network Specs

| Property         | Value                              |
|------------------|------------------------------------|
| **Network Name** | GGCHAIN Mainnet                    |
| **Chain ID**     | `2121217`                          |
| **Symbol**       | `GG`                               |
| **Decimals**     | `18`                               |
| **Consensus**    | Proof-of-Work (Ethash)             |
| **Block Reward** | `3 GG` per block                   |
| **Max Supply**   | `21,000,000 GG`                    |
| **Block Time**   | ~15 seconds                        |
| **EVM**          | Compatible (Solidity ready)        |

## 🔌 Endpoints

| Service              | URL                                       |
|----------------------|-------------------------------------------|
| Project Website      | https://gghyper.net                       |
| Block Explorer       | https://explorer.gghyper.net              |
| RPC (HTTP)           | https://rpc.gghyper.net                   |
| RPC (WebSocket)      | wss://rpc.gghyper.net/ws                  |
| Mobile App (APK)     | https://ggpayfinance.com/apk/ggpay-mining.apk |

## 🦊 Add to MetaMask

```
Network Name:  GGCHAIN Mainnet
RPC URL:       https://rpc.gghyper.net
Chain ID:      2121217
Symbol:        GG
Explorer:      https://explorer.gghyper.net
```

Or visit [gghyper.net](https://gghyper.net) and click **"Add Network"** (one-click).

## 💰 Deployed Tokens

| Token         | Symbol | Contract Address                            | Supply    |
|---------------|--------|---------------------------------------------|-----------|
| Tether GGPAY  | USDT   | `0x79Cce540c444AE1D7bDfd318CfBDB950147BcEc0`| 1,000,000 |

## ⛏️ Mining

GGCHAIN uses **Ethash** Proof-of-Work consensus. See [docs/mining-guide.md](docs/mining-guide.md) to start mining.

Quick start with `geth`:

```bash
geth --networkid 2121217 \
     --syncmode full \
     --gcmode archive \
     --mine --miner.threads 4 \
     --miner.etherbase 0xYOUR_ADDRESS \
     --http --http.addr 0.0.0.0 --http.port 8545 \
     --http.api eth,net,web3,personal,miner
```

## 📁 Repository Structure

```
.
├── contracts/        Smart contracts (USDT, ERC-20 template)
├── docs/             Documentation (mining, RPC, network)
├── assets/           Logos & branding
├── config/           Deployment configs (systemd, nginx)
└── README.md
```

## 🌍 Community

| Platform | Link                                |
|----------|-------------------------------------|
| Twitter  | https://x.com/GGPAYCOIN             |
| Telegram | https://t.me/GGWPAYCOIN             |
| Discord  | https://discord.gg/rM2UrHT3N        |
| Email    | Info@glogreenfinance.com            |

## 📜 License

MIT License - see [LICENSE](LICENSE) file.

---

<p align="center">
  © 2026 GGPAY • Pay Smarter. Move Faster.
</p>
