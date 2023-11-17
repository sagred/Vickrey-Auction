// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VickreyAuction.sol";

contract VickreyAuctionGetAuctionTest is Test {
    VickreyAuction auction;
    uint256 itemId = 1;
    uint32 startTime;
    uint32 bidPeriod = 1 days;
    uint32 revealPeriod = 1 days;
    uint96 reservePrice = 1 ether;

    function setUp() public {
        auction = new VickreyAuction();
        startTime = uint32(block.timestamp) + 1 days;
        auction.createAuction(itemId, startTime, bidPeriod, revealPeriod, reservePrice);
    }

    function testGetAuction() public {
        VickreyAuction.Auction memory retrievedAuction = auction.getAuction(itemId);
        
        assertEq(retrievedAuction.seller, address(this));
        assertEq(retrievedAuction.startTime, startTime);
        assertEq(retrievedAuction.endOfBiddingPeriod, startTime + bidPeriod);
        assertEq(retrievedAuction.endOfRevealPeriod, startTime + bidPeriod + revealPeriod);
        assertEq(retrievedAuction.highestBid, reservePrice);
        assertEq(retrievedAuction.secondHighestBid, reservePrice);
        assertEq(retrievedAuction.highestBidder, address(0));
        assertEq(retrievedAuction.numUnrevealedBids, 0);
        assertEq(retrievedAuction.index, 1);
    }

    function testGetNonexistentAuction() public {
    VickreyAuction.Auction memory retrievedAuction = auction.getAuction(999); // Assuming 999 is a non-existent item ID

    assertEq(retrievedAuction.seller, address(0));
    assertEq(retrievedAuction.startTime, 0);
    assertEq(retrievedAuction.endOfBiddingPeriod, 0);
    assertEq(retrievedAuction.endOfRevealPeriod, 0);
    assertEq(retrievedAuction.highestBid, 0);
    assertEq(retrievedAuction.secondHighestBid, 0);
    assertEq(retrievedAuction.highestBidder, address(0));
    assertEq(retrievedAuction.numUnrevealedBids, 0);
    assertEq(retrievedAuction.index, 0);
}

}
