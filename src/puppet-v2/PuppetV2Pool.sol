// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../uniswap/UniswapV2Library.sol";

/**
 * @title PuppetV2Pool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract PuppetV2Pool {
    address private _uniswapPair;
    address private _uniswapFactory;
    IERC20 private _token;
    IERC20 private _weth;

    mapping(address => uint256) public deposits;

    event Borrowed(
        address indexed borrower,
        uint256 depositRequired,
        uint256 borrowAmount,
        uint256 timestamp
    );

    constructor(
        address wethAddress,
        address tokenAddress,
        address uniswapPairAddress,
        address uniswapFactoryAddress
    ) {
        _weth = IERC20(wethAddress);
        _token = IERC20(tokenAddress);
        _uniswapPair = uniswapPairAddress;
        _uniswapFactory = uniswapFactoryAddress;
    }

    /**
     * @notice Allows borrowing `borrowAmount` of tokens by first depositing three times their value in WETH
     *         Sender must have approved enough WETH in advance.
     *         Calculations assume that WETH and borrowed token have same amount of decimals.
     */
    function borrow(uint256 borrowAmount) external {
        require(
            _token.balanceOf(address(this)) >= borrowAmount,
            "Not enough token balance"
        );

        // Calculate how much WETH the user must deposit
        uint256 depositOfWETHRequired = calculateDepositOfWETHRequired(
            borrowAmount
        );

        // Take the WETH
        _weth.transferFrom(msg.sender, address(this), depositOfWETHRequired);

        // internal accounting
        deposits[msg.sender] += depositOfWETHRequired;

        require(_token.transfer(msg.sender, borrowAmount));

        emit Borrowed(
            msg.sender,
            depositOfWETHRequired,
            borrowAmount,
            block.timestamp
        );
    }

    function calculateDepositOfWETHRequired(
        uint256 tokenAmount
    ) public view returns (uint256) {
        return (_getOracleQuote(tokenAmount) * 3) / (10 ** 18);
    }

    // Fetch the price from Uniswap v2 using the official libraries
    function _getOracleQuote(uint256 amount) private view returns (uint256) {
        (uint256 reservesWETH, uint256 reservesToken) = UniswapV2Library
            .getReserves(_uniswapFactory, address(_weth), address(_token));
        return
            UniswapV2Library.quote(
                amount * (10 ** 18),
                reservesToken,
                reservesWETH
            );
    }
}
