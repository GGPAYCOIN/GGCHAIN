# GGCHAIN Developer SDK

Official SDKs to build on **GGCHAIN** (Chain ID `2121217`).

| Package | Install | Tested against | Status |
|---|---|---|---|
| **`@gghyper/sdk`** (JS / TS) | `npm install @gghyper/sdk` | `https://rpc.gghyper.net` | ✅ Working |
| **`gghyper-sdk`** (Python) | `pip install gghyper-sdk` | `https://rpc.gghyper.net` | ✅ Working |

## What's inside

Everything a developer needs to build a real app on GGCHAIN:

- ✅ JSON-RPC client (read/write)
- ✅ Native GG transfers
- ✅ Generic ERC-20 wrapper (any token)
- ✅ Contract deployment helper
- ✅ Multicall3 (batch reads in 1 RPC call)
- ✅ Gas-price + gas-estimate utilities
- ✅ Message signing + verification (EIP-191)
- ✅ Mining Pool REST client
- ✅ Blockscout Explorer REST client
- ✅ WebSocket event subscription (logs + new blocks)
- ✅ Add-to-MetaMask (EIP-3085) parameters

## Live infrastructure

| Service | URL |
|---|---|
| RPC | https://rpc.gghyper.net |
| WebSocket | wss://ws.gghyper.net |
| Explorer | https://explorer.gghyper.net |
| Mining Pool | https://pool.gghyper.net |
| **Multicall3** | `0x47D307a6c5516c3957AB942d0480D420aBBd4bcE` |
| Docs | https://sdk.gghyper.net (pending DNS) |

## Layout

```
/sdk/
├── js/              @gghyper/sdk        (TypeScript, builds to ESM + CJS + .d.ts)
│   ├── src/
│   │   ├── client.ts      — main GGChain class
│   │   ├── token.ts       — ERC-20 wrapper
│   │   ├── pool.ts        — mining pool client
│   │   ├── explorer.ts    — Blockscout client
│   │   ├── constants.ts   — chain params, ABIs
│   │   └── index.ts
│   ├── dist/        — built output (publish-ready)
│   ├── package.json
│   └── README.md    — usage docs
└── python/          gghyper-sdk         (Python 3.9+)
    ├── gghyper_sdk/
    │   ├── client.py
    │   ├── token.py
    │   ├── pool.py
    │   ├── explorer.py
    │   ├── constants.py
    │   └── __init__.py
    ├── pyproject.toml
    └── README.md
```

## Publishing checklist

To go live as public packages:

- [ ] **JS**: in `/sdk/js/` run `npm publish --access public` (requires npm token under `@gghyper` scope)
- [ ] **Python**: in `/sdk/python/` run `python -m build && twine upload dist/*` (requires PyPI token)
- [ ] **DNS**: add A record `sdk.gghyper.net` → `83.171.248.75` (then certbot SSL via VPS-1)
- [ ] **GitHub**: push both folders to `github.com/gghyper/sdk-js` and `gghyper/sdk-py` (Save-to-GitHub flow)

The SDK is **fully ready and tested** — just publishing & hosting remain.
