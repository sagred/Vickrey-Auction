// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TokenizedVickeryAuction.sol";
import "../src/MockERC721.sol";
import "../src/MockERC20.sol";

contract EndAuctionTest is Test {
    TokenizedVickeryAuction auction;
    MockERC721 erc721;
    MockERC20 erc20;
    uint256 tokenId = 1;
    uint96 bidAmount = 10 ether;
    uint96 secondBidAmount = 8 ether;
    bytes32 nonce1 = keccak256("secret1");
    bytes32 nonce2 = keccak256("secret2");
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

        uint32 startTime = uint32(block.timestamp - 2 hours); // Start time in the past

        auction.createAuction(address(erc721), tokenId, address(erc20), startTime, bidPeriod, revealPeriod, reservePrice);

        // Commit and reveal two bids
        commitAndRevealBid(bidAmount, nonce1);
        commitAndRevealBid(secondBidAmount, nonce2);
    }

    function commitAndRevealBid(uint96 amount, bytes32 nonce) internal {
        // Make sure we're in the bidding period
        vm.warp(uint32(block.timestamp - 1 hours));

        uint64 auctionIndex = auction.getAuction(address(erc721), tokenId).index;
        bytes20 commitment = bytes20(keccak256(abi.encode(nonce, amount, address(erc721), tokenId, auctionIndex)));

        auction.commitBid(address(erc721), tokenId, commitment, amount);

        // Warp to the reveal period
        vm.warp(uint32(block.timestamp + bidPeriod + 1 hours));
        auction.revealBid(address(erc721), tokenId, amount, nonce);
    }

    function testEndAuction() public {
        // Warp to after the reveal period
        vm.warp(uint32(block.timestamp + revealPeriod + 2 hours));

        auction.endAuction(address(erc721), tokenId);

        // Verify the auction state
        assertEq(erc721.ownerOf(tokenId), address(this)); // Assuming the test contract is the highest bidder

        // Add checks for ERC20 token balances to verify the seller received the second highest bid

        // Additional assertions can be added to fully test the functionality
    }
}

