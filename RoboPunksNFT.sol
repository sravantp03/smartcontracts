// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RoboPunksNFT is ERC721, Ownable {
    uint256 public mintPrice;
    uint256 public totalSupply;
    uint256 public maxSupply;
    uint256 public maxPerWallet;
    bool public isPublicMintEnabled;
    string internal baseTokenURI;
    mapping(address => uint256) public walletMintCount;

    constructor() payable ERC721("RoboPunks", "RP") {
        mintPrice = 0.01 ether;
        totalSupply = 0;
        maxSupply = 100;
        maxPerWallet = 3;
    }

    function togglePublicMint(bool isPublicMintEnabled_) external onlyOwner {
        isPublicMintEnabled = isPublicMintEnabled_;
    }

    function setTokenURI(string memory tokenURI_) external onlyOwner {
        baseTokenURI = tokenURI_;
    }

    // overriding existing _baseURI function in ERC721.
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    // withdraw ETH from the contract
    function withdrawETH() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Transfer Failed");
    }

    function mint(uint256 quantity_) public payable {
        require(quantity_ > 0, "Minimum quantity should be 1");
        require(isPublicMintEnabled, "Public minting is not enabled");
        require(
            walletMintCount[msg.sender] + quantity_ <= maxPerWallet,
            "Max mint per wallet exceeded"
        );
        require(totalSupply + quantity_ <= maxSupply, "Sold out");
        require(msg.value == quantity_ * mintPrice, "Not enough ETH sent");

        for (uint256 i = 0; i < quantity_; i++) {
            uint256 newTokenId = totalSupply + 1;
            totalSupply++;
            _safeMint(msg.sender, newTokenId);
        }
    }
}
