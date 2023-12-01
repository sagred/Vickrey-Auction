// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

contract VickreyAuction {
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
    }

    struct Bid {
        bytes20 commitment;
        uint96 collateral;
    }

    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => mapping(uint64 => mapping(address => Bid))) public bids;

    function createAuction(
        uint256 itemId,
        uint32 startTime,
        uint32 bidPeriod,
        uint32 revealPeriod,
        uint96 reservePrice
    ) external {
        require(startTime >= block.timestamp, "Start time must be in the future");
        require(bidPeriod > 0, "Bid period must be positive");
        require(revealPeriod > 0, "Reveal period must be positive");

        Auction memory newAuction = Auction({
            seller: msg.sender,
            startTime: startTime,
            endOfBiddingPeriod: startTime + bidPeriod,
            endOfRevealPeriod: startTime + bidPeriod + revealPeriod,
            numUnrevealedBids: 0,
            highestBid: reservePrice,
            secondHighestBid: reservePrice,
            highestBidder: address(0),
            index: uint64(auctions[itemId].index + 1)
        });

        auctions[itemId] = newAuction;
    }

    function commitBid(uint256 itemId, bytes20 commitment) external payable {
        Auction storage auction = auctions[itemId];
        require(block.timestamp >= auction.startTime && block.timestamp < auction.endOfBiddingPeriod, "Bidding period not active");

        bids[itemId][auction.index][msg.sender] = Bid({
            commitment: commitment,
            collateral: uint96(msg.value)
        });

        auction.numUnrevealedBids++;
    }

    function revealBid(uint256 itemId, uint96 bidValue, bytes32 nonce) external {
        Auction storage auction = auctions[itemId];
        require(block.timestamp >= auction.endOfBiddingPeriod && block.timestamp < auction.endOfRevealPeriod, "Reveal period not active");

        bytes20 commitment = bytes20(keccak256(abi.encode(nonce, bidValue, itemId, auction.index)));
        Bid storage bid = bids[itemId][auction.index][msg.sender];

        require(bid.commitment == commitment, "Commitment does not match");

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

    function endAuction(uint256 itemId) external {
        Auction storage auction = auctions[itemId];
        require(block.timestamp >= auction.endOfRevealPeriod || auction.numUnrevealedBids == 0, "Auction not yet ended");
        delete auctions[itemId];
    }

    function withdrawCollateral(uint256 itemId, uint64 auctionIndex) external {
        Bid storage bid = bids[itemId][auctionIndex][msg.sender];
        require(bid.commitment == bytes20(0), "Bid not opened");
        require(msg.sender != auctions[itemId].highestBidder, "Cannot withdraw collateral as highest bidder");

        uint96 collateral = bid.collateral;
        bid.collateral = 0;
        payable(msg.sender).transfer(collateral);
    }

    function getAuction(uint256 itemId) external view returns (Auction memory) {
        return auctions[itemId];
    }
}
