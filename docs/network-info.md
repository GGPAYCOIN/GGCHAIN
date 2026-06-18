# GGCHAIN Network Information

## Mainnet Configuration

- **Network Name:** GGCHAIN Mainnet  
- **Chain ID:** 2121217 (0x205E01)  
- **Currency Symbol:** GG  
- **Decimals:** 18  
- **Consensus:** Proof-of-Work (Ethash)  
- **Block Time:** ~15 seconds  
- **Block Reward:** 3 GG per block  
- **Max Supply:** 21,000,000 GG  

## Endpoints

### JSON-RPC (HTTP)
```
https://rpc.gghyper.net
```

### WebSocket
```
wss://rpc.gghyper.net/ws
```

### Block Explorer
```
https://explorer.gghyper.net
```

## Supported RPC Methods

All standard `eth_*`, `net_*`, `web3_*`, `miner_*`, `personal_*` namespaces.

### Quick Test

```bash
curl -X POST https://rpc.gghyper.net \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'
```

Response:
```json
{"jsonrpc":"2.0","id":1,"result":"0x205e01"}
```

## Connect via Web3 Libraries

### ethers.js (v6)
```js
import { JsonRpcProvider } from "ethers";
const provider = new JsonRpcProvider("https://rpc.gghyper.net");
const block = await provider.getBlockNumber();
```

### web3.js
```js
const Web3 = require("web3");
const web3 = new Web3("https://rpc.gghyper.net");
const chainId = await web3.eth.getChainId();
```

### viem
```js
import { createPublicClient, http } from "viem";
const client = createPublicClient({
  chain: { id: 2121217, name: "GGCHAIN", nativeCurrency: { symbol: "GG", decimals: 18 } },
  transport: http("https://rpc.gghyper.net")
});
```
