// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TokenizedVickeryAuction.sol";
import "../src/MockERC721.sol";
import "../src/MockERC20.sol";

contract WithdrawCollateralTest is Test {
    TokenizedVickeryAuction auction;
    MockERC721 erc721;
    MockERC20 erc20;
    uint256 tokenId = 1;
    uint96 bidAmount = 10 ether;
    uint96 higherBidAmount = 15 ether;
    bytes32 nonce1 = keccak256("secret1");
    bytes32 nonce2 = keccak256("secret2");
    address bidder = address(0x123);
    address higherBidder = address(0x456);

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
        erc20.mint(bidder, 1000 ether);
        erc20.mint(higherBidder, 1000 ether);
        erc20.approve(address(auction), 2000 ether);

        startTime = uint32(block.timestamp - 1 hours);
        auction.createAuction(address(erc721), tokenId, address(erc20), startTime, bidPeriod, revealPeriod, reservePrice);

        commitAndRevealBid(bidAmount, nonce1, bidder);
        commitAndRevealBid(higherBidAmount, nonce2, higherBidder);

        uint32 endOfRevealPeriod = startTime + bidPeriod + revealPeriod;
        vm.warp(endOfRevealPeriod + 1 hours);
        auction.endAuction(address(erc721), tokenId);
    }

    function commitAndRevealBid(uint96 amount, bytes32 nonce, address bidderAddress) internal {
        vm.startPrank(bidderAddress);
        erc20.approve(address(auction), amount);

        uint64 auctionIndex = auction.getAuction(address(erc721), tokenId).index;
        bytes20 commitment = bytes20(keccak256(abi.encode(nonce, amount, address(erc721), tokenId, auctionIndex)));

        auction.commitBid(address(erc721), tokenId, commitment, amount);
        vm.warp(startTime + bidPeriod + 1 hours);
        auction.revealBid(address(erc721), tokenId, amount, nonce);
        vm.stopPrank();
    }

    function testWithdrawCollateral() public {
        uint64 auctionIndex = auction.getAuction(address(erc721), tokenId).index;
        uint256 initialBalance = erc20.balanceOf(bidder);

        vm.startPrank(bidder);
        auction.withdrawCollateral(address(erc721), tokenId, auctionIndex);
        vm.stopPrank();

        uint256 finalBalance = erc20.balanceOf(bidder);
        assertEq(finalBalance, initialBalance + bidAmount);
    }
}
