"""GGCHAIN Blockscout explorer API client."""
from __future__ import annotations
from typing import Any, Optional
import requests
import json


class Explorer:
    def __init__(self, base_url: str = "https://explorer.gghyper.net"):
        self.base_url = base_url.rstrip("/")

    def _api(self, **params) -> Any:
        r = requests.get(f"{self.base_url}/api", params=params, timeout=15)
        r.raise_for_status()
        j = r.json()
        return j.get("result")

    def tx_list(self, address: str, page: int = 1, offset: int = 50):
        return self._api(module="account", action="txlist", address=address,
                         page=page, offset=offset, sort="desc")

    def internal_tx_list(self, address: str):
        return self._api(module="account", action="txlistinternal", address=address)

    def token_transfers(self, address: str, contractaddress: Optional[str] = None):
        p = {"module": "account", "action": "tokentx", "address": address}
        if contractaddress: p["contractaddress"] = contractaddress
        return self._api(**p)

    def get_contract_source(self, address: str) -> Any:
        return self._api(module="contract", action="getsourcecode", address=address)

    def get_contract_abi(self, address: str):
        raw = self._api(module="contract", action="getabi", address=address)
        return json.loads(raw) if isinstance(raw, str) else raw

    def token_info(self, contractaddress: str):
        return self._api(module="token", action="getToken", contractaddress=contractaddress)

    def url(self, address_or_tx: str) -> str:
        return f"{self.base_url}/{'address' if len(address_or_tx) == 42 else 'tx'}/{address_or_tx}"
