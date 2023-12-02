// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TokenizedVickeryAuction.sol";
import "../src/MockERC721.sol";
import "../src/MockERC20.sol";

contract CommitBidTest is Test {
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

        // Create an auction for testing
        uint32 startTime = uint32(block.timestamp + 1 hours);
        uint32 bidPeriod = 1 days;
        uint32 revealPeriod = 1 days;
        uint96 reservePrice = 10 ether;

        auction.createAuction(address(erc721), 1, address(erc20), startTime, bidPeriod, revealPeriod, reservePrice);
    }

    function testCommitBid() public {
        bytes32 hash = keccak256(abi.encodePacked("secret", uint256(10 ether)));
        bytes20 commitment = bytes20(hash);
        uint96 bidAmount = 10 ether;

        // Ensure we're in the bidding period
        vm.warp(block.timestamp + 2 hours);

        auction.commitBid(address(erc721), 1, commitment, bidAmount);

        // Verify the bid details
        (bytes20 storedCommitment, uint96 storedCollateral) = auction.bids(address(erc721), 1, 1, address(this));
        assertEq(storedCommitment, commitment);
        assertEq(storedCollateral, bidAmount);

        // Additional assertions to verify the state of the auction
        // ...
    }

    // Additional test functions for negative scenarios
}
