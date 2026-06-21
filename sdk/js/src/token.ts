import { Contract, JsonRpcProvider, Signer, formatUnits, parseUnits, TransactionResponse } from "ethers";
import { ABI_ERC20 } from "./constants.js";

/** Ergonomic wrapper over any ERC-20 on GGCHAIN. */
export class Token {
  private readonly _read: Contract;
  private _decimals?: number;
  private _symbol?: string;

  constructor(
    readonly address: string,
    private readonly provider: JsonRpcProvider,
    private readonly getSigner: () => Signer | undefined,
  ) {
    this._read = new Contract(address, ABI_ERC20 as any, provider);
  }

  /** Cached symbol(). */
  async symbol(): Promise<string> {
    if (!this._symbol) this._symbol = await this._read.symbol();
    return this._symbol!;
  }

  /** Cached decimals(). */
  async decimals(): Promise<number> {
    if (this._decimals === undefined) this._decimals = Number(await this._read.decimals());
    return this._decimals!;
  }

  /** Raw on-chain integer balance (wei). */
  async balanceOfRaw(owner: string): Promise<bigint> {
    return await this._read.balanceOf(owner);
  }

  /** Decimal-adjusted balance as a string. */
  async balanceOf(owner: string): Promise<string> {
    const [raw, d] = await Promise.all([this.balanceOfRaw(owner), this.decimals()]);
    return formatUnits(raw, d);
  }

  /** Allowance owner → spender as decimal string. */
  async allowance(owner: string, spender: string): Promise<string> {
    const [raw, d] = await Promise.all([this._read.allowance(owner, spender), this.decimals()]);
    return formatUnits(raw, d);
  }

  /** Approve `spender` to spend `amount` (decimal string or "max"). */
  async approve(spender: string, amount: string | "max"): Promise<TransactionResponse> {
    const s = this._requireSigner();
    const c = new Contract(this.address, ABI_ERC20 as any, s);
    if (amount === "max") return await c.approve(spender, (1n << 256n) - 1n);
    return await c.approve(spender, parseUnits(amount, await this.decimals()));
  }

  /** Transfer `amount` to `to`. */
  async transfer(to: string, amount: string): Promise<TransactionResponse> {
    const s = this._requireSigner();
    const c = new Contract(this.address, ABI_ERC20 as any, s);
    return await c.transfer(to, parseUnits(amount, await this.decimals()));
  }

  /** Total supply as decimal string. */
  async totalSupply(): Promise<string> {
    const [raw, d] = await Promise.all([this._read.totalSupply(), this.decimals()]);
    return formatUnits(raw, d);
  }

  private _requireSigner(): Signer {
    const s = this.getSigner();
    if (!s) throw new Error(`Token ${this.address}: signer required for this action`);
    return s;
  }
}
