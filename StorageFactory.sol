//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./SimpleStorage.sol";

contract StorageFactory {

    SimpleStorage public simple;

    function deploySimpleStorage(uint _num) public {
        simple = new SimpleStorage(); // Deploying SimpleStorage Contract
        simple.store(_num); // calling SimpleStorage store function using SimpleStorage address
    }

    function getFavNum() public view returns(uint256) {
        return simple.retrieve(); // getting data from SimpleStorage
    }

}