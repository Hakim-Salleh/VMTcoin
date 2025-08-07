// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VMTcoin.sol";

contract VMTcoinTest is Test {
    VMTcoin public token;

    function setUp() public {
        token = new VMTcoin();
    }

    function testInitialSupply() public {
        uint256 supply = token.totalSupply();
        assertGt(supply, 0);
    }

    function testTransfer() public {
        address to = address(0xBEEF);
        token.transfer(to, 1000);
        assertEq(token.balanceOf(to), 1000);
    }
}
