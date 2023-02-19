// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title Dancing Cows NFT Contract
 * @author Sravan
 * @notice contract address : 0xFb1b8eb91ACf7A50cE22226D07B63Af96c0a17B4
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DancingCows is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    uint256 private publicMintPrice; // initial mint price.
    uint256 private maxSupply;
    mapping(address => bool) private allowList;

    // Track the mint state of contract.
    enum MintState {
        CLOSED,
        ALLOWLIST,
        PUBLIC
    } 

    MintState public NFTMintState = MintState.CLOSED; // initailly mint is closed.

    constructor() ERC721("DancingCows", "DCS") {
        publicMintPrice = 0.01 ether;
        maxSupply = 10; // initial number of tokens that can able to mint.
    }

    // Public Mint.
    // allow public to mint nft
    function safeMint() public payable {
        require(NFTMintState == MintState.PUBLIC, "Error, Public Mint is not open");
        require(msg.value == publicMintPrice, "Not enough Fund to Mint Token");
        mintNFT();
    }

    // AllowList Mint
    // Only people in the allowlist can mint token.
    function allowListMint() public payable {
        require(NFTMintState == MintState.ALLOWLIST, "Error, AllowList Mint is not open");
        require(allowList[msg.sender], "You are not allowlisted to mint");
        require(msg.value == 0.001 ether, "Not enough Fund to Mint Token"); // allowlist people can mint token at 0.001 ether (fixed).
        mintNFT();
    }

    // Seperating minting logic here.
    function mintNFT() internal {
        require(totalSupply() < maxSupply, "Sold out.");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // public can get the current mint price.
    function getPublicMintPrice() public view returns(uint256) {
        return publicMintPrice;
    }

    // owner can change the mint price in the future.
    function setMintPrice(uint256 mintPrice_) public onlyOwner {
        publicMintPrice = mintPrice_;
    }

    // public can view the maximum token available to mint.
    function getMaxSupply() public view returns(uint256) {
        return maxSupply;
    }

    // owner can set the max supply of token
    function setMaxSupply(uint256 maxSupply_) public onlyOwner {
        // when updating max supply value it should be greater than current supply value.
        require(maxSupply_ >= totalSupply(), "Invalid Maxsupply value.");
        maxSupply = maxSupply_;
    }

    // owner can set allowlist address / addresses using this function.
    function setAllowListAddress(address[] calldata userAddresses_) public onlyOwner {
        for (uint256 i = 0; i < userAddresses_.length; i++) {
            allowList[userAddresses_[i]] = true;
        }
    }

    // public can see whether they are allowlisted/ whitelisted or not.
    function getAllowListStatus(address userAddress_) public view returns(bool) {
        return allowList[userAddress_];
    }

    // owner need to toggle allowlist mint to enable the whitelisted user to start mint the token.
    function toggleAllowListMint() public onlyOwner {
        NFTMintState = MintState.ALLOWLIST;
    }

    // owner need to toggle public mint to enable everyone to start mint the token.
    function togglePublicMint() public onlyOwner {
        NFTMintState = MintState.PUBLIC;
    }

    // Owner can close the mint
    function closeMint() public onlyOwner {
        NFTMintState = MintState.CLOSED;
    }

    // owner can withdraw eth.
    function withdrawFunds() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Transaction failed");
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmUozsRCC5uTqu7FnDAa5CggxuJK8JabQdXX6R2TN2exgf/";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }
}