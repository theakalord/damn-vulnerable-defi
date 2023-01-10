pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../DamnValuableToken.sol";

/**
 * @notice A simple pool to get flash loans of DVT
 */
contract FlashLoanerPool is ReentrancyGuard {

    using Address for address;

    DamnValuableToken public liquidityToken;

    constructor(address liquidityTokenAddress) {
        liquidityToken = DamnValuableToken(liquidityTokenAddress);
    }

    function flashLoan(uint256 amount) external nonReentrant {
        uint256 balanceBefore = liquidityToken.balanceOf(address(this));
        require(amount <= balanceBefore, "Not enough token balance");

        require(msg.sender.isContract(), "Borrower must be a deployed contract");
        
        liquidityToken.transfer(msg.sender, amount);

        (bool success, ) = msg.sender.call(
            abi.encodeWithSignature(
                "receiveFlashLoan(uint256)",
                amount
            )
        );
        require(success, "External call failed");

        require(liquidityToken.balanceOf(address(this)) >= balanceBefore, "Flash loan not paid back");
    }
}