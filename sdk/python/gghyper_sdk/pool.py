"""GGCHAIN Mining Pool API client."""
from __future__ import annotations
from dataclasses import dataclass
import requests


@dataclass
class PoolStats:
    hashrate: float
    miners_total: int
    block_height: str
    raw: dict


@dataclass
class MinerStats:
    hashrate: float
    workers_online: int
    workers: dict
    balance: float
    paid: float
    raw: dict


class Pool:
    def __init__(self, base_url: str = "https://pool.gghyper.net"):
        self.base_url = base_url.rstrip("/")

    def _get(self, path: str):
        r = requests.get(f"{self.base_url}{path}", timeout=10)
        r.raise_for_status()
        return r.json()

    def stats(self) -> PoolStats:
        d = self._get("/api/stats")
        node = (d.get("nodes") or [{}])[0]
        return PoolStats(
            hashrate=float(d.get("hashrate") or 0),
            miners_total=int(d.get("minersTotal") or 0),
            block_height=str(node.get("height", "")),
            raw=d,
        )

    def miner(self, address: str) -> MinerStats:
        d = self._get(f"/api/accounts/{address}")
        stats = d.get("stats") or {}
        return MinerStats(
            hashrate=float(d.get("hashrate") or 0),
            workers_online=int(d.get("workersOnline") or 0),
            workers=d.get("workers") or {},
            balance=float(stats.get("balance") or 0) / 1e9,
            paid=float(stats.get("paid") or 0) / 1e9,
            raw=d,
        )

    def blocks(self) -> dict: return self._get("/api/blocks")
    def payments(self) -> dict: return self._get("/api/payments")

    @staticmethod
    def format_hash(h: float) -> str:
        if not h or h <= 0: return "0 H/s"
        units = ["H/s", "KH/s", "MH/s", "GH/s", "TH/s", "PH/s"]
        i = 0
        while h >= 1000 and i < len(units) - 1: h /= 1000; i += 1
        return f"{h:.2f} {units[i]}"

    @staticmethod
    def stratum_url() -> str: return "stratum+tcp://pool.gghyper.net:3333"
