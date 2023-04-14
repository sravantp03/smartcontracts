// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketplace {
    // Custom Errors
    error NFTMarketplace__Price_Error(uint256 price);
    error NFTMarketplace__NotApprovedForMarket();
    error NFTMarketplace__AlreadyListed(address nftAddress, uint256 tokenId);
    error NFTMarketplace__NotListed(address nftAddress, uint256 tokenId);
    error NFTMarketplace__NotOwner();
    error NFTMarketplace__ErrorInPrice(
        address nftAddress,
        uint256 tokenId,
        uint256 nftPrice
    );
    error NFTMarketplace__BuyerError(
        address nftAddress,
        uint256 tokenId,
        address seller,
        address buyer
    );
    error NFTMarketplace__Withdraw_Error();

    // Events
    event NFTListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    event NFTBought(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address seller,
        address indexed buyer,
        uint256 price
    );

    event NFTListingCancelled(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed seller
    );

    event NFTPriceUpdated(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 indexed newPrice
    );

    struct Listing {
        uint256 price;
        address seller;
    }

    mapping(address => mapping(uint256 => Listing)) private s_listings;
    // keeps track of the amount earned via nft sells (later withdraw using withdraw function)
    mapping(address => uint256) private s_earnings;

    modifier isNFTListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price <= 0) {
            revert NFTMarketplace__NotListed(nftAddress, tokenId);
        }
        _;
    }

    modifier notNFTListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price > 0) {
            revert NFTMarketplace__AlreadyListed(nftAddress, tokenId);
        }
        _;
    }

    modifier isOwner(
        address nftAddress,
        uint256 tokenId,
        address seller
    ) {
        if (seller != ERC721(nftAddress).ownerOf(tokenId)) {
            revert NFTMarketplace__NotOwner();
        }
        _;
    }

    // Allow NFT Owner to List NFTs
    function listNFT(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    )
        external
        notNFTListed(nftAddress, tokenId)
        isOwner(nftAddress, tokenId, msg.sender)
    {
        if (price <= 0) {
            revert NFTMarketplace__Price_Error(price);
        }

        // Creating nftContract instance to interact
        ERC721 nftContract = ERC721(nftAddress);

        if (nftContract.getApproved(tokenId) != address(this)) {
            revert NFTMarketplace__NotApprovedForMarket();
        }

        s_listings[nftAddress][tokenId] = Listing({
            price: price,
            seller: msg.sender
        });

        emit NFTListed(msg.sender, nftAddress, tokenId, price);
    }

    // Allow user to Buy NFTs
    function buyNFT(
        address nftAddress,
        uint256 tokenId
    ) external payable isNFTListed(nftAddress, tokenId) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (msg.value != listing.price) {
            revert NFTMarketplace__ErrorInPrice(
                nftAddress,
                tokenId,
                listing.price
            );
        }

        if (msg.sender == listing.seller) {
            revert NFTMarketplace__BuyerError(
                nftAddress,
                tokenId,
                listing.seller,
                msg.sender
            );
        }

        s_earnings[listing.seller] += msg.value; // Updating seller earnings by nft price
        delete s_listings[nftAddress][tokenId]; // deleting the listing for the nft

        // Transfering ownership of Nft from seller to buyer.
        ERC721(nftAddress).safeTransferFrom(
            listing.seller,
            msg.sender,
            tokenId
        );

        emit NFTBought(
            nftAddress,
            tokenId,
            listing.seller,
            msg.sender,
            listing.price
        );
    }

    function cancelListing(
        address nftAddress,
        uint256 tokenId
    )
        external
        isNFTListed(nftAddress, tokenId)
        isOwner(nftAddress, tokenId, msg.sender)
    {
        delete s_listings[nftAddress][tokenId];
        emit NFTListingCancelled(nftAddress, tokenId, msg.sender);
    }

    function updateNFTListing(
        address nftAddress,
        uint256 tokenId,
        uint256 newPrice
    )
        external
        isOwner(nftAddress, tokenId, msg.sender)
        isNFTListed(nftAddress, tokenId)
    {
        s_listings[nftAddress][tokenId].price = newPrice;

        emit NFTPriceUpdated(nftAddress, tokenId, newPrice);
    }

    function viewEarnings(address seller) external view returns (uint256) {
        return s_earnings[seller];
    }

    function withdrawEarnings() external {
        uint256 earnings = s_earnings[msg.sender];

        if (earnings <= 0) {
            revert NFTMarketplace__Withdraw_Error();
        }
        s_earnings[msg.sender] = 0;

        (bool sent, ) = payable(msg.sender).call{value: earnings}("");
        if (!sent) {
            revert NFTMarketplace__Withdraw_Error();
        }
    }

    receive() external payable {}

    fallback() external payable {}
}
