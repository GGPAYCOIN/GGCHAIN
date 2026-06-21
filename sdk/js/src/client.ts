import {
  JsonRpcProvider, WebSocketProvider, Wallet, Signer, Contract, ContractFactory,
  formatEther, parseEther, hashMessage, getAddress,
  TransactionResponse, TransactionReceipt, Interface, Log, EventLog, isAddress,
} from "ethers";
import { GGCHAIN, ABI_ERC20, MULTICALL3, ABI_MULTICALL3 } from "./constants.js";
import { Token } from "./token.js";
import { Pool } from "./pool.js";
import { Explorer } from "./explorer.js";

export interface ClientOptions {
  rpc?: string;
  ws?: string;
  signer?: Signer;
  privateKey?: string;
}

export interface MulticallReq { target: string; allowFailure?: boolean; callData: string; }
export interface MulticallRes { success: boolean; returnData: string; }

/**
 * GGCHAIN Client — the developer entry-point.
 *
 * @example Read
 * const gg = new GGChain();
 * const bal = await gg.getBalance("0xAlice…");
 *
 * @example Write
 * const gg = new GGChain({ privateKey: "0x..." });
 * await gg.send("0xBob…", "1.5");
 *
 * @example Custom contract
 * const c = gg.contract("0x...", abi);
 * await c.someMethod();
 */
export class GGChain {
  readonly provider: JsonRpcProvider;
  private _signer?: Signer;
  private _ws?: WebSocketProvider;

  /** Mining pool REST client. */
  readonly pool: Pool;
  /** Blockscout explorer REST client. */
  readonly explorer: Explorer;

  constructor(opts: ClientOptions = {}) {
    this.provider = new JsonRpcProvider(opts.rpc ?? GGCHAIN.rpc, GGCHAIN.chainId, { staticNetwork: true });
    if (opts.signer) this._signer = opts.signer.connect(this.provider);
    if (opts.privateKey) this._signer = new Wallet(opts.privateKey, this.provider);
    if (opts.ws) this._ws = new WebSocketProvider(opts.ws, GGCHAIN.chainId);
    this.pool = new Pool(GGCHAIN.pool);
    this.explorer = new Explorer(GGCHAIN.explorer);
  }

  // ─── Signer management ────────────────────────────────────────────────

  /** Attach a signer (private key or any ethers Signer). */
  connect(signer: Signer | string): this {
    this._signer = typeof signer === "string"
      ? new Wallet(signer, this.provider)
      : signer.connect(this.provider);
    return this;
  }

  get signer(): Signer {
    if (!this._signer) throw new Error("No signer attached. Use new GGChain({ privateKey }) or .connect(signer)");
    return this._signer;
  }

  /** Address of the currently attached signer. */
  async address(): Promise<string> { return await this.signer.getAddress(); }

  /** True if a signer is attached. */
  get hasSigner(): boolean { return !!this._signer; }

  // ─── Native GG ────────────────────────────────────────────────────────

  /** Native GG balance (decimal string). */
  async getBalance(address?: string): Promise<string> {
    const a = address ?? await this.address();
    return formatEther(await this.provider.getBalance(getAddress(a)));
  }

  /** Send native GG. */
  async send(to: string, amount: string): Promise<TransactionResponse> {
    return await this.signer.sendTransaction({ to: getAddress(to), value: parseEther(amount) });
  }

  // ─── Block & tx helpers ───────────────────────────────────────────────

  async blockNumber(): Promise<number> { return await this.provider.getBlockNumber(); }
  async getBlock(blockHashOrNumber: number | string) { return await this.provider.getBlock(blockHashOrNumber); }
  async getTransaction(hash: string) { return await this.provider.getTransaction(hash); }
  async getReceipt(hash: string): Promise<TransactionReceipt | null> { return await this.provider.getTransactionReceipt(hash); }
  async waitForTx(hash: string, confirmations = 1, timeout = 120_000): Promise<TransactionReceipt | null> {
    return await this.provider.waitForTransaction(hash, confirmations, timeout);
  }

