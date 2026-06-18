# GGCHAIN Smart Contracts

EVM-compatible Solidity contracts deployed on GGCHAIN Mainnet (Chain ID: 2121217).

## Deployed Contracts

### Tether GGPAY (USDT)
- **Contract:** [`0x79Cce540c444AE1D7bDfd318CfBDB950147BcEc0`](https://explorer.gghyper.net/token/0x79Cce540c444AE1D7bDfd318CfBDB950147BcEc0)
- **Symbol:** USDT
- **Decimals:** 18
- **Total Supply:** 1,000,000
- **Source:** [GGPAY_USDT.sol](GGPAY_USDT.sol)
- **Standard:** ERC-20 with mint (owner-only)

## Templates

- [GGToken.sol](GGToken.sol) - Basic ERC-20 token template (no dependencies)

## Deploy Your Own Token

1. Open https://remix.ethereum.org
2. Copy `GGToken.sol` into a new file
3. Compile with Solidity `0.8.20+`
4. Deploy & Run Transactions → Environment: **Injected Provider - MetaMask**
5. Confirm MetaMask is on GGCHAIN Mainnet (Chain ID 2121217)
6. Set `initialSupply` value → Deploy
7. Verify on https://explorer.gghyper.net/

## Verification on Blockscout

After deploying:
1. Visit your contract page on explorer.gghyper.net
2. Click "Code" tab → "Verify & Publish"
3. Method: Solidity (Flattened source)
4. Compiler: 0.8.20+commit.a1b79de6
5. Paste flattened source code → Verify
