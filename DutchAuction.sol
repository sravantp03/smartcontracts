// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC721 {
    function transferFrom(address _from, address _to, uint256 _nftId) external;
}

contract DutchAuction {
    uint256 public constant DURATION = 7 days;
    uint256 public immutable nftId;
    IERC721 public immutable nft;
    address payable public immutable seller;
    uint256 public immutable startingPrice;

    uint256 public immutable startAt;
    uint256 public immutable expiresAt;
    uint256 public immutable discountRate;

    constructor(
        uint256 _startingPrice,
        uint256 _discountRate,
        address _nft,
        uint256 _nftId
    ) {
        seller = payable(msg.sender);
        startingPrice = _startingPrice;
        discountRate = _discountRate;
        nft = IERC721(_nft);
        nftId = _nftId;
        startAt = block.timestamp;
        expiresAt = startAt + DURATION;

        require(
            _startingPrice >= discountRate * DURATION,
            "Starting Price < Discount Rate"
        );
    }

    // calculate price when user calls buy function.
    function getPrice() public view returns (uint256) {
        uint256 discount = discountRate * (block.timestamp - startAt);
        return startingPrice - discount;
    }

    function buy() public payable {
        uint256 price = getPrice();
        require(block.timestamp < expiresAt, "Auction Expired");
        require(msg.value >= price, "Not enough Fund");

        // Transfering NFT to buyer.
        nft.transferFrom(seller, msg.sender, nftId);

        // Refunding if buyer send more ETH than price.
        uint256 refundAmt = msg.value - price;
        require(refundAmt > 0, "");
        (bool success, ) = payable(msg.sender).call{value: refundAmt}("");
        require(success, "Transfer Failed");

        // Deleting Contract after successful purchase.
        selfdestruct(seller);
    }
}
