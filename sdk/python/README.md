# gghyper-sdk (Python)

Official Python SDK for **GGCHAIN**. Built on `web3.py`.

```bash
pip install gghyper-sdk
```

## Quick Start

```python
from gghyper_sdk import GGChain

gg = GGChain()                                  # read-only via default RPC
print("Block:", gg.block_number())
print("Bal:", gg.get_balance("0xfF3dBbD0..."))

# Wrap any ERC-20
usdt = gg.token("0xE77F05C01dac30901De8346c23242C4284dCb4aB")
print(usdt.symbol(), usdt.balance_of("0xfF3dBbD0..."))
```

### Signing

```python
gg = GGChain(private_key=os.environ["PK"])
tx_hash = gg.send("0xBob...", "1.5")            # 1.5 GG
print(gg.explorer.url(tx_hash))
gg.wait_for_tx(tx_hash)
```

### Deploy a contract

```python
abi = [...]
bytecode = "0x60806040..."
result = gg.deploy(abi, bytecode, [constructor_arg1, constructor_arg2])
print("Deployed at:", result["address"])
```

### Multicall (batch reads)

```python
from gghyper_sdk import ABI_ERC20
from web3 import Web3

erc20 = gg.w3.eth.contract(abi=ABI_ERC20)
calls = [
    {"target": tokenA, "callData": erc20.encode_abi("balanceOf", [user])},
    {"target": tokenB, "callData": erc20.encode_abi("balanceOf", [user])},
]
for r in gg.multicall(calls):
    print(r["success"], r["returnData"])
```

### Mining Pool

```python
stats = gg.pool.stats()
print(gg.pool.format_hash(stats.hashrate), "·", stats.miners_total, "miners")
print(gg.pool.miner("0xfF3dBbD0...").workers_online)
```

### Explorer

```python
txs   = gg.explorer.tx_list("0xAlice", page=1, offset=20)
abi   = gg.explorer.get_contract_abi("0xMyContract...")
url   = gg.explorer.url("0xMyContract...")
```

### Real-time logs

```python
gg = GGChain(ws="wss://ws.gghyper.net")
for log in gg.subscribe_logs(address="0xMyContract..."):
    print(log["topics"], log["data"])
```

### Sign / verify messages

```python
sig = gg.sign_message("Login at " + str(int(time.time())))
who = GGChain.verify_message("Login at " + str(int(time.time())), sig)
```

## License

MIT
