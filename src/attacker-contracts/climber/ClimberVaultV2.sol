// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ClimberVaultV2 is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    uint256 public constant WITHDRAWAL_LIMIT = 1 ether;
    uint256 public constant WAITING_PERIOD = 15 days;

    uint256 private _lastWithdrawalTimestamp;
    address private _sweeper;

    // Allows trusted sweeper account to retrieve any tokens
    function sweepFunds(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(msg.sender, token.balanceOf(address(this))), "Transfer failed");
    }

    // By marking this internal function with `onlyOwner`, we only allow the owner account to authorize an upgrade
    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}
}
