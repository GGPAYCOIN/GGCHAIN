"""GGCHAIN canonical network parameters and core ABIs."""
GGCHAIN = {
    "chain_id": 2121217,
    "chain_id_hex": "0x205C81",
    "name": "GGCHAIN",
    "symbol": "GG",
    "decimals": 18,
    "rpc": "https://rpc.gghyper.net",
    "ws": "wss://ws.gghyper.net",
    "explorer": "https://explorer.gghyper.net",
    "faucet": "https://faucet.gghyper.net",
    "pool": "https://pool.gghyper.net",
}

WALLET_PARAMS = {
    "chainId": GGCHAIN["chain_id_hex"],
    "chainName": GGCHAIN["name"],
    "nativeCurrency": {"name": "GG", "symbol": GGCHAIN["symbol"], "decimals": GGCHAIN["decimals"]},
    "rpcUrls": [GGCHAIN["rpc"]],
    "blockExplorerUrls": [GGCHAIN["explorer"]],
}

MULTICALL3 = "0x47D307a6c5516c3957AB942d0480D420aBBd4bcE"

ABI_MULTICALL3 = [
    {"name": "aggregate3", "type": "function", "stateMutability": "payable",
     "inputs": [{"name": "calls", "type": "tuple[]",
                 "components": [{"name": "target", "type": "address"},
                                {"name": "allowFailure", "type": "bool"},
                                {"name": "callData", "type": "bytes"}]}],
     "outputs": [{"name": "", "type": "tuple[]",
                  "components": [{"name": "success", "type": "bool"},
                                 {"name": "returnData", "type": "bytes"}]}]},
    {"name": "getBlockNumber", "type": "function", "stateMutability": "view", "inputs": [], "outputs": [{"type": "uint256"}]},
    {"name": "getEthBalance", "type": "function", "stateMutability": "view",
     "inputs": [{"name": "addr", "type": "address"}], "outputs": [{"type": "uint256"}]},
]

ABI_ERC20 = [
    {"name":"name","type":"function","stateMutability":"view","inputs":[],"outputs":[{"type":"string"}]},
    {"name":"symbol","type":"function","stateMutability":"view","inputs":[],"outputs":[{"type":"string"}]},
    {"name":"decimals","type":"function","stateMutability":"view","inputs":[],"outputs":[{"type":"uint8"}]},
    {"name":"totalSupply","type":"function","stateMutability":"view","inputs":[],"outputs":[{"type":"uint256"}]},
    {"name":"balanceOf","type":"function","stateMutability":"view","inputs":[{"name":"o","type":"address"}],"outputs":[{"type":"uint256"}]},
    {"name":"allowance","type":"function","stateMutability":"view","inputs":[{"name":"o","type":"address"},{"name":"s","type":"address"}],"outputs":[{"type":"uint256"}]},
    {"name":"approve","type":"function","stateMutability":"nonpayable","inputs":[{"name":"s","type":"address"},{"name":"a","type":"uint256"}],"outputs":[{"type":"bool"}]},
    {"name":"transfer","type":"function","stateMutability":"nonpayable","inputs":[{"name":"to","type":"address"},{"name":"a","type":"uint256"}],"outputs":[{"type":"bool"}]},
    {"name":"transferFrom","type":"function","stateMutability":"nonpayable","inputs":[{"name":"f","type":"address"},{"name":"t","type":"address"},{"name":"a","type":"uint256"}],"outputs":[{"type":"bool"}]},
]
