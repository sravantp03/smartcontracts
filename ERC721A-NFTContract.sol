// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "https://github.com/exo-digital-labs/ERC721R/blob/main/contracts/ERC721A.sol";
import "https://github.com/exo-digital-labs/ERC721R/blob/main/contracts/IERC721R.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BoogiManNFT is ERC721A, Ownable {
    using Address for address payable;

    uint256 public constant MINT_PRICE = 0.01 ether;
    uint256 public constant MAX_MINT_PER_USER = 5;
    uint256 public constant MAX_MINT = 100;
    uint256 public constant REFUND_PERIOD = 3 minutes;

    constructor() ERC721A("BoogiMan", "BMAN") {}

    function safeMint(uint256 _quantity) public payable {
        require(msg.value == MINT_PRICE * _quantity, "Not enough funds");

        // _numberMinted() function inside ERC721A, where it keep track of how many tokens were minted by the caller.
        require(
            _numberMinted(msg.sender) + _quantity <= MAX_MINT_PER_USER,
            "Exceeds Mint Limit"
        );

        // _totalMinted() returns the count of total minted token. (ERC721A function)
        require(_totalMinted() + _quantity <= MAX_MINT, "Sold out");
        _safeMint(msg.sender, _quantity);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        // Address.sendValue(payable(owner()), balance);
        payable(owner()).sendValue(balance); // using Address library to do this. Available in ERC721A
    }
}
