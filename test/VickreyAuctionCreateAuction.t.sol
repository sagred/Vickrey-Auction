// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "ds-test/test.sol";
import "../src/VickreyAuction.sol";

contract VickreyAuctionCreateAuctionTest is DSTest {
    VickreyAuction auction;

    function setUp() public {
        auction = new VickreyAuction();
    }

    function testCreateAuctionWithValidParameters() public {
        uint256 itemId = 1;
        uint32 startTime = uint32(block.timestamp + 1 days);
        uint32 bidPeriod = 1 days;
        uint32 revealPeriod = 1 days;
        uint96 reservePrice = 1 ether;

        auction.createAuction(itemId, startTime, bidPeriod, revealPeriod, reservePrice);
        VickreyAuction.Auction memory createdAuction = auction.getAuction(itemId);

        assertEq(createdAuction.seller, address(this));
        assertEq(createdAuction.startTime, startTime);
        assertEq(createdAuction.endOfBiddingPeriod, startTime + bidPeriod);
        assertEq(createdAuction.endOfRevealPeriod, startTime + bidPeriod + revealPeriod);
        assertEq(createdAuction.highestBid, reservePrice);
        assertEq(createdAuction.secondHighestBid, reservePrice);
    }

    function testFailCreateAuctionWithStartTimeInPast() public {
        uint256 itemId = 2;
        uint32 startTime = uint32(block.timestamp - 1 days); // Past time
        uint32 bidPeriod = 1 days;
        uint32 revealPeriod = 1 days;
        uint96 reservePrice = 1 ether;

        auction.createAuction(itemId, startTime, bidPeriod, revealPeriod, reservePrice);
    }

    function testFailCreateAuctionWithNegativeBidPeriod() public {
        uint256 itemId = 3;
        uint32 startTime = uint32(block.timestamp + 1 days);
        uint32 bidPeriod = 0; // Invalid bid period
        uint32 revealPeriod = 1 days;
        uint96 reservePrice = 1 ether;

        auction.createAuction(itemId, startTime, bidPeriod, revealPeriod, reservePrice);
    }

    function testFailCreateAuctionWithNegativeRevealPeriod() public {
        uint256 itemId = 4;
        uint32 startTime = uint32(block.timestamp + 1 days);
        uint32 bidPeriod = 1 days;
        uint32 revealPeriod = 0; // Invalid reveal period
        uint96 reservePrice = 1 ether;

        auction.createAuction(itemId, startTime, bidPeriod, revealPeriod, reservePrice);
    }

}
