"""GGChain Python SDK — main client."""
from __future__ import annotations
from typing import Any, Callable, List, Optional, Union, Dict
from decimal import Decimal
from web3 import Web3
from web3.contract import Contract as Web3Contract
from web3.types import TxReceipt
from eth_account import Account
from eth_account.messages import encode_defunct
from eth_account.signers.local import LocalAccount

from .constants import GGCHAIN, MULTICALL3, ABI_MULTICALL3
from .token import Token
from .pool import Pool
from .explorer import Explorer


class GGChain:
    """The GGCHAIN Python SDK entry-point."""

    def __init__(self, rpc: Optional[str] = None, private_key: Optional[str] = None, ws: Optional[str] = None):
        self.w3 = Web3(Web3.HTTPProvider(rpc or GGCHAIN["rpc"]))
        self._ws_url = ws
        self._account: Optional[LocalAccount] = None
        if private_key:
            self._account = Account.from_key(private_key)
        self.pool = Pool(GGCHAIN["pool"])
        self.explorer = Explorer(GGCHAIN["explorer"])

    # ─── Signer ──────────────────────────────────────────────────────
    def connect(self, private_key: str) -> "GGChain":
        self._account = Account.from_key(private_key)
        return self

    @property
    def account(self) -> LocalAccount:
        if not self._account:
            raise RuntimeError("No signer. Pass private_key= or call .connect()")
        return self._account

    @property
    def address(self) -> str: return self.account.address

    @property
    def has_signer(self) -> bool: return self._account is not None

    # ─── Native GG ───────────────────────────────────────────────────
    def get_balance(self, address: Optional[str] = None) -> str:
        a = Web3.to_checksum_address(address or self.address)
        return str(Decimal(self.w3.eth.get_balance(a)) / Decimal(10**18))

    def send(self, to: str, amount: Union[str, Decimal]) -> str:
        amt = int(Decimal(str(amount)) * (10**18))
        tx = {
            "to": Web3.to_checksum_address(to),
            "value": amt,
            "nonce": self.w3.eth.get_transaction_count(self.address),
            "gas": 21000,
            "gasPrice": self.w3.eth.gas_price,
            "chainId": GGCHAIN["chain_id"],
        }
        signed = self.account.sign_transaction(tx)
        h = self.w3.eth.send_raw_transaction(signed.raw_transaction)
        return "0x" + h.hex()

    # ─── Block / tx helpers ──────────────────────────────────────────
    def block_number(self) -> int: return self.w3.eth.block_number
    def get_block(self, b: Union[int, str]) -> Any: return self.w3.eth.get_block(b)
    def get_transaction(self, h: str) -> Any: return self.w3.eth.get_transaction(h)
    def get_receipt(self, h: str) -> TxReceipt: return self.w3.eth.get_transaction_receipt(h)
    def wait_for_tx(self, h: str, timeout: int = 120) -> TxReceipt:
        return self.w3.eth.wait_for_transaction_receipt(h, timeout=timeout)

    # ─── Gas helpers ─────────────────────────────────────────────────
    def gas_price(self) -> int: return int(self.w3.eth.gas_price)

    def estimate_gas(self, tx: Dict[str, Any]) -> int: return int(self.w3.eth.estimate_gas(tx))

    # ─── Contracts ───────────────────────────────────────────────────
    def contract(self, address: str, abi: list) -> Web3Contract:
        return self.w3.eth.contract(address=Web3.to_checksum_address(address), abi=abi)

    def token(self, address: str) -> Token:
        return Token(address, self.w3, lambda: self._account)

    def deploy(self, abi: list, bytecode: str, args: Optional[list] = None) -> Dict[str, Any]:
        """Deploy a contract. Returns {address, tx_hash, receipt}."""
        if not self.has_signer:
            raise RuntimeError("deploy() needs a signer")
        args = args or []
        ContractFactory = self.w3.eth.contract(abi=abi, bytecode=bytecode)
        tx = ContractFactory.constructor(*args).build_transaction({
            "from": self.address,
            "nonce": self.w3.eth.get_transaction_count(self.address),
            "gas": 5_000_000,
            "gasPrice": self.gas_price(),
            "chainId": GGCHAIN["chain_id"],
        })
        signed = self.account.sign_transaction(tx)
        h = self.w3.eth.send_raw_transaction(signed.raw_transaction)
        receipt = self.w3.eth.wait_for_transaction_receipt(h, timeout=240)
        return {
            "address": receipt["contractAddress"],
            "tx_hash": "0x" + h.hex(),
            "receipt": receipt,
        }

    # ─── Multicall ───────────────────────────────────────────────────
    def multicall(self, calls: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Batch read calls. Each item: {"target": addr, "callData": "0x…", "allowFailure": bool=False}.
        Returns [{success, returnData}].
        """
        mc = self.w3.eth.contract(address=MULTICALL3, abi=ABI_MULTICALL3)
        formatted = [(c["target"], c.get("allowFailure", False), c["callData"]) for c in calls]
        r = mc.functions.aggregate3(formatted).call()
        return [{"success": x[0], "returnData": "0x" + x[1].hex() if isinstance(x[1], (bytes, bytearray)) else x[1]} for x in r]

    # ─── Messages / signatures ───────────────────────────────────────
    def sign_message(self, message: str) -> str:
        msg = encode_defunct(text=message)
        return self.account.sign_message(msg).signature.hex()

    @staticmethod
    def verify_message(message: str, signature: str) -> str:
        return Account.recover_message(encode_defunct(text=message), signature=signature)

    # ─── WebSocket events (lazy connect) ─────────────────────────────
    def subscribe_logs(self, address: Optional[str] = None, topics: Optional[List[str]] = None):
        """Generator yielding logs in real-time via WebSocket. Requires ws= in constructor."""
        if not self._ws_url:
            raise RuntimeError("Pass ws='wss://...' to GGChain() to subscribe.")
        from web3 import Web3 as _W3
        ws = _W3(_W3.LegacyWebSocketProvider(self._ws_url))
        flt: Dict[str, Any] = {}
        if address: flt["address"] = Web3.to_checksum_address(address)
        if topics:  flt["topics"]  = topics
        f = ws.eth.filter(flt)
        import time
        while True:
            for log in f.get_new_entries():
                yield log
            time.sleep(2)

    # ─── Validation helpers ──────────────────────────────────────────
    @staticmethod
    def is_address(value: str) -> bool: return Web3.is_address(value)

    @staticmethod
    def to_checksum_address(value: str) -> str: return Web3.to_checksum_address(value)
