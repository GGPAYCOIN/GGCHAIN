/**
 * @gghyper/sdk — Official GGCHAIN developer SDK.
 *
 * Quick start:
 *   import { GGChain } from "@gghyper/sdk";
 *   const gg = new GGChain();
 *   await gg.getBalance("0x…");                    // GG balance
 *   const t = gg.token("0xErc20…");                // wrap any ERC-20
 *   await t.balanceOf("0x…");
 *   await gg.pool.stats();                         // mining pool API
 *   await gg.explorer.txList("0x…");               // explorer API
 *
 * Write:
 *   const gg = new GGChain({ privateKey: process.env.PK });
 *   await gg.send("0xBob", "1.5");                 // 1.5 GG
 *   await gg.deploy(abi, bytecode, [arg1, arg2]);  // deploy a contract
 *
 * Multicall:
 *   const res = await gg.multicall([
 *     { target: tokenA, callData: gg.encodeCall(iface, "balanceOf", ["0x…"]) },
 *     { target: tokenB, callData: gg.encodeCall(iface, "balanceOf", ["0x…"]) },
 *   ]);
 *
 * Events (WebSocket):
 *   const gg = new GGChain({ ws: "wss://ws.gghyper.net" });
 *   const off = gg.onLogs({ address: "0x…" }, (log) => console.log(log));
 */

export { GGChain } from "./client.js";
export type { ClientOptions, MulticallReq, MulticallRes } from "./client.js";

export { Token } from "./token.js";
export { Pool, type PoolStats, type MinerStats } from "./pool.js";
export { Explorer } from "./explorer.js";

export {
  GGCHAIN, WALLET_PARAMS, ABI_ERC20, MULTICALL3, ABI_MULTICALL3,
} from "./constants.js";

// Re-export common ethers utilities so most apps don't need to install ethers separately.
export {
  formatEther, parseEther, formatUnits, parseUnits,
  keccak256, toUtf8Bytes, getAddress, isAddress, ZeroAddress, MaxUint256,
  Wallet, Interface, Contract,
} from "ethers";
