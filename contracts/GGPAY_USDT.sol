// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title GGPAY_USDT
 * @notice Tether GGPAY stablecoin (USDT) on GGCHAIN Mainnet
 * @dev Deployed at 0x79Cce540c444AE1D7bDfd318CfBDB950147BcEc0
 */
contract GGPAY_USDT is ERC20, Ownable {
    constructor() ERC20("Tether GGPAY", "USDT") Ownable(msg.sender) {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
