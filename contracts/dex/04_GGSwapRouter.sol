// SPDX-License-Identifier: MIT
// GGSwap Router - User-facing entry point for swaps and liquidity provision
// Wraps native GG <-> WGG automatically so users can swap native GG directly.
// Deploy LAST: requires Factory address and WGG address as constructor params.
pragma solidity ^0.8.20;

interface IGGSwapFactory {
    function getPair(address, address) external view returns (address);
    function createPair(address, address) external returns (address);
}

interface IGGSwapPair {
    function getReserves() external view returns (uint112, uint112, uint32);
    function token0() external view returns (address);
    function mint(address) external returns (uint256);
    function burn(address) external returns (uint256, uint256);
    function swap(uint, uint, address, bytes calldata) external;
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address, address, uint256) external returns (bool);
    function totalSupply() external view returns (uint256);
}

interface IERC20Router {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
}

interface IWGG {
    function deposit() external payable;
    function withdraw(uint256) external;
    function transfer(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

contract GGSwapRouter {
    address public immutable factory;
    address public immutable WGG;

    modifier ensure(uint256 deadline) {
        require(block.timestamp <= deadline, "GGSwap: EXPIRED");
        _;
    }

    receive() external payable {
        require(msg.sender == WGG, "GGSwap: ONLY_WGG"); // Only accept native from WGG withdraw
    }

    constructor(address _factory, address _WGG) {
        factory = _factory;
        WGG = _WGG;
    }

    // ====== Liquidity ======
    function _addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin) internal returns (uint amountA, uint amountB) {
        if (IGGSwapFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IGGSwapFactory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = _getReserves(tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = amountADesired * reserveB / reserveA;
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "GGSwap: INSUFFICIENT_B");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = amountBDesired * reserveA / reserveB;
                require(amountAOptimal <= amountADesired && amountAOptimal >= amountAMin, "GGSwap: INSUFFICIENT_A");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline)
        external ensure(deadline) returns (uint amountA, uint amountB, uint liquidity)
    {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = IGGSwapFactory(factory).getPair(tokenA, tokenB);
        _safeTransferFrom(tokenA, msg.sender, pair, amountA);
        _safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IGGSwapPair(pair).mint(to);
    }

    // Add liquidity with native GG (auto-wraps to WGG)
    function addLiquidityGG(address token, uint amountTokenDesired, uint amountTokenMin, uint amountGGMin, address to, uint deadline)
        external payable ensure(deadline) returns (uint amountToken, uint amountGG, uint liquidity)
    {
        (amountToken, amountGG) = _addLiquidity(token, WGG, amountTokenDesired, msg.value, amountTokenMin, amountGGMin);
        address pair = IGGSwapFactory(factory).getPair(token, WGG);
        _safeTransferFrom(token, msg.sender, pair, amountToken);
        IWGG(WGG).deposit{value: amountGG}();
        IWGG(WGG).transfer(pair, amountGG);
        liquidity = IGGSwapPair(pair).mint(to);
        if (msg.value > amountGG) payable(msg.sender).transfer(msg.value - amountGG);
    }

    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline)
        public ensure(deadline) returns (uint amountA, uint amountB)
    {
        address pair = IGGSwapFactory(factory).getPair(tokenA, tokenB);
        IGGSwapPair(pair).transferFrom(msg.sender, pair, liquidity);
        (uint a0, uint a1) = IGGSwapPair(pair).burn(to);
        (address t0,) = _sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == t0 ? (a0, a1) : (a1, a0);
        require(amountA >= amountAMin, "GGSwap: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "GGSwap: INSUFFICIENT_B_AMOUNT");
    }

    function removeLiquidityGG(address token, uint liquidity, uint amountTokenMin, uint amountGGMin, address to, uint deadline)
        external ensure(deadline) returns (uint amountToken, uint amountGG)
    {
        (amountToken, amountGG) = removeLiquidity(token, WGG, liquidity, amountTokenMin, amountGGMin, address(this), deadline);
        IERC20Router(token).transfer(to, amountToken);
        IWGG(WGG).withdraw(amountGG);
        payable(to).transfer(amountGG);
    }

    // ====== Swap ======
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal {
        for (uint i = 0; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i+1]);
            (address t0,) = _sortTokens(input, output);
            uint amountOut = amounts[i+1];
            (uint amount0Out, uint amount1Out) = input == t0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? IGGSwapFactory(factory).getPair(output, path[i+2]) : _to;
            IGGSwapPair(IGGSwapFactory(factory).getPair(input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external ensure(deadline) returns (uint[] memory amounts)
    {
        amounts = getAmountsOut(amountIn, path);
        require(amounts[amounts.length-1] >= amountOutMin, "GGSwap: INSUFFICIENT_OUTPUT_AMOUNT");
        _safeTransferFrom(path[0], msg.sender, IGGSwapFactory(factory).getPair(path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
    }

    // Swap exact native GG for tokens (auto-wraps to WGG)
    function swapExactGGForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external payable ensure(deadline) returns (uint[] memory amounts)
    {
        require(path[0] == WGG, "GGSwap: INVALID_PATH");
        amounts = getAmountsOut(msg.value, path);
        require(amounts[amounts.length-1] >= amountOutMin, "GGSwap: INSUFFICIENT_OUTPUT_AMOUNT");
        IWGG(WGG).deposit{value: amounts[0]}();
        IWGG(WGG).transfer(IGGSwapFactory(factory).getPair(path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
    }

    // Swap exact tokens for native GG (auto-unwraps from WGG)
    function swapExactTokensForGG(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external ensure(deadline) returns (uint[] memory amounts)
    {
        require(path[path.length-1] == WGG, "GGSwap: INVALID_PATH");
        amounts = getAmountsOut(amountIn, path);
        require(amounts[amounts.length-1] >= amountOutMin, "GGSwap: INSUFFICIENT_OUTPUT_AMOUNT");
        _safeTransferFrom(path[0], msg.sender, IGGSwapFactory(factory).getPair(path[0], path[1]), amounts[0]);
        _swap(amounts, path, address(this));
        IWGG(WGG).withdraw(amounts[amounts.length-1]);
        payable(to).transfer(amounts[amounts.length-1]);
    }

    // ====== View / Quote ======
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint) {
        require(amountIn > 0, "GGSwap: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "GGSwap: INSUFFICIENT_LIQUIDITY");
        uint amountInWithFee = amountIn * 997;
        return (amountInWithFee * reserveOut) / (reserveIn * 1000 + amountInWithFee);
    }

    function getAmountsOut(uint amountIn, address[] memory path) public view returns (uint[] memory amounts) {
        require(path.length >= 2, "GGSwap: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i = 0; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = _getReserves(path[i], path[i+1]);
            amounts[i+1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    function quote(uint amountA, uint reserveA, uint reserveB) public pure returns (uint) {
        require(amountA > 0 && reserveA > 0 && reserveB > 0, "GGSwap: QUOTE_INVALID");
        return amountA * reserveB / reserveA;
    }

    // ====== Internal helpers ======
    function _sortTokens(address tokenA, address tokenB) internal pure returns (address t0, address t1) {
        require(tokenA != tokenB, "GGSwap: IDENTICAL");
        (t0, t1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(t0 != address(0), "GGSwap: ZERO");
    }

    function _getReserves(address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address t0,) = _sortTokens(tokenA, tokenB);
        address pair = IGGSwapFactory(factory).getPair(tokenA, tokenB);
        (uint112 r0, uint112 r1,) = IGGSwapPair(pair).getReserves();
        (reserveA, reserveB) = tokenA == t0 ? (uint(r0), uint(r1)) : (uint(r1), uint(r0));
    }

    function _safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool ok, bytes memory data) = token.call(abi.encodeWithSelector(IERC20Router.transferFrom.selector, from, to, value));
        require(ok && (data.length == 0 || abi.decode(data, (bool))), "GGSwap: TRANSFER_FROM_FAILED");
    }
}
