// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VickreyAuction.sol";

contract VickreyAuctionEndAuctionTest is Test {
    VickreyAuction auction;
    uint256 itemId = 1;
    uint32 startTime;
    uint32 bidPeriod = 1 days;
    uint32 revealPeriod = 1 days;
    uint96 reservePrice = 1 ether;
    bytes32 nonce = keccak256("random");
    uint96 bidValue = 2 ether;

    function setUp() public {
        auction = new VickreyAuction();
        startTime = uint32(block.timestamp);
        auction.createAuction(itemId, startTime, bidPeriod, revealPeriod, reservePrice);

        vm.warp(startTime + 1);
        auction.commitBid{value: bidValue}(itemId, bytes20(keccak256(abi.encode(nonce, bidValue, itemId, auction.getAuction(itemId).index))));

        vm.warp(startTime + bidPeriod + 1);
        auction.revealBid(itemId, bidValue, nonce);
    }

    function testSuccessfulEndAuction() public {
        // Fast-forward to end of reveal period
        vm.warp(startTime + bidPeriod + revealPeriod + 1);

        auction.endAuction(itemId);

    }

    function testFailEndAuctionEarly() public {
    vm.warp(startTime + bidPeriod + revealPeriod - 1);
    
    try auction.endAuction(itemId) {
        fail("Auction ended before reveal period is over");
    } catch Error(string memory reason) {
        assertEq(reason, "Reveal period not over"); // Replace with your actual revert message
    }
}

    function testFailEndNonExistentAuction() public {
    uint256 nonExistentItemId = itemId + 1000; // Assure itemId is indeed non-existent
    try auction.endAuction(nonExistentItemId) {
        fail("Auction ended for a non-existent item");
    } catch Error(string memory reason) {
        assertEq(reason, "Auction does not exist"); // Replace with your actual revert message
    }
}


    function testFailEndAuctionWithNoValidBids() public {
        uint256 newItemId = itemId + 1;
        auction.createAuction(newItemId, startTime, bidPeriod, revealPeriod, reservePrice);

        vm.warp(startTime + bidPeriod + revealPeriod + 1);

        auction.endAuction(newItemId);
    }
}
