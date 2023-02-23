// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract PiggyBank {
    event Deposit(address indexed funder, uint256 amount);
    event Withdraw(uint256 amount);

    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    fallback() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    function checkBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function withdraw() external onlyOwner {
        emit Withdraw(address(this).balance);
        // Implements the concept that, if we need to take money from piggybank we need to break it.
        selfdestruct(owner); //This delete the contract and send money to owner account.
    }
}
