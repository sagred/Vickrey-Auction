// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TokenizedVickeryAuctionV2.sol";
import "../src/MockERC721.sol";
import "../src/MockERC20.sol";

contract BlacklistFunctionalityTest is Test {
    TokenizedVickeryAuctionV2 auction;
    MockERC721 erc721;
    MockERC20 erc20;
    uint256 tokenId = 1;
    address seller = address(0x123);
    uint32 startTime;
    uint32 bidPeriod = 1 days;
    uint32 revealPeriod = 1 days;
    uint96 reservePrice = 5 ether;

    function setUp() public {
        erc721 = new MockERC721("Test NFT", "TNFT");
        erc20 = new MockERC20("Test Token", "TT", 18);
        auction = new TokenizedVickeryAuctionV2();

        // Ensure the seller is set correctly for the NFT
        vm.prank(seller);
        erc721.mint(seller, tokenId);
        vm.prank(seller);
        erc721.approve(address(auction), tokenId);

        startTime = uint32(block.timestamp + 1 hours);
    }

    function testBlacklist() public {
        // Add seller to blacklist
        auction.addToBlacklist(seller);

        // Attempt to create an auction with a blacklisted seller
        vm.startPrank(seller);
        vm.expectRevert("Seller is blacklisted");
        auction.createAuction(address(erc721), tokenId, address(erc20), startTime, bidPeriod, revealPeriod, reservePrice);
        vm.stopPrank();

        // Remove seller from blacklist
        auction.removeFromBlacklist(seller);

        // Retry auction creation
        vm.startPrank(seller);
        auction.createAuction(address(erc721), tokenId, address(erc20), startTime, bidPeriod, revealPeriod, reservePrice);
        vm.stopPrank();
    }
}
