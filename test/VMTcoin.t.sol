// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VMTcoin.sol";
import "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract VMTcoinTest is Test {
    VMTcoin public vmt;
    address public owner;
    address public daoTreasury;
    address public backup;

    error EnforcedPause();

    function setUp() public {
        owner = address(this);
        // owner = address(0x001);
        daoTreasury = address(0xDA0);
        backup = address(0xBEEF);

        // Deploy logic contract
        VMTcoin logic = new VMTcoin();

        // Encode initializer data
        bytes memory data = abi.encodeWithSignature(
            "initialize(address,address,address)",
            owner,
            daoTreasury,
            backup
        );

        // Deploy proxy
        ERC1967Proxy proxy = new ERC1967Proxy(address(logic), data);
        vmt = VMTcoin(payable(proxy));
    }

    function testInitialMint() public view {
        // Owner should have received 1,000,000 VMT
        assertEq(vmt.totalSupply(), 1_000_000 ether);
        assertEq(vmt.balanceOf(owner), 1_000_000 ether);
    }

    function testTransferWithTaxAndBurn() public {
        address to = address(0xB0B);
        uint256 amount = 1_000 ether;

        vmt.transfer(to, amount);

        // Tax: 0.1%, Burn: 0.01%
        uint256 tax = (amount * 10) / 10_000;
        uint256 burn = (amount * 1) / 10_000;
        uint256 received = amount - tax - burn;

        assertEq(vmt.balanceOf(to), received);
        assertEq(vmt.balanceOf(daoTreasury), tax);
        assertEq(vmt.totalSupply(), 1_000_000 ether - burn);
    }

    function testBlacklistBlocksTransfer() public {
        address victim = address(0xBAD);
        vm.prank(owner);
        vmt.blacklist(victim, true);

        // Send some tokens to blacklisted address for test
        vm.expectRevert("VMTcoin: Account blacklisted");
        vmt.transfer(victim, 1 ether);
    }

    function testPausePreventsTransfer() public {
        vm.prank(owner);
        vmt.pause();

        // vm.expectRevert("Pausable: paused");
        vm.expectRevert(EnforcedPause.selector);
        vmt.transfer(address(0x1234), 100 ether);
    }

    function testMintRespectsMaxSupply() public {
        vm.prank(owner);
        vmt.mint(address(0xA1), 374_000_000 ether); // brings total to 375M

        // Should revert if trying to exceed max supply
        vm.expectRevert("Exceeds MAX_SUPPLY");
        vm.prank(owner);
        vmt.mint(address(0xB2), 1 ether);
    }

    function testDonateBNB() public {
        uint256 amount = 1 ether;
        vm.deal(address(this), amount);

        // Send donation
        vm.expectEmit(true, true, true, true);
        emit VMTcoin.DonationReceived(address(this), amount, "BNB");

        vmt.donateBNB{value: amount}();
        assertEq(daoTreasury.balance, amount);
    }

    function testDonateERC20() public {
        // Setup dummy ERC20 token
        DummyERC20 dummy = new DummyERC20();
        dummy.mint(address(this), 1_000 ether);
        dummy.approve(address(vmt), 500 ether);

        // Expect donation to succeed
        vm.expectEmit(true, true, true, true);
        emit VMTcoin.DonationReceived(address(this), 500 ether, "ERC20");

        vmt.donateToken(address(dummy), 500 ether);
        assertEq(dummy.balanceOf(daoTreasury), 500 ether);
    }
}

contract DummyERC20 is IERC20 {
    string public name = "Dummy";
    string public symbol = "DUM";
    uint8 public decimals = 18;
    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    function transfer(address to, uint256 amount) external override returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function mint(address to, uint256 amount) public {
        balanceOf[to] += amount;
        totalSupply += amount;
    }
}
