// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title GGPAY Token (GGT)
 * @dev Official ERC-20 token for GGCHAIN Mainnet
 * Chain ID: 2121217
 * Symbol: GGT
 * Decimals: 18
 * Initial Supply: 1,000,000,000 GGT (1 Billion)
 */

contract GGToken {
    string public name = "GGPAY Token";
    string public symbol = "GGT";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    address public owner;
    bool public paused = false;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);

    modifier onlyOwner() {
        require(msg.sender == owner, "GGT: caller is not the owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "GGT: token transfer while paused");
        _;
    }

    constructor(uint256 initialSupply) {
        owner = msg.sender;
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        require(to != address(0), "GGT: transfer to the zero address");
        require(balanceOf[msg.sender] >= value, "GGT: insufficient balance");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), "GGT: approve to the zero address");

        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        require(from != address(0), "GGT: transfer from the zero address");
        require(to != address(0), "GGT: transfer to the zero address");
        require(balanceOf[from] >= value, "GGT: insufficient balance");
        require(allowance[from][msg.sender] >= value, "GGT: insufficient allowance");

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        return true;
    }

    function mint(address to, uint256 value) public onlyOwner returns (bool) {
        require(to != address(0), "GGT: mint to the zero address");

        totalSupply += value;
        balanceOf[to] += value;

        emit Mint(to, value);
        emit Transfer(address(0), to, value);
        return true;
    }

    function burn(uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "GGT: insufficient balance to burn");

        balanceOf[msg.sender] -= value;
        totalSupply -= value;

        emit Burn(msg.sender, value);
        emit Transfer(msg.sender, address(0), value);
        return true;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "GGT: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function pause() public onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }
}
