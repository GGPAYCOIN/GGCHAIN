"""Ergonomic ERC-20 wrapper for any token on GGCHAIN."""
from __future__ import annotations
from typing import Callable, Optional, Union
from decimal import Decimal
from web3 import Web3
from eth_account.signers.local import LocalAccount
from .constants import ABI_ERC20, GGCHAIN


class Token:
    def __init__(self, address: str, w3: Web3, get_account: Callable[[], Optional[LocalAccount]]):
        self.address = Web3.to_checksum_address(address)
        self._w3 = w3
        self._get = get_account
        self._c = w3.eth.contract(address=self.address, abi=ABI_ERC20)
        self._dec: Optional[int] = None
        self._sym: Optional[str] = None

    def symbol(self) -> str:
        if self._sym is None: self._sym = self._c.functions.symbol().call()
        return self._sym

    def decimals(self) -> int:
        if self._dec is None: self._dec = int(self._c.functions.decimals().call())
        return self._dec

    def name(self) -> str: return self._c.functions.name().call()

    def total_supply(self) -> str:
        raw = int(self._c.functions.totalSupply().call())
        return str(Decimal(raw) / Decimal(10 ** self.decimals()))

    def balance_of_raw(self, owner: str) -> int:
        return int(self._c.functions.balanceOf(Web3.to_checksum_address(owner)).call())

    def balance_of(self, owner: str) -> str:
        return str(Decimal(self.balance_of_raw(owner)) / Decimal(10 ** self.decimals()))

    def allowance(self, owner: str, spender: str) -> str:
        raw = int(self._c.functions.allowance(
            Web3.to_checksum_address(owner), Web3.to_checksum_address(spender),
        ).call())
        return str(Decimal(raw) / Decimal(10 ** self.decimals()))

    def approve(self, spender: str, amount: Union[str, Decimal, int]) -> str:
        acct = self._require()
        if amount == "max" or amount is True:
            amt = (1 << 256) - 1
        else:
            amt = int(Decimal(str(amount)) * Decimal(10 ** self.decimals()))
        return self._send(acct, "approve", Web3.to_checksum_address(spender), amt)

    def transfer(self, to: str, amount: Union[str, Decimal]) -> str:
        acct = self._require()
        amt = int(Decimal(str(amount)) * Decimal(10 ** self.decimals()))
        return self._send(acct, "transfer", Web3.to_checksum_address(to), amt)

    def _require(self) -> LocalAccount:
        a = self._get()
        if not a: raise RuntimeError(f"Token {self.address}: signer required")
        return a

    def _send(self, acct: LocalAccount, fn: str, *args) -> str:
        tx = getattr(self._c.functions, fn)(*args).build_transaction({
            "from": acct.address,
            "nonce": self._w3.eth.get_transaction_count(acct.address),
            "gas": 120_000,
            "gasPrice": self._w3.eth.gas_price,
            "chainId": GGCHAIN["chain_id"],
        })
        signed = acct.sign_transaction(tx)
        h = self._w3.eth.send_raw_transaction(signed.raw_transaction)
        return "0x" + h.hex()
