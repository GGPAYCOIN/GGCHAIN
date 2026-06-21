# @gghyper/sdk

The official **GGCHAIN** developer SDK for JavaScript & TypeScript.

A tiny (≈15 KB) wrapper around `ethers v6` plus first-class clients for the GGCHAIN **Blockscout explorer**, **mining pool**, **multicall**, **gas helpers**, **contract deployment** and **WebSocket events** — everything you need to build apps, bots, indexers or scripts on top of GGCHAIN.

```bash
npm install @gghyper/sdk
# or
yarn add @gghyper/sdk
# or
pnpm add @gghyper/sdk
```

---

## Hello GGCHAIN

```ts
import { GGChain } from "@gghyper/sdk";

const gg = new GGChain();                      // → RPC: https://rpc.gghyper.net, chainId 2121217

console.log("Block:",   await gg.blockNumber());
console.log("Balance:", await gg.getBalance("0xfF3dBbD01B3B7A0613CB8A58C33B33Fd6c2db23a"), "GG");
```

## Reading any ERC-20

```ts
const usdt = gg.token("0xE77F05C01dac30901De8346c23242C4284dCb4aB");
await usdt.symbol();                     // "bUSDT"
await usdt.decimals();                   // 18
await usdt.balanceOf("0x…");             // human-readable string
await usdt.totalSupply();
```

## Signing & sending

```ts
const gg = new GGChain({ privateKey: process.env.PK });
await gg.send("0xBob…", "1.5");                       // 1.5 GG
await gg.token("0xE77F05…AB").transfer("0xBob", "100"); // 100 bUSDT
await gg.token("0xE77F05…AB").approve("0xSpender", "max");
const sig = await gg.signMessage("Login to MyDapp at " + Date.now());
```

## Arbitrary contracts

```ts
const myContract = gg.contract("0xMyContract…", MY_ABI);
const value = await myContract.someView();
const tx = await myContract.someWrite(arg1, arg2);
await gg.waitForTx(tx.hash);
```

## Deploying a contract

```ts
const { address, contract } = await gg.deploy(ABI, BYTECODE, [constructorArg1, constructorArg2]);
console.log("Deployed at", address);
```

## Multicall (batch RPC reads)

```ts
import { Interface } from "@gghyper/sdk";
const erc20 = new Interface(["function balanceOf(address) view returns (uint256)"]);

const results = await gg.multicall([
  { target: tokenA, callData: gg.encodeCall(erc20, "balanceOf", [user]) },
  { target: tokenB, callData: gg.encodeCall(erc20, "balanceOf", [user]) },
  { target: tokenC, callData: gg.encodeCall(erc20, "balanceOf", [user]) },
]);
// results[i] = { success: boolean, returnData: bytes }
```

## Mining Pool API

```ts
const stats = await gg.pool.stats();
console.log("Hashrate:", Pool.formatHash(stats.hashrate));
console.log("Active miners:", stats.minersTotal);

const me = await gg.pool.miner("0x…");
console.log("My workers:", me.workersOnline, "pending:", me.stats.balance);
```

## Explorer (Blockscout) API

```ts
const txs    = await gg.explorer.txList("0xAlice…");
const erc20s = await gg.explorer.tokenTransfers("0xAlice…");
const abi    = await gg.explorer.getContractABI("0xMyContract…");
const src    = await gg.explorer.getContractSource("0xMyContract…");
const url    = gg.explorer.url("0xMyContract…");
```

## WebSocket: live blocks & logs

```ts
const gg = new GGChain({ ws: "wss://ws.gghyper.net" });

const offBlock = gg.onBlock(n => console.log("block", n));
const offLogs  = gg.onLogs({ address: "0xMyContract…" }, log => console.log(log));

// later:
offBlock(); offLogs();
await gg.destroy();
```

## Add GGCHAIN to MetaMask (one-liner)

```ts
import { WALLET_PARAMS } from "@gghyper/sdk";
await (window as any).ethereum.request({ method: "wallet_addEthereumChain", params: [WALLET_PARAMS] });
```

## Browser Wallet Signer

```ts
import { BrowserProvider } from "ethers";
import { GGChain } from "@gghyper/sdk";

const provider = new BrowserProvider((window as any).ethereum);
const signer   = await provider.getSigner();
const gg       = new GGChain({ signer });
await gg.send("0xBob…", "1");
```

## Network Constants

```ts
import { GGCHAIN } from "@gghyper/sdk";
GGCHAIN.chainId;     // 2121217
GGCHAIN.chainIdHex;  // 0x205C81
GGCHAIN.rpc;         // https://rpc.gghyper.net
GGCHAIN.explorer;    // https://explorer.gghyper.net
GGCHAIN.pool;        // https://pool.gghyper.net
GGCHAIN.faucet;      // https://faucet.gghyper.net
```

## TypeScript

Full type definitions are bundled — `import type {…}` works everywhere.

```ts
import type { ClientOptions, MulticallReq, PoolStats } from "@gghyper/sdk";
```

## Bundle size

| Build  | Size (minified)   |
|--------|-------------------|
| ESM    | ~15 KB            |
| CJS    | ~16 KB            |

Tree-shakeable — only what you `import` lands in your bundle.

## License

MIT © GGHyper Labs · [github.com/gghyper/sdk-js](https://github.com/gghyper/sdk-js)