  // ─── Gas helpers ──────────────────────────────────────────────────────

  async gasPrice(): Promise<bigint> { return (await this.provider.getFeeData()).gasPrice ?? 0n; }
  async estimateGas(tx: { to: string; data?: string; value?: bigint }): Promise<bigint> {
    return await this.provider.estimateGas(tx);
  }

  // ─── Contracts ────────────────────────────────────────────────────────

  /** Wrap any contract address with an ABI (write-mode auto if signer attached). */
  contract(address: string, abi: any[]): Contract {
    return new Contract(getAddress(address), abi, this._signer ?? this.provider);
  }

  /** Wrap any ERC-20 token. */
  token(address: string): Token {
    return new Token(getAddress(address), this.provider, () => this._signer);
  }

  /** Deploy a contract. Returns the contract instance after deployment. */
  async deploy(abi: any[], bytecode: string, args: any[] = []): Promise<{ address: string; tx: TransactionResponse; contract: Contract }> {
    const factory = new ContractFactory(abi, bytecode, this.signer);
    const contract = await factory.deploy(...args);
    const tx = contract.deploymentTransaction()!;
    await contract.waitForDeployment();
    const address = await contract.getAddress();
    return { address, tx, contract: contract as unknown as Contract };
  }

  // ─── Multicall ────────────────────────────────────────────────────────

  /** Batch multiple read calls into a single RPC. */
  async multicall(calls: MulticallReq[]): Promise<MulticallRes[]> {
    const mc = new Contract(MULTICALL3, ABI_MULTICALL3 as any, this.provider);
    const formatted = calls.map(c => ({ target: c.target, allowFailure: c.allowFailure ?? false, callData: c.callData }));
    const r = await mc.aggregate3.staticCall(formatted);
    return r.map((x: any) => ({ success: x.success, returnData: x.returnData }));
  }

  /** Convenience: build an Interface-encoded multicall (typed). */
  encodeCall(iface: Interface, fn: string, args: any[] = []): string {
    return iface.encodeFunctionData(fn, args);
  }

  // ─── Messages / signatures ────────────────────────────────────────────

  /** Sign an arbitrary string message (EIP-191). */
  async signMessage(message: string): Promise<string> {
    return await this.signer.signMessage(message);
  }

  /** Hash an EIP-191 personal message. */
  hashMessage(message: string): string { return hashMessage(message); }

  /** Verify which address signed a message. */
  static verifyMessage(message: string, signature: string): string {
    // re-export from ethers via dynamic import to avoid bloating top-level
    const { verifyMessage } = require("ethers");
    return verifyMessage(message, signature);
  }

  // ─── Event subscription (WebSocket) ───────────────────────────────────

  /** Subscribe to logs via WebSocket. Returns an unsubscribe fn. */
  onLogs(filter: { address?: string; topics?: string[] }, handler: (log: Log | EventLog) => void): () => void {
    if (!this._ws) throw new Error("WS provider not configured. Pass { ws: 'wss://...' } in constructor.");
    this._ws.on(filter, handler);
    return () => { this._ws!.off(filter, handler); };
  }

  /** Subscribe to new blocks. */
  onBlock(handler: (blockNumber: number) => void): () => void {
    if (!this._ws) throw new Error("WS provider not configured.");
    this._ws.on("block", handler);
    return () => { this._ws!.off("block", handler); };
  }

  /** Close all open connections (RPC + WS). */
  async destroy(): Promise<void> {
    this.provider.destroy();
    if (this._ws) await this._ws.destroy();
  }

  // ─── Validation ───────────────────────────────────────────────────────

  static isAddress(value: string): boolean { return isAddress(value); }
  static toChecksumAddress(value: string): string { return getAddress(value); }
}
