// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {Auction} from "../src/Auction.sol";

contract DeployAuction is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address payable beneficiary = payable(vm.envAddress("BENEFICIARY_ADDRESS"));
        uint256 biddingTime = 7 days;

        vm.startBroadcast(deployerPrivateKey);

        Auction auction = new Auction(biddingTime, beneficiary);

        console2.log("Auction deployed at:", address(auction));

        vm.stopBroadcast();
    }
}
