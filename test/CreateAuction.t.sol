// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TokenizedVickeryAuction.sol";
import "../src/MockERC721.sol";
import "../src/MockERC20.sol";

contract CreateAuctionTest is Test {
    TokenizedVickeryAuction auction;
    MockERC721 erc721;
    MockERC20 erc20;

    function setUp() public {
        erc721 = new MockERC721("Test NFT", "TNFT");
        erc20 = new MockERC20("Test Token", "TT", 18);
        auction = new TokenizedVickeryAuction();

        erc721.mint(address(this), 1);
        erc721.approve(address(auction), 1);
        erc20.mint(address(this), 1000 ether);
        erc20.approve(address(auction), 1000 ether);
    }

    function testCreateAuction() public {
        uint32 startTime = uint32(block.timestamp + 1 days);
        uint32 bidPeriod = 1 days;
        uint32 revealPeriod = 1 days;
        uint96 reservePrice = 10 ether;

        auction.createAuction(address(erc721), 1, address(erc20), startTime, bidPeriod, revealPeriod, reservePrice);

        TokenizedVickeryAuction.Auction memory createdAuction = auction.getAuction(address(erc721), 1);
        assertEq(createdAuction.seller, address(this));
        assertEq(createdAuction.startTime, startTime);
        assertEq(createdAuction.endOfBiddingPeriod, startTime + bidPeriod);
        assertEq(createdAuction.endOfRevealPeriod, startTime + bidPeriod + revealPeriod);
        assertEq(createdAuction.highestBid, reservePrice);
        assertEq(createdAuction.secondHighestBid, reservePrice);
        assertEq(createdAuction.highestBidder, address(0));
        assertEq(createdAuction.erc20Token, address(erc20));
    }

    // Add more test cases to cover negative scenarios and edge cases
}
