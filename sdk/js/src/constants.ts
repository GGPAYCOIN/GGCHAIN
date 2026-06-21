/** GGCHAIN core network parameters. */
export const GGCHAIN = {
  chainId: 2121217,
  chainIdHex: "0x205C81",
  name: "GGCHAIN",
  symbol: "GG",
  decimals: 18,
  rpc: "https://rpc.gghyper.net",
  ws: "wss://ws.gghyper.net",
  explorer: "https://explorer.gghyper.net",
  faucet: "https://faucet.gghyper.net",
  pool: "https://pool.gghyper.net",
} as const;

/** Add-to-wallet (EIP-3085) parameters. */
export const WALLET_PARAMS = {
  chainId: GGCHAIN.chainIdHex,
  chainName: GGCHAIN.name,
  nativeCurrency: { name: "GG", symbol: GGCHAIN.symbol, decimals: GGCHAIN.decimals },
  rpcUrls: [GGCHAIN.rpc],
  blockExplorerUrls: [GGCHAIN.explorer],
} as const;

/** Minimal ERC-20 ABI fragments. */
export const ABI_ERC20 = [
  "function name() view returns (string)",
  "function symbol() view returns (string)",
  "function decimals() view returns (uint8)",
  "function totalSupply() view returns (uint256)",
  "function balanceOf(address) view returns (uint256)",
  "function allowance(address,address) view returns (uint256)",
  "function approve(address,uint256) returns (bool)",
  "function transfer(address,uint256) returns (bool)",
  "function transferFrom(address,address,uint256) returns (bool)",
  "event Transfer(address indexed from, address indexed to, uint256 value)",
  "event Approval(address indexed owner, address indexed spender, uint256 value)",
] as const;

/** Multicall3 deployed on GGCHAIN. */
export const MULTICALL3 = "0x47D307a6c5516c3957AB942d0480D420aBBd4bcE" as const;

export const ABI_MULTICALL3 = [
  "function aggregate3((address target, bool allowFailure, bytes callData)[] calls) payable returns ((bool success, bytes returnData)[])",
  "function getBlockNumber() view returns (uint256)",
  "function getEthBalance(address addr) view returns (uint256)",
] as const;
