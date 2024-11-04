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

        vm.prank(bidder1);
        auction.bid{value: 1 ether}();

        uint auctionEndTime = auction.auctionEnd();
        vm.warp(auctionEndTime - 4 minutes);

        console2.log("Current time:", block.timestamp);
        console2.log("Auction end time:", auctionEndTime);
        console2.log("Time difference:", auctionEndTime - block.timestamp);

        vm.prank(bidder2);
        auction.bid{value: 1 ether}();

        assertEq(auction.highestBidder(), bidder2);
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
