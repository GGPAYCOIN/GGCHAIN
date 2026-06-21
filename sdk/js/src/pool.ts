export interface PoolStats {
  hashrate: number;
  minersTotal: number;
  candidatesTotal: number;
  immatureTotal: number;
  maturedTotal: number;
  nodes: Array<{ name: string; height: string; difficulty: string }>;
  now: number;
}

export interface MinerStats {
  hashrate: number;
  hashrate24h?: number;
  currentHashrate?: number;
  workersOnline: number;
  workers: Record<string, { hr: number; lastBeat: number; validShares: number; invalidShares: number }>;
  stats: { balance: number; immature: number; paid: number };
  payments?: Array<{ amount: string; tx: string; timestamp: number }>;
  rewards?: Array<{ blockheight: number; reward: string; timestamp: number }>;
}

/** Client for the GGCHAIN Mining Pool public API. */
export class Pool {
  constructor(public readonly baseUrl: string = "https://pool.gghyper.net") {}

  private async _fetch<T>(path: string): Promise<T> {
    const r = await fetch(`${this.baseUrl}${path}`);
    if (!r.ok) throw new Error(`Pool API ${path}: ${r.status} ${r.statusText}`);
    return await r.json() as T;
  }

  /** Pool-wide live stats. */
  stats(): Promise<PoolStats> { return this._fetch<PoolStats>("/api/stats"); }

  /** Look up a single miner by wallet address. */
  miner(address: string): Promise<MinerStats> { return this._fetch<MinerStats>(`/api/accounts/${address}`); }

  /** Recent blocks found by the pool. */
  blocks(): Promise<any> { return this._fetch("/api/blocks"); }

  /** Recent miner payouts. */
  payments(): Promise<any> { return this._fetch("/api/payments"); }

  /** Helper: format raw H/s into a human string. */
  static formatHash(h: number): string {
    if (!h || h <= 0) return "0 H/s";
    const u = ["H/s", "KH/s", "MH/s", "GH/s", "TH/s", "PH/s"];
    let i = 0; let v = h;
    while (v >= 1000 && i < u.length - 1) { v /= 1000; i++; }
    return `${v.toFixed(2)} ${u[i]}`;
  }

  /** Stratum endpoint string for miners. */
  stratumUrl(): string { return "stratum+tcp://pool.gghyper.net:3333"; }
}
