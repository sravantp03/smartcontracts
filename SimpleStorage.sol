// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7; // specifying solidity version

contract SimpleStorage {

    uint256 favoriteNumber; // state variable

    function store(uint256 _favNum) public {
        favoriteNumber = _favNum;
    }

    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }
    
}