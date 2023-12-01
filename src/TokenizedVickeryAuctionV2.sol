// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "./TokenizedVickeryAuction.sol";

contract TokenizedVickeryAuctionV2 is TokenizedVickeryAuction {
    mapping(address => bool) private blacklist;

    event SellerBlacklisted(address indexed account);
    event SellerUnblacklisted(address indexed account);

    function addToBlacklist(address account) external {
        require(!blacklist[account], "Account is already blacklisted");
        blacklist[account] = true;
        emit SellerBlacklisted(account);
    }

    function removeFromBlacklist(address account) external {
        require(blacklist[account], "Account is not blacklisted");
        blacklist[account] = false;
        emit SellerUnblacklisted(account);
    }

    function createAuction(
        address tokenContract,
        uint256 tokenId,
        address erc20Token,
        uint32 startTime,
        uint32 bidPeriod,
        uint32 revealPeriod,
        uint96 reservePrice
    ) public override {
        require(!blacklist[msg.sender], "Seller is blacklisted");
        super.createAuction(tokenContract, tokenId, erc20Token, startTime, bidPeriod, revealPeriod, reservePrice);
    }
}
