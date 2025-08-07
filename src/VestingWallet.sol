// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title VestingWallet
 * @dev A simple linear token vesting contract
 */
contract VestingWallet is Ownable {
    IERC20 public immutable token;
    address public beneficiary;

    uint256 public immutable start;
    uint256 public immutable duration;
    uint256 public released;

    constructor(address _token, address _beneficiary, uint256 _start, uint256 _duration) Ownable(msg.sender) {
        require(_beneficiary != address(0), "Invalid beneficiary");
        require(_start >= block.timestamp, "Start must be in the future");
        require(_duration > 0, "Duration must be > 0");

        token = IERC20(_token);
        beneficiary = _beneficiary;
        start = _start;
        duration = _duration;
    }

    function release() public {
        uint256 releasable = vestedAmount() - released;
        require(releasable > 0, "Nothing to release");

        released += releasable;
        token.transfer(beneficiary, releasable);
    }

    function vestedAmount() public view returns (uint256) {
        uint256 totalBalance = token.balanceOf(address(this)) + released;

        if (block.timestamp < start) {
            return 0;
        } else if (block.timestamp >= start + duration) {
            return totalBalance;
        } else {
            return (totalBalance * (block.timestamp - start)) / duration;
        }
    }

    function updateBeneficiary(address newBeneficiary) external onlyOwner {
        require(newBeneficiary != address(0), "Zero address");
        beneficiary = newBeneficiary;
    }
}
