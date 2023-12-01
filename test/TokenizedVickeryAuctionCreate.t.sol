// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TokenizedVickeryAuction.sol";

contract TokenizedVickeryAuctionCreateTest is Test {
    TokenizedVickeryAuction auction;
    uint256 itemId = 1;
    uint32 startTime;
    uint32 bidPeriod = 1 days;
    uint32 revealPeriod = 1 days;
    uint96 reservePrice = 1 ether;

    function setUp() public {
        auction = new TokenizedVickeryAuction();
        startTime = uint32(block.timestamp) + 1 days;
    }

    function testCreateAuctionSuccess() public {
        auction.createAuction(itemId, startTime, bidPeriod, revealPeriod, reservePrice);

        TokenizedVickeryAuction.Auction memory createdAuction = auction.getAuction(itemId);
        assertEq(createdAuction.seller, address(this));
        assertEq(createdAuction.startTime, startTime);
        assertEq(createdAuction.endOfBiddingPeriod, startTime + bidPeriod);
        assertEq(createdAuction.endOfRevealPeriod, startTime + bidPeriod + revealPeriod);
        assertEq(createdAuction.highestBid, reservePrice);
        assertEq(createdAuction.secondHighestBid, reservePrice);
        assertEq(createdAuction.highestBidder, address(0));
        assertEq(createdAuction.numUnrevealedBids, 0);
        assertEq(createdAuction.index, 1);
    }

    function testFailCreateAuctionInvalidParams() public {
        uint32 invalidStartTime = uint32(block.timestamp) - 1 days; // Past time
        vm.expectRevert("Start time must be in the future"); // Expected revert reason
        auction.createAuction(itemId, invalidStartTime, bidPeriod, revealPeriod, reservePrice);
    }
}
