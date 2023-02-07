// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7; // specifying solidity version

contract SimpleStorage {

    uint public favoriteNumber;

    struct People {
        uint256 favNum;
        string name;
        address add;
    }

    People[] public people;

    mapping(string => uint256) nameToFav;

    function store(uint256 _favNum) public {
        favoriteNumber = _favNum;
    }

    function printnum() public view returns(uint256) {
        return favoriteNumber;
    }

    function addPeople(uint256 _num, string memory _name) public {
        people.push(People(_num, _name, msg.sender));
    }

    function addMapping(string memory _name, uint256 _num) public {
        nameToFav[_name] = _num;
    }

    function returnMap(string memory _name) public view returns(uint256) {
        return nameToFav[_name];
    } 

}