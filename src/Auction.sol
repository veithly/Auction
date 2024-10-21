// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Auction {
    address payable public beneficiary;
    uint public auctionEnd;
    address public highestBidder;
    uint public highestBid;
    mapping(address => uint) pendingReturns;
    bool ended;

    // 新增变量
    uint public constant COOL_DOWN_PERIOD = 5 minutes;
    uint public constant TIME_EXTENSION = 5 minutes;
    uint public constant LAST_MINUTES_THRESHOLD = 5 minutes;
    uint public constant TIME_WEIGHT_MULTIPLIER = 120; // 120%
    mapping(address => uint) lastBidTime;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor(uint _biddingTime, address payable _beneficiary) {
        beneficiary = _beneficiary;
        auctionEnd = block.timestamp + _biddingTime;
    }

    function bid() public payable {
        require(block.timestamp < auctionEnd, "Auction already ended");
        require(msg.value > highestBid, "There already is a higher bid");

        // 实现冷却机制
        require(block.timestamp > lastBidTime[msg.sender] + COOL_DOWN_PERIOD, "Bidding too soon");

        // 实现时间加权
        uint weightedBid = msg.value;
        if (auctionEnd - block.timestamp <= LAST_MINUTES_THRESHOLD) {
            weightedBid = msg.value * TIME_WEIGHT_MULTIPLIER / 100;
        }

        require(weightedBid > highestBid, "There already is a higher weighted bid");

        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        lastBidTime[msg.sender] = block.timestamp;
        emit HighestBidIncreased(msg.sender, msg.value);

        // 实现拍卖终局延长
        if (auctionEnd - block.timestamp <= LAST_MINUTES_THRESHOLD) {
            auctionEnd = block.timestamp + TIME_EXTENSION;
        }
    }

    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            if (!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function endAuction() public {
        require(block.timestamp >= auctionEnd, "Auction not yet ended");
        require(!ended, "auctionEnd has already been called");

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        beneficiary.transfer(highestBid);
    }
}
