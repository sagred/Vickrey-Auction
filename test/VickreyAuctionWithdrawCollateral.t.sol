// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VickreyAuction.sol";

contract VickreyAuctionWithdrawCollateralTest is Test {
    VickreyAuction auction;
    uint256 itemId = 1;
    uint32 startTime;
    uint32 bidPeriod = 1 days;
    uint32 revealPeriod = 1 days;
    uint96 reservePrice = 1 ether;
    bytes32 nonce = keccak256("random");
    uint96 bidValue = 2 ether;
    address bidder;

    function setUp() public {
        auction = new VickreyAuction();
        startTime = uint32(block.timestamp);
        auction.createAuction(itemId, startTime, bidPeriod, revealPeriod, reservePrice);

        bidder = address(0x123);
        vm.deal(bidder, 10 ether); // Provide test Ether to the bidder
        vm.prank(bidder);
        auction.commitBid{value: bidValue}(itemId, bytes20(keccak256(abi.encode(nonce, bidValue, itemId, auction.getAuction(itemId).index))));

        vm.warp(startTime + bidPeriod + revealPeriod + 1);
        auction.endAuction(itemId);
    }

    //function testSuccessfulWithdrawal() public {
      //  uint initialBalance = bidder.balance;

        //vm.prank(bidder);
        //auction.withdrawCollateral(itemId, auction.getAuction(itemId).index);

        //assertLt(bidder.balance, initialBalance);
    //}

    function testFailWithdrawalByWinningBidder() public {
        vm.prank(address(this));
        auction.withdrawCollateral(itemId, auction.getAuction(itemId).index);
    }

    function testFailWithdrawalBeforeAuctionEnd() public {
        vm.warp(startTime + bidPeriod);

        vm.prank(bidder);
        auction.withdrawCollateral(itemId, auction.getAuction(itemId).index);
    }

    function testFailWithdrawalWithNoCollateral() public {
        vm.prank(bidder);
        auction.withdrawCollateral(itemId, auction.getAuction(itemId).index);

        vm.prank(bidder);
        auction.withdrawCollateral(itemId, auction.getAuction(itemId).index);
    }
}
