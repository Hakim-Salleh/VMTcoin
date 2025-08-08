// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title VMTcoin
/// @author Jakcy LoveCode
/// @notice This is an VMTcoin that will be used as utility token on BNB chain.
contract VMTcoin is 
    Initializable,
    ERC20PermitUpgradeable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    uint256 public constant MAX_SUPPLY = 375_000_000 * 1e18;
    uint256 public constant TRANSFER_TAX_RATE = 10; // 0.1%;
    uint256 public constant BURN_RATE = 1; // 0.01%;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");
    bytes32 public constant ENTITY_ROLE = keccak256("ENTITY_ROLE");
    bytes32 public constant BLACKLIST_ROLE = keccak256("BLACKLIST_ROLE");

    address public daoTreasury;
    address public backupAdmin;
    mapping (address => bool) blacklisted;
    mapping (string => address) entityWallets;

    event TreasuryUpdated(address indexed newTreasury);
    event DonationReceived(address indexed from, uint256 amount, string donationType);
    event EntityWalletsSet(string indexed name, address indexed wallet);

    event OwnershipRecovered(address previousAdmin, address newAdmin);

    modifier notBlacklisted(address account) {
        require(blacklisted[account] == false, "VMTcoin: Account blacklisted");
        _;
    }

    function initialize(address initialOwner, address _daoTreasury, address backup) public initializer {
        __ERC20_init("Victoria Maruhina Token", "VMTcoin");
        __ERC20Permit_init("Victoria Maruhina Token");
        __Pausable_init();
        __AccessControl_init();
        __ERC20Burnable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _grantRole(MINTER_ROLE, initialOwner);
        _grantRole(PAUSER_ROLE, initialOwner);
        _grantRole(BLACKLIST_ROLE, initialOwner);
        _grantRole(TREASURY_ROLE, initialOwner);
        _grantRole(ENTITY_ROLE, initialOwner);

        daoTreasury = _daoTreasury;
        backupAdmin = backup;
        _mint(initialOwner, 1_000_000 ether);
        // _mint(address(this), 1_000_000 ether);
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        require(totalSupply() + amount <= MAX_SUPPLY , "Exceeds MAX_SUPPLY");
        _mint(to, amount);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setBackupAdmin(address _backup) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_backup != address(0), "Invalid");
        backupAdmin = _backup;
    }

    function recoverOwnership(address newAdmin) external {
        require(msg.sender == backupAdmin, "Not backup admin");
        _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        emit OwnershipRecovered(msg.sender, newAdmin);
    }

    function blacklist(address user, bool status) external onlyRole(BLACKLIST_ROLE) {
        blacklisted[user] = status;
    }

    function setDaoTreasury(address newTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newTreasury != address(0), "Zero address");
        daoTreasury = newTreasury;
        _grantRole(TREASURY_ROLE, newTreasury);
    }

    function registerEntityWallet(string memory name, address wallet) external onlyRole(ENTITY_ROLE) {
        require(wallet != address(0), "Zero address");
        entityWallets[name] = wallet;
        emit EntityWalletsSet(name, wallet);
    }

    function donateBNB() external payable nonReentrant {
        require(msg.value > 0, "Zero BNB");
        payable(daoTreasury).transfer(msg.value);
        emit DonationReceived(msg.sender, msg.value, "BNB");
    }

    function donateToken(address token, uint256 amount) external nonReentrant {
        require(amount > 0, "Zero token amount");
        require(token != address(0), "Zero token address");
        bool success = IERC20(token).transferFrom(msg.sender, daoTreasury, amount);
        require(success, "Token transfer failed");
        emit DonationReceived(msg.sender, amount, "ERC20");
    }

    // function transfer(address from, address to, uint256 amount) internal whenNotPaused notBlacklisted(from) notBlacklisted(to) {
    //     uint256 tax = (amount * TRANSFER_TAX_RATE) / 10000; // 0.1%
    //     uint256 burnAmount = (amount * BURN_RATE) / 10000; // 0.01%
    //     uint256 sendAmount = amount - tax - burnAmount;

    //     super._transfer(from, daoTreasury, tax);
    //     _burn(from, burnAmount);
    //     super._transfer(from, to, sendAmount);
    // }

    function transfer(address to, uint256 amount) public override whenNotPaused notBlacklisted(_msgSender()) notBlacklisted(to) returns (bool) {
        uint256 tax = (amount * TRANSFER_TAX_RATE) / 10000; // 0.1%
        uint256 burnAmount = (amount * BURN_RATE) / 10000; // 0.01%
        uint256 sendAmount = amount - tax - burnAmount;

        // super._transfer(from, daoTreasury, tax);
        // _burn(from, burnAmount);
        // super._transfer(from, to, sendAmount);
        super._transfer(_msgSender(), daoTreasury, tax);
        _burn(_msgSender(), burnAmount);
        super._transfer(_msgSender(), to, sendAmount);

        return true;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    receive() external payable {
        payable(daoTreasury).transfer(msg.value);
    }

    fallback() external payable {
        payable(daoTreasury).transfer(msg.value);
    }
}