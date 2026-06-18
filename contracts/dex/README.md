# GGSwap DEX — Deployment Guide

Step-by-step instructions to deploy GGSwap (Uniswap V2-style AMM) on GGCHAIN Mainnet.

**You only deploy 3 contracts (WGG, Factory, Router). Pairs are created automatically when users add liquidity.**

---

## Prerequisites

- MetaMask connected to **GGCHAIN Mainnet** (Chain ID `2121217`)
- Wallet with at least **5 GG** for gas (deployment uses ~3 GG total)
- Remix IDE open: https://remix.ethereum.org

---

## Step 1 — Deploy WGG (Wrapped GG)

1. Remix → File Explorer → New file `WGG.sol`
2. Paste contents of [`01_WGG.sol`](./01_WGG.sol)
3. Solidity Compiler tab → Version `0.8.20+commit.a1b79de6`, optimizer **enabled, 200 runs**
4. Compile
5. Deploy & Run tab → Environment: **Injected Provider - MetaMask**
6. Contract: `WGG`
7. Click **Deploy** → MetaMask confirm
8. **📋 Copy the deployed address** → call this `WGG_ADDRESS`

Test: Send 0.1 GG to `WGG_ADDRESS` — `balanceOf(you)` should show `0.1 WGG`.

---

## Step 2 — Deploy GGSwapFactory

1. Remix → New file `GGSwapPair.sol` → paste [`02_GGSwapPair.sol`](./02_GGSwapPair.sol)
2. Remix → New file `GGSwapFactory.sol` → paste [`03_GGSwapFactory.sol`](./03_GGSwapFactory.sol)
3. Compile `GGSwapFactory.sol` (it imports the Pair automatically)
4. Deploy & Run → Contract: `GGSwapFactory`
5. Constructor argument `_feeToSetter`: paste **your wallet address** (you control LP fees)
6. Click **Deploy** → confirm
7. **📋 Copy the deployed address** → call this `FACTORY_ADDRESS`

---

## Step 3 — Deploy GGSwapRouter

1. Remix → New file `GGSwapRouter.sol` → paste [`04_GGSwapRouter.sol`](./04_GGSwapRouter.sol)
2. Compile
3. Deploy & Run → Contract: `GGSwapRouter`
4. Constructor arguments:
   - `_factory`: `FACTORY_ADDRESS` (from Step 2)
   - `_WGG`: `WGG_ADDRESS` (from Step 1)
5. Click **Deploy** → confirm
6. **📋 Copy the deployed address** → call this `ROUTER_ADDRESS`

---

## Step 4 — Create First Pair & Add Initial Liquidity

This is what gives the DEX something to swap.

### 4a. Approve USDT for Router

Go to USDT contract on Blockscout: `0x79Cce540c444AE1D7bDfd318CfBDB950147BcEc0`
→ Write Contract → Connect Wallet → call `approve`:
- `spender`: `ROUTER_ADDRESS`
- `amount`: `100000000000000000000000` (100,000 USDT in wei)

### 4b. Add Liquidity via Router

Go to your `ROUTER_ADDRESS` on Blockscout → Write Contract → `addLiquidityGG`:

| Parameter | Value | Notes |
|-----------|-------|-------|
| `token` | `0x79Cce540c444AE1D7bDfd318CfBDB950147BcEc0` | USDT address |
| `amountTokenDesired` | `10000000000000000000000` | 10,000 USDT (10000 * 1e18) |
| `amountTokenMin` | `9900000000000000000000` | 1% slippage |
| `amountGGMin` | `9900000000000000000000` | 1% slippage |
| `to` | your address | LP tokens recipient |
| `deadline` | `9999999999` | far future |
| `payableAmount` (GG) | `10000` | 10,000 GG to pair with USDT (set in "Value" field above) |

→ Write → MetaMask confirm

✅ **Pool created!** Initial price: 1 GG = 1 USDT.

You'll receive ~10,000 GG-LP tokens representing your share.

---

## Step 5 — Verify Contracts on Blockscout

For each deployed contract:
1. Open Blockscout: https://explorer.gghyper.net/address/CONTRACT_ADDRESS
2. **Code** tab → **Verify & Publish**
3. Method: Solidity (Single file)
4. Compiler: 0.8.20+commit.a1b79de6
5. Optimization: enabled, runs 200
6. License: MIT
7. Paste source code → Verify

This makes contracts readable on the explorer and trustworthy for users.

---

## Step 6 — Save Addresses

Save these in your `.env` for the frontend:

```env
NEXT_PUBLIC_CHAIN_ID=2121217
NEXT_PUBLIC_WGG_ADDRESS=0x...      # from Step 1
NEXT_PUBLIC_FACTORY_ADDRESS=0x...  # from Step 2
NEXT_PUBLIC_ROUTER_ADDRESS=0x...   # from Step 3
NEXT_PUBLIC_USDT_ADDRESS=0x79Cce540c444AE1D7bDfd318CfBDB950147BcEc0
```

---

## Common Issues

| Error | Cause | Fix |
|-------|-------|-----|
| `INSUFFICIENT_LIQUIDITY` | Pool not created yet | Run Step 4 |
| `EXPIRED` | `deadline` too small | Use `9999999999` |
| `TRANSFER_FROM_FAILED` | Forgot `approve` | Call `approve` first |
| `INSUFFICIENT_OUTPUT_AMOUNT` | High slippage | Lower amounts or raise pool liquidity |
| Gas estimation failed | Trying to swap with no liquidity | Add liquidity first |

---

## Architecture

```
                ┌────────────────┐
                │  GGSwapRouter  │  ← Users interact here
                └───────┬────────┘
                        │
              ┌─────────┴──────────┐
              ▼                    ▼
        ┌──────────┐         ┌──────────┐
        │  Factory │ creates │   Pair   │  (1 per token pair)
        └──────────┘         └──────────┘
                                  │
                            holds reserves of
                            ┌─────┴──────┐
                          token0       token1
                          (e.g. WGG)   (e.g. USDT)
```

- **WGG**: native GG wrapped as ERC-20 so it can be used in pools
- **Factory**: creates a `Pair` contract for each token combination
- **Pair**: implements AMM math (x * y = k), holds reserves, mints LP tokens
- **Router**: user-friendly entry point; handles native GG wrapping/unwrapping, multi-hop swaps, slippage protection

Fee: **0.30% on every swap**, goes to LPs proportional to their share.
