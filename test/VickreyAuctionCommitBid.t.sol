// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "ds-test/test.sol";
import "forge-std/Test.sol";

import "../src/VickreyAuction.sol"; // Adjust the path as per your project structure

contract VickreyAuctionCommitBidTest is DSTest {
    VickreyAuction auction;
    uint256 constant itemId = 1;
    uint32 constant startTime = uint32(block.timestamp + 1 days);
    uint32 constant bidPeriod = 1 days;
    uint32 constant revealPeriod = 1 days;
    uint96 constant reservePrice = 1 ether;
    bytes20 constant dummyCommitment = bytes20(keccak256("dummy"));

    function setUp() public {
        auction = new VickreyAuction();
        auction.createAuction(itemId, startTime, bidPeriod, revealPeriod, reservePrice);
    }

    function testCommitBidWithinPeriod() public {
        // Fast forward time to start bidding period
        hevm.warp(startTime + 1); // 'hevm' is part of the Foundry test environment

        uint256 bidAmount = 1 ether;
        auction.commitBid{value: bidAmount}(itemId, dummyCommitment);

        (, uint96 collateral) = auction.bids(itemId, 0, address(this));
        assertEq(collateral, bidAmount, "Collateral should match the bid amount");
    }

    function testFailCommitBidBeforeStartTime() public {
        hevm.warp(startTime - 1); // Time travel to just before the auction starts

        auction.commitBid{value: 1 ether}(itemId, dummyCommitment);
    }

    function testFailCommitBidAfterBiddingPeriod() public {
        hevm.warp(startTime + bidPeriod + 1); // Time travel to just after the bidding period

        auction.commitBid{value: 1 ether}(itemId, dummyCommitment);
    }

    function testFailCommitBidWithInsufficientCollateral() public {
        hevm.warp(startTime + 1); // During the bidding period

        auction.commitBid{value: 0.5 ether}(itemId, dummyCommitment); // Assuming 1 ether is the minimum bid
    }

    // Add more test cases as required...
}
