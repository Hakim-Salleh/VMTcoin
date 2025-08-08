// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/VMTcoin.sol";
import "../src/AdminRouter.sol";
import "../src/VestingWallet.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployAll is Script {
    function run() external {
        // Load deployer's private key from .env or hardcode
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Setup deploy parameters
        address daoTreasury = address(0xDA0);       // Replace with actual DAO treasury address
        address backupAdmin = address(0xBEEF);      // Replace with real backup admin
        address vestingBeneficiary = address(0x1234); // Replace with real beneficiary
        uint256 vestingStart = block.timestamp + 1 days;
        uint256 vestingDuration = 365 days;

        vm.startBroadcast(deployerPrivateKey);

        // --- Step 1: Deploy logic (VMTcoin implementation) ---
        VMTcoin logic = new VMTcoin();

        // Encode initializer
        bytes memory initData = abi.encodeWithSignature(
            "initialize(address,address,address)",
            msg.sender,    // initialOwner
            daoTreasury,
            backupAdmin
        );

        // Deploy proxy pointing to logic with init data
        ERC1967Proxy proxy = new ERC1967Proxy(address(logic), initData);
        VMTcoin vmt = VMTcoin(payable(proxy));

        // --- Step 2: Deploy AdminRouter ---
        AdminRouter router = new AdminRouter(payable(address(vmt)), daoTreasury, backupAdmin);

        // --- Step 3: Deploy VestingWallet ---
        VestingWallet vesting = new VestingWallet(address(vmt), vestingBeneficiary, vestingStart, vestingDuration);

        // --- Logs ---
        console2.log("Deployer:", msg.sender);
        console2.log("VMTcoin Logic:", address(logic));
        console2.log("VMTcoin Proxy:", address(vmt));
        console2.log("AdminRouter:", address(router));
        console2.log("VestingWallet:", address(vesting));

        vm.stopBroadcast();
    }
}
