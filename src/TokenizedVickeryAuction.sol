// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenizedVickeryAuction {
    struct Auction {
        address seller;
        uint32 startTime;
        uint32 endOfBiddingPeriod;
        uint32 endOfRevealPeriod;
        uint64 numUnrevealedBids;
        uint96 highestBid;
        uint96 secondHighestBid;
        address highestBidder;
        uint64 index;
        address erc20Token;
    }

    struct Bid {
        bytes20 commitment;
        uint96 collateral;
    }

    mapping(address => mapping(uint256 => Auction)) public auctions;
    mapping(address => mapping(uint256 => mapping(uint64 => mapping(address => Bid)))) public bids;

    function createAuction(
        address tokenContract,
        uint256 tokenId,
        address erc20Token,
        uint32 startTime,
        uint32 bidPeriod,
        uint32 revealPeriod,
        uint96 reservePrice
    ) external {
        require(startTime >= block.timestamp, "Start time must be in the future");
        require(bidPeriod > 0, "Bid period must be positive");
        require(revealPeriod > 0, "Reveal period must be positive");

        Auction storage auction = auctions[tokenContract][tokenId];
        auction.seller = msg.sender;
        auction.startTime = startTime;
        auction.endOfBiddingPeriod = startTime + bidPeriod;
        auction.endOfRevealPeriod = startTime + bidPeriod + revealPeriod;
        auction.numUnrevealedBids = 0;
        auction.highestBid = reservePrice;
        auction.secondHighestBid = reservePrice;
        auction.highestBidder = address(0);
        auction.index++;
        auction.erc20Token = erc20Token;

        IERC721(tokenContract).transferFrom(msg.sender, address(this), tokenId);
    }

    function commitBid(address tokenContract, uint256 tokenId, bytes20 commitment, uint96 erc20Tokens) external {
        Auction storage auction = auctions[tokenContract][tokenId];
        require(block.timestamp >= auction.startTime && block.timestamp < auction.endOfBiddingPeriod, "Bidding period not active");

        IERC20(auction.erc20Token).transferFrom(msg.sender, address(this), erc20Tokens);

        Bid storage bid = bids[tokenContract][tokenId][auction.index][msg.sender];
        bid.commitment = commitment;
        bid.collateral = erc20Tokens;
        auction.numUnrevealedBids++;
    }

    function revealBid(address tokenContract, uint256 tokenId, uint96 bidValue, bytes32 nonce) external {
        Auction storage auction = auctions[tokenContract][tokenId];
        require(block.timestamp >= auction.endOfBiddingPeriod && block.timestamp < auction.endOfRevealPeriod, "Reveal period not active");

        Bid storage bid = bids[tokenContract][tokenId][auction.index][msg.sender];
        require(bid.commitment == bytes20(keccak256(abi.encode(nonce, bidValue, tokenContract, tokenId, auction.index))), "Invalid commitment");

        if (bidValue > auction.highestBid) {
            auction.secondHighestBid = auction.highestBid;
            auction.highestBid = bidValue;
            auction.highestBidder = msg.sender;
        } else if (bidValue > auction.secondHighestBid) {
            auction.secondHighestBid = bidValue;
        }

        bid.commitment = bytes20(0);
        auction.numUnrevealedBids--;
    }

    function endAuction(address tokenContract, uint256 tokenId) external {
        Auction storage auction = auctions[tokenContract][tokenId];
        require(block.timestamp >= auction.endOfRevealPeriod || auction.numUnrevealedBids == 0, "Auction not yet ended");

        if (auction.highestBidder != address(0)) {
            IERC20(auction.erc20Token).transfer(auction.seller, auction.secondHighestBid);
            IERC721(tokenContract).transferFrom(address(this), auction.highestBidder, tokenId);
        } else {
            IERC721(tokenContract).transferFrom(address(this), auction.seller, tokenId);
        }

        delete auctions[tokenContract][tokenId];
    }

    function withdrawCollateral(address tokenContract, uint256 tokenId, uint64 auctionIndex) external {
        Bid storage bid = bids[tokenContract][tokenId][auctionIndex][msg.sender];
        require(bid.commitment == bytes20(0), "Bid not opened");
        require(msg.sender != auctions[tokenContract][tokenId].highestBidder, "Cannot withdraw collateral as highest bidder");

        uint96 collateral = bid.collateral;
        bid.collateral = 0;
        IERC20(auctions[tokenContract][tokenId].erc20Token).transfer(msg.sender, collateral);
    }

    function getAuction(address tokenContract, uint256 tokenId) external view returns (Auction memory) {
        return auctions[tokenContract][tokenId];
    }
}
