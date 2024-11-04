// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Auction} from "../src/Auction.sol";

contract AuctionTest is Test {
    Auction public auction;
    address payable beneficiary;
    uint biddingTime;

    function setUp() public {
        beneficiary = payable(address(0x1234));
        biddingTime = 7 days;
        auction = new Auction(biddingTime, beneficiary);
    }

    function testBidding() public {
        address bidder1 = address(0x5678);
        address bidder2 = address(0x9ABC);

        vm.deal(bidder1, 2 ether);
        vm.deal(bidder2, 3 ether);

        vm.prank(bidder1);
        auction.bid{value: 1 ether}();

        assertEq(auction.highestBidder(), bidder1);
        assertEq(auction.highestBid(), 1 ether);

        vm.prank(bidder2);
        auction.bid{value: 2 ether}();

        assertEq(auction.highestBidder(), bidder2);
        assertEq(auction.highestBid(), 2 ether);
    }

    function testCooldownPeriod() public {
        address bidder = address(0x5678);
        vm.deal(bidder, 3 ether);

        vm.prank(bidder);
        auction.bid{value: 1 ether}();

        vm.prank(bidder);
        vm.expectRevert("Bidding too soon");
        auction.bid{value: 2 ether}();

        vm.warp(block.timestamp + 5 minutes + 1 seconds);

        vm.prank(bidder);
        auction.bid{value: 2 ether}();

        assertEq(auction.highestBid(), 2 ether);
    }

    function testTimeWeightedBidding() public {
        address bidder1 = address(0x5678);
        address bidder2 = address(0x9ABC);

        vm.deal(bidder1, 2 ether);
        vm.deal(bidder2, 3 ether);

        // 第一个用户在正常时间出价1 ETH
        vm.prank(bidder1);
        auction.bid{value: 1 ether}();

        // 记录第一次出价的加权值
        uint firstBidWeighted = auction.highestWeightedBid();
        assertEq(firstBidWeighted, 1 ether, "Normal bid should not be weighted");

        // 跳转到拍卖结束前4分钟
        uint auctionEndTime = auction.auctionEnd();
        vm.warp(auctionEndTime - 4 minutes);

        // bidder2在最后5分钟内出价1.1 ETH
        vm.prank(bidder2);
        auction.bid{value: 1.1 ether}();

        // 验证新的最高出价者是bidder2
        assertEq(auction.highestBidder(), bidder2, "Bidder2 should be highest bidder");

        // 验证实际出价金额
        assertEq(auction.highestBid(), 1.1 ether, "Actual bid amount should be 1.1 ether");

        // 验证加权后的出价金额 (1.1 ether * 120%)
        assertEq(
            auction.highestWeightedBid(),
            (1.1 ether * auction.TIME_WEIGHT_MULTIPLIER()) / 100,
            "Weighted bid should be 1.32 ether"
        );

        // 测试第三个出价者在最后时段出价
        address bidder3 = address(0xDEF0);
        vm.deal(bidder3, 2 ether);
        vm.prank(bidder3);

        // 出价1.2 ETH，实际出价高于前一个出价
        auction.bid{value: 1.2 ether}();

        assertEq(auction.highestBidder(), bidder3, "Bidder3 should be highest bidder");
        assertEq(
            auction.highestWeightedBid(),
            (1.2 ether * auction.TIME_WEIGHT_MULTIPLIER()) / 100,
            "Weighted bid should be 1.44 ether"
        );

        // 添加一个测试，验证较低的出价会被拒绝
        address bidder4 = address(0xBEEF);
        vm.deal(bidder4, 2 ether);
        vm.prank(bidder4);

        // 尝试出价1.15 ETH（低于当前最高价1.2 ETH），应该被拒绝
        vm.expectRevert("Bid must be higher than current highest bid");
        auction.bid{value: 1.15 ether}();
    }

    function testAuctionEndTimeExtension() public {
        address bidder = address(0x5678);
        vm.deal(bidder, 2 ether);

        uint originalEndTime = auction.auctionEnd();
        vm.warp(block.timestamp + 6 days + 23 hours + 55 minutes);

        vm.prank(bidder);
        auction.bid{value: 1 ether}();

        assertEq(auction.auctionEnd(), block.timestamp + auction.TIME_EXTENSION());
    }

    function testEndAuction() public {
        address bidder = address(0x5678);
        vm.deal(bidder, 2 ether);

        vm.prank(bidder);
        auction.bid{value: 1 ether}();

        vm.warp(block.timestamp + 7 days + 1 seconds);

        uint256 initialBalance = beneficiary.balance;
        auction.endAuction();

        assertEq(beneficiary.balance, initialBalance + 1 ether);
    }
}
