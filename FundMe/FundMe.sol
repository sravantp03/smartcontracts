//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./PriceConverter.sol"; // Library

contract FundMe {

    using PriceConverter for uint256; // using library.

    uint256 minimumUSD = 50;

    address payable public owner;

    constructor() {
        owner = payable(msg.sender); // setting owner of the contract.
    }

    address[] public funders; // holds address of account who calls fund function.

    mapping(address => uint256) public addressToAmount;

    function fund() public payable {
        require(msg.value.getConversionRate() >= minimumUSD, "not enough money");
        funders.push(msg.sender);
        addressToAmount[msg.sender] += msg.value; // mapping address to amount sent. 
    }

    function withdraw() public onlyOwner {
        // resetting map
        for (uint256 i = 0; i < funders.length; i++) {
            addressToAmount[funders[i]] = 0;
        }

        // resetting array
        funders = new address[](0);

        // withdraw fund
        (bool callSuccess, ) = owner.call{value: address(this).balance}("");
        require(callSuccess, "Failed");
    }

    // only owner modifier
    modifier onlyOwner {
        require(msg.sender == owner, "Not Owner");
        _;
    }

}