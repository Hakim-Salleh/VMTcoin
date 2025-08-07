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
            msg.sender,
            uint64(block.timestamp),
            address(token)
        );

        // Deploy AdminRouter
        AdminRouter admin = new AdminRouter();

        vm.stopBroadcast();
    }
}
