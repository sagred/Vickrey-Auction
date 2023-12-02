// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TokenizedVickeryAuction.sol";
import "../src/MockERC721.sol";
import "../src/MockERC20.sol";

contract RevealBidTest is Test {
    TokenizedVickeryAuction auction;
    MockERC721 erc721;
    MockERC20 erc20;
    bytes32 nonce = keccak256(abi.encodePacked("secret"));
    uint96 bidAmount = 10 ether;
    uint256 tokenId = 1;

    function setUp() public {
        erc721 = new MockERC721("Test NFT", "TNFT");
        erc20 = new MockERC20("Test Token", "TT", 18);
        auction = new TokenizedVickeryAuction();

        erc721.mint(address(this), tokenId);
        erc721.approve(address(auction), tokenId);
        erc20.mint(address(this), 1000 ether);
        erc20.approve(address(auction), 1000 ether);

        uint32 startTime = uint32(block.timestamp + 1 hours);
        uint32 bidPeriod = 1 days;
        uint32 revealPeriod = 1 days;
        uint96 reservePrice = 5 ether;

        auction.createAuction(address(erc721), tokenId, address(erc20), startTime, bidPeriod, revealPeriod, reservePrice);
        uint64 auctionIndex = auction.getAuction(address(erc721), tokenId).index;
        bytes20 commitment = bytes20(keccak256(abi.encode(nonce, bidAmount, address(erc721), tokenId, auctionIndex)));

        vm.warp(block.timestamp + 2 hours);
        auction.commitBid(address(erc721), tokenId, commitment, bidAmount);
    }

    function testRevealBid() public {
        // Warp to the reveal period
        vm.warp(block.timestamp + 1 days + 2 hours);

        uint64 auctionIndex = auction.getAuction(address(erc721), tokenId).index;
        auction.revealBid(address(erc721), tokenId, bidAmount, nonce);

        // Verify the auction state after revealing the bid
        TokenizedVickeryAuction.Auction memory currentAuction = auction.getAuction(address(erc721), tokenId);
        assertEq(currentAuction.highestBid, bidAmount);
        assertEq(currentAuction.highestBidder, address(this));
        assertEq(currentAuction.numUnrevealedBids, 0);

        // Additional assertions can be added to fully test the functionality
    }

    // Additional test functions for negative scenarios
}
