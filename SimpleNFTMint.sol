// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleNFTMint is ERC721, Ownable {
    uint256 public mintPrice = 0.01 ether;
    uint256 private totalSupply = 0; // current number of nft minted.
    uint256 public maxSupply; // maximum mint allowed.
    bool public isMintEnabled; // default false.
    mapping(address => uint256) public mintedWallet; // for tracking number of nft minted by wallet.

    constructor() payable ERC721("Simple Mint NFT", "SMNFT") {
        maxSupply = 2;
    }

    function toggleMint() external onlyOwner {
        isMintEnabled = !isMintEnabled;
    }

    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function mint() external payable {
        require(isMintEnabled, "Minting is disabled..");
        require(
            mintedWallet[msg.sender] == 0,
            "You already minted this token.."
        );
        require(msg.value == mintPrice, "Not enough ETH..");
        require(totalSupply < maxSupply, "Sold out..");

        mintedWallet[msg.sender]++;
        totalSupply++;
        uint256 tokenId = totalSupply;
        _safeMint(msg.sender, tokenId);
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }
}
