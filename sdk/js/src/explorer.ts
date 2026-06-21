/** Blockscout (Etherscan-compatible) explorer REST client for GGCHAIN. */
export class Explorer {
  constructor(public readonly baseUrl: string = "https://explorer.gghyper.net") {}

  private async _api<T>(params: Record<string, string>): Promise<T> {
    const qs = new URLSearchParams(params).toString();
    const r = await fetch(`${this.baseUrl}/api?${qs}`);
    if (!r.ok) throw new Error(`Explorer ${r.status} ${r.statusText}`);
    const j = await r.json() as any;
    if (j.status === "0" && j.message !== "OK") return j.result as T;
    return j.result as T;
  }

  /** List of normal transactions for an address. */
  async txList(address: string, page = 1, offset = 50): Promise<any[]> {
    return await this._api({ module: "account", action: "txlist", address, page: String(page), offset: String(offset), sort: "desc" });
  }

  /** List of internal transactions for an address. */
  async internalTxList(address: string): Promise<any[]> {
    return await this._api({ module: "account", action: "txlistinternal", address });
  }

  /** ERC-20 token transfers for an address. */
  async tokenTransfers(address: string, contractaddress?: string): Promise<any[]> {
    const p: Record<string, string> = { module: "account", action: "tokentx", address };
    if (contractaddress) p.contractaddress = contractaddress;
    return await this._api(p);
  }

  /** Get verified contract source code. */
  async getContractSource(address: string): Promise<any> {
    return await this._api({ module: "contract", action: "getsourcecode", address });
  }

  /** Get contract ABI (if verified). */
  async getContractABI(address: string): Promise<any[]> {
    const raw = await this._api<string>({ module: "contract", action: "getabi", address });
    return typeof raw === "string" ? JSON.parse(raw) : raw as any;
  }

  /** Token holder count + supply. */
  async tokenInfo(contractaddress: string): Promise<any> {
    return await this._api({ module: "token", action: "getToken", contractaddress });
  }

  /** Direct URL to an address or tx on the explorer UI. */
  url(addressOrTx: string): string {
    return addressOrTx.length === 42 ? `${this.baseUrl}/address/${addressOrTx}` : `${this.baseUrl}/tx/${addressOrTx}`;
  }
}
