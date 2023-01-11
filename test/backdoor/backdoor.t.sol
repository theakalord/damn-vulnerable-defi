// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "../../src/DamnValuableToken.sol";
import "../../src/backdoor/WalletRegistry.sol";
import "../../src/attacker-contracts/BackdoorAttacker.sol";

contract BackdoorTest is Test {
    DamnValuableToken public token;
    GnosisSafe public masterCopy;
    GnosisSafeProxyFactory public walletFactory;
    WalletRegistry public walletRegistry;

    address public deployer = address(1);
    address public attacker = address(2);
    address public alice = address(3);
    address public bob = address(4);
    address public charlie = address(5);
    address public david = address(6);
    address[] public users = [alice, bob, charlie, david];

    uint256 public constant AMOUNT_TOKENS_DISTRIBUTED = 40 ether;

    function setUp() public {
        startHoax(deployer);

        // Deploy Gnosis Safe master copy and factory contracts
        masterCopy = new GnosisSafe();
        walletFactory = new GnosisSafeProxyFactory();
        token = new DamnValuableToken();

        // Deploy the registry
        walletRegistry = new WalletRegistry(
            address(masterCopy),
            address(walletFactory),
            address(token),
            users
        );

        // Users are registered as beneficiaries
        for (uint256 i; i < users.length; ++i) {
            assertTrue(walletRegistry.beneficiaries(users[i]));
        }

        // Transfer tokens to be distributed to the registry
        token.transfer(address(walletRegistry), AMOUNT_TOKENS_DISTRIBUTED);

        vm.stopPrank();
    }

    function testExploit() public {
        /** YOUR EXPLOIT GOES HERE */
        startHoax(attacker);
        BackdoorAttacker attackerContract = new BackdoorAttacker();
        attackerContract.attack(
            walletFactory,
            address(masterCopy),
            users,
            address(walletRegistry),
            address(token)
        );
        vm.stopPrank();

        /** SUCCESS CONDITION */
        for (uint256 i; i < users.length; ++i) {
            address wallet = walletRegistry.wallets(users[i]);

            // User must have registered a wallet
            assertFalse(wallet == address(0), "User did not register a wallet");

            // User is no longer registered as a beneficiary
            assertFalse(walletRegistry.beneficiaries(users[i]));
        }

        // Attacker must have taken all tokens
        assertEq(token.balanceOf(attacker), AMOUNT_TOKENS_DISTRIBUTED);
    }
}
