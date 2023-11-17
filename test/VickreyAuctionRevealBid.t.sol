// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VickreyAuction.sol";

contract VickreyAuctionRevealBidTest is Test {
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
}


    function testSuccessfulRevealBid() public {
        vm.warp(startTime + bidPeriod + 1); // Move time to reveal period
        auction.revealBid(itemId, bidValue, nonce);
        
        VickreyAuction.Auction memory currentAuction = auction.getAuction(itemId);
        assertEq(currentAuction.highestBid, bidValue);
    }

    function testFailRevealWithIncorrectNonce() public {
        vm.warp(startTime + bidPeriod + 1); // Move time to reveal period
        auction.revealBid(itemId, bidValue, "wrongnonce");
    }

    function testFailRevealWithIncorrectValue() public {
        vm.warp(startTime + bidPeriod + 1); // Move time to reveal period
        auction.revealBid(itemId, bidValue + 1 ether, nonce);
    }

    function testFailRevealOutsideRevealPeriod() public {
        auction.revealBid(itemId, bidValue, nonce);
    }
}
