// SPDX-License-Identifier: MIT
// GGSwap Pair Contract - Single trading pair AMM (Uniswap V2-style x*y=k)
// Each token-token pair has its own deployed instance of this contract.
// Holds reserves of 2 tokens, mints LP tokens to liquidity providers,
// charges 0.30% fee on swaps.
pragma solidity ^0.8.20;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

interface IGGSwapCallee {
    function ggSwapCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

contract GGSwapPair {
    // ====== ERC-20 LP token ======
    string  public constant name     = "GGSwap LP";
    string  public constant symbol   = "GG-LP";
    uint8   public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // ====== Pair state ======
    uint256 public constant MINIMUM_LIQUIDITY = 10**3;
    address public factory;
    address public token0;
    address public token1;
    uint112 private reserve0;
    uint112 private reserve1;
    uint32  private blockTimestampLast;
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast;

    // Reentrancy lock
    uint256 private unlocked = 1;
    modifier lock() { require(unlocked == 1, "GGSwap: LOCKED"); unlocked = 0; _; unlocked = 1; }

    // ====== Events ======
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor() {
        factory = msg.sender;
    }

    // Called by Factory once at deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "GGSwap: FORBIDDEN");
        token0 = _token0;
        token1 = _token1;
    }

    function getReserves() public view returns (uint112 _r0, uint112 _r1, uint32 _ts) {
        _r0 = reserve0; _r1 = reserve1; _ts = blockTimestampLast;
    }

    // ====== ERC-20 internals ======
    function _mintLP(address to, uint256 v) private { totalSupply += v; balanceOf[to] += v; emit Transfer(address(0), to, v); }
    function _burnLP(address from, uint256 v) private { balanceOf[from] -= v; totalSupply -= v; emit Transfer(from, address(0), v); }
    function approve(address sp, uint256 v) external returns (bool) { allowance[msg.sender][sp] = v; emit Approval(msg.sender, sp, v); return true; }
    function transfer(address to, uint256 v) external returns (bool) { _transfer(msg.sender, to, v); return true; }
    function transferFrom(address from, address to, uint256 v) external returns (bool) {
        uint256 a = allowance[from][msg.sender];
        if (a != type(uint256).max) allowance[from][msg.sender] = a - v;
        _transfer(from, to, v); return true;
    }
    function _transfer(address from, address to, uint256 v) private { balanceOf[from] -= v; balanceOf[to] += v; emit Transfer(from, to, v); }

    // ====== Internal update ======
    function _update(uint balance0, uint balance1, uint112 _r0, uint112 _r1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, "GGSwap: OVERFLOW");
        uint32 ts = uint32(block.timestamp % 2**32);
        uint32 elapsed = ts - blockTimestampLast;
        if (elapsed > 0 && _r0 != 0 && _r1 != 0) {
            unchecked {
                price0CumulativeLast += (uint256(_r1) * 2**112 / _r0) * elapsed;
                price1CumulativeLast += (uint256(_r0) * 2**112 / _r1) * elapsed;
            }
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = ts;
        emit Sync(reserve0, reserve1);
    }

    // ====== Liquidity Provider functions ======
    // Mint LP tokens. Caller must transfer tokens to this contract first.
    function mint(address to) external lock returns (uint256 liquidity) {
        (uint112 _r0, uint112 _r1,) = getReserves();
        uint256 bal0 = IERC20(token0).balanceOf(address(this));
        uint256 bal1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = bal0 - _r0;
        uint256 amount1 = bal1 - _r1;

        if (totalSupply == 0) {
            liquidity = _sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mintLP(address(0xdead), MINIMUM_LIQUIDITY); // permanently lock
        } else {
            uint256 l0 = amount0 * totalSupply / _r0;
            uint256 l1 = amount1 * totalSupply / _r1;
            liquidity = l0 < l1 ? l0 : l1;
        }
        require(liquidity > 0, "GGSwap: INSUFFICIENT_LIQUIDITY_MINTED");
        _mintLP(to, liquidity);
        _update(bal0, bal1, _r0, _r1);
        emit Mint(msg.sender, amount0, amount1);
    }

    // Burn LP tokens. Caller must transfer LP tokens to this contract first.
    function burn(address to) external lock returns (uint256 amount0, uint256 amount1) {
        (uint112 _r0, uint112 _r1,) = getReserves();
        uint256 bal0 = IERC20(token0).balanceOf(address(this));
        uint256 bal1 = IERC20(token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];

        amount0 = liquidity * bal0 / totalSupply;
        amount1 = liquidity * bal1 / totalSupply;
        require(amount0 > 0 && amount1 > 0, "GGSwap: INSUFFICIENT_LIQUIDITY_BURNED");
        _burnLP(address(this), liquidity);
        IERC20(token0).transfer(to, amount0);
        IERC20(token1).transfer(to, amount1);
        bal0 = IERC20(token0).balanceOf(address(this));
        bal1 = IERC20(token1).balanceOf(address(this));
        _update(bal0, bal1, _r0, _r1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // ====== Swap ======
    // 0.30% fee built into the invariant check (997/1000)
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, "GGSwap: INSUFFICIENT_OUTPUT_AMOUNT");
        (uint112 _r0, uint112 _r1,) = getReserves();
        require(amount0Out < _r0 && amount1Out < _r1, "GGSwap: INSUFFICIENT_LIQUIDITY");

        uint256 bal0; uint256 bal1;
        {
            address _t0 = token0; address _t1 = token1;
            require(to != _t0 && to != _t1, "GGSwap: INVALID_TO");
            if (amount0Out > 0) IERC20(_t0).transfer(to, amount0Out);
            if (amount1Out > 0) IERC20(_t1).transfer(to, amount1Out);
            if (data.length > 0) IGGSwapCallee(to).ggSwapCall(msg.sender, amount0Out, amount1Out, data);
            bal0 = IERC20(_t0).balanceOf(address(this));
            bal1 = IERC20(_t1).balanceOf(address(this));
        }
        uint256 amount0In = bal0 > _r0 - amount0Out ? bal0 - (_r0 - amount0Out) : 0;
        uint256 amount1In = bal1 > _r1 - amount1Out ? bal1 - (_r1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, "GGSwap: INSUFFICIENT_INPUT_AMOUNT");
        {
            uint256 bal0Adj = bal0 * 1000 - amount0In * 3;
            uint256 bal1Adj = bal1 * 1000 - amount1In * 3;
            require(bal0Adj * bal1Adj >= uint256(_r0) * _r1 * (1000**2), "GGSwap: K");
        }
        _update(bal0, bal1, _r0, _r1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // Force balances to match reserves
    function skim(address to) external lock {
        IERC20(token0).transfer(to, IERC20(token0).balanceOf(address(this)) - reserve0);
        IERC20(token1).transfer(to, IERC20(token1).balanceOf(address(this)) - reserve1);
    }

    // Force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    // Babylonian sqrt
    function _sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) { z = y; uint256 x = y / 2 + 1; while (x < z) { z = x; x = (y / x + x) / 2; } }
        else if (y != 0) { z = 1; }
    }
}
