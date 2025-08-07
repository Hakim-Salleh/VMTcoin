// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VMTcoin.sol";
import "../src/VestingWallet.sol";
import "../src/AdminRouter.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy VMT token
        VMTcoin token = new VMTcoin();

        // Deploy VestingWallet example (adjust constructor args as needed)
        VestingWallet vesting = new VestingWallet(
            address(token),
            msg.sender,
            uint64(block.timestamp) + 1 * 24 * 60 * 60,
            uint64(block.timestamp) + 7 * 24 * 60 * 60
        );

        // Deploy AdminRouter
        AdminRouter admin = new AdminRouter(payable(token), msg.sender, msg.sender);

        vm.stopBroadcast();
    }
}
