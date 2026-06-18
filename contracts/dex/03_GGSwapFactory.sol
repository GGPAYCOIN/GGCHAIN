// SPDX-License-Identifier: MIT
// GGSwap Factory - Creates and tracks all trading pairs
// Deploy AFTER GGSwapPair (you only deploy the Pair as bytecode reference via this Factory).
// Actually: you deploy this Factory contract which has the Pair bytecode embedded inline.
// To keep this file self-contained and deployable in Remix, paste GGSwapPair source ABOVE this Factory.
pragma solidity ^0.8.20;

// NOTE: For Remix deployment, copy contents of 02_GGSwapPair.sol ABOVE this contract,
// OR import it: import "./02_GGSwapPair.sol";

import "./02_GGSwapPair.sol";

contract GGSwapFactory {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 pairCount);

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "GGSwap: IDENTICAL_ADDRESSES");
        (address t0, address t1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(t0 != address(0), "GGSwap: ZERO_ADDRESS");
        require(getPair[t0][t1] == address(0), "GGSwap: PAIR_EXISTS");

        // Deterministic deployment via CREATE2 so address is predictable
        bytes32 salt = keccak256(abi.encodePacked(t0, t1));
        GGSwapPair newPair = new GGSwapPair{salt: salt}();
        newPair.initialize(t0, t1);
        pair = address(newPair);

        getPair[t0][t1] = pair;
        getPair[t1][t0] = pair;
        allPairs.push(pair);
        emit PairCreated(t0, t1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, "GGSwap: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, "GGSwap: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }
}
