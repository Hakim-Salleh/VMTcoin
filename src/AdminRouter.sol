// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./VMTcoin.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AdminRouter
 * @dev Utility contract to help manage VMTcoin roles and entities
 */
contract AdminRouter is Ownable {
    VMTcoin public vmtToken;

    constructor(address payable _vmtToken, address daoTreasury, address backupAdmin) Ownable(msg.sender) {
        require(_vmtToken != address(0), "Invalid token address");
        vmtToken = VMTcoin(_vmtToken);
    }

    function registerEntityWallet(string memory name, address wallet) external onlyOwner {
        vmtToken.registerEntityWallet(name, wallet);
    }

    function grantRole(bytes32 role, address account) external onlyOwner {
        vmtToken.grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) external onlyOwner {
        vmtToken.revokeRole(role, account);
    }

    function transferAdmin(address newAdmin) external onlyOwner {
        require(newAdmin != address(0), "Zero address");
        vmtToken.grantRole(vmtToken.DEFAULT_ADMIN_ROLE(), newAdmin);
        vmtToken.revokeRole(vmtToken.DEFAULT_ADMIN_ROLE(), owner());
    }

    function updateDaoTreasury(address newTreasury) external onlyOwner {
        vmtToken.setDaoTreasury(newTreasury);
    }
}
