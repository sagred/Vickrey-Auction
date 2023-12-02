// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TokenizedVickeryAuction.sol";
import "../src/MockERC721.sol";
import "../src/MockERC20.sol";

contract GetAuctionTest is Test {
    TokenizedVickeryAuction auction;
    MockERC721 erc721;
    MockERC20 erc20;
    uint256 tokenId = 1;
    address tokenContract;
    uint32 startTime;
    uint32 bidPeriod = 1 days;
    uint32 revealPeriod = 1 days;
    uint96 reservePrice = 5 ether;

    function setUp() public {
        erc721 = new MockERC721("Test NFT", "TNFT");
        erc20 = new MockERC20("Test Token", "TT", 18);
        auction = new TokenizedVickeryAuction();

        erc721.mint(address(this), tokenId);
        erc721.approve(address(auction), tokenId);
        erc20.mint(address(this), 1000 ether);
        erc20.approve(address(auction), 1000 ether);

        tokenContract = address(erc721);
        startTime = uint32(block.timestamp + 1 hours); // Set start time to 1 hour in the future

        auction.createAuction(tokenContract, tokenId, address(erc20), startTime, bidPeriod, revealPeriod, reservePrice);
    }

    function testGetAuction() public {
        TokenizedVickeryAuction.Auction memory retrievedAuction = auction.getAuction(tokenContract, tokenId);

        // Verify that the auction details are correct
        assertEq(retrievedAuction.seller, address(this));
        assertEq(retrievedAuction.startTime, startTime);
        assertEq(retrievedAuction.endOfBiddingPeriod, startTime + bidPeriod);
        assertEq(retrievedAuction.endOfRevealPeriod, startTime + bidPeriod + revealPeriod);
        assertEq(retrievedAuction.highestBid, reservePrice);
        assertEq(retrievedAuction.secondHighestBid, reservePrice);
        assertEq(retrievedAuction.highestBidder, address(0));
        assertEq(retrievedAuction.erc20Token, address(erc20));
        // Additional checks can be added as necessary
    }
}
