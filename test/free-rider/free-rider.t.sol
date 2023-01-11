// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/DamnValuableToken.sol";
import "../../src/free-rider/FreeRiderBuyer.sol";
import "../../src/free-rider/FreeRiderNFTMarketplace.sol";
import "../../src/uniswap/IUniswapV2Factory.sol";
import "../../src/uniswap/IUniswapV2Pair.sol";
import "../../src/uniswap/IUniswapV2Router02.sol";
import "../../src/attacker-contracts/FreeRiderAttacker.sol";

contract FreeRiderTest is Test {
    address public weth;
    DamnValuableToken public token;
    DamnValuableNFT public nft;
    FreeRiderBuyer public buyerContract;
    FreeRiderNFTMarketplace public marketplace;
    IUniswapV2Factory public uniswapFactory;
    IUniswapV2Router02 public uniswapRouter;
    IUniswapV2Pair public uniswapPair;

    address public deployer = address(1);
    address public attacker = address(2);
    address public buyer = address(3);

    // The NFT marketplace will have 6 tokens, at 15 ETH each
    uint256 public constant NFT_PRICE = 15 ether;
    uint8 public constant AMOUNT_OF_NFTS = 6;
    uint256 public constant MARKETPLACE_INITIAL_ETH_BALANCE = 90 ether;

    // The buyer will offer 45 ETH as payout for the job
    uint256 public constant BUYER_PAYOUT = 45 ether;

    // Initial reserves for the Uniswap v2 pool
    uint256 public constant UNISWAP_INITIAL_TOKEN_RESERVE = 15000 ether;
    uint256 public constant UNISWAP_INITIAL_WETH_RESERVE = 9000 ether;

    function setUp() public {
        // mainnet fork
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

        startHoax(deployer);
        token = new DamnValuableToken();

        // Deploy Uniswap Factory and Router
        uniswapFactory = IUniswapV2Factory(
            address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f)
        );
        uniswapRouter = IUniswapV2Router02(
            address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)
        );

        // Approve tokens, and then create Uniswap v2 pair against WETH and add liquidity
        // Note that the function takes care of deploying the pair automatically
        token.approve(address(uniswapRouter), UNISWAP_INITIAL_TOKEN_RESERVE);
        uniswapRouter.addLiquidityETH{value: UNISWAP_INITIAL_WETH_RESERVE}(
            address(token),
            UNISWAP_INITIAL_TOKEN_RESERVE,
            0,
            0,
            deployer,
            block.timestamp
        );

        // Get a reference to the created Uniswap pair
        uniswapPair = IUniswapV2Pair(
            uniswapFactory.getPair(address(token), weth)
        );
        assertGt(uniswapPair.balanceOf(deployer), 0);

        // Deploy the marketplace and get the associated ERC721 token
        // The marketplace will automatically mint AMOUNT_OF_NFTS to the deployer (see `FreeRiderNFTMarketplace::constructor`)
        marketplace = new FreeRiderNFTMarketplace{
            value: MARKETPLACE_INITIAL_ETH_BALANCE
        }(AMOUNT_OF_NFTS);

        // Deploy NFT contract
        nft = DamnValuableNFT(marketplace.token());

        // Ensure deployer owns all minted NFTs and approve the marketplace to trade them
        for (uint256 id; id != AMOUNT_OF_NFTS; ++id) {
            assertEq(nft.ownerOf(id), deployer);
        }
        nft.setApprovalForAll(address(marketplace), true);

        // Open offers in the marketplace
        uint256[] memory ids = new uint256[](AMOUNT_OF_NFTS);
        uint256[] memory prices = new uint256[](AMOUNT_OF_NFTS);
        for (uint256 i; i != AMOUNT_OF_NFTS; ++i) {
            ids[i] = i;
            prices[i] = NFT_PRICE;
        }
        marketplace.offerMany(ids, prices);
        assertEq(marketplace.amountOfOffers(), 6);

        vm.stopPrank();

        // Deploy buyer's contract, adding the attacker as the partner
        hoax(buyer);
        buyerContract = new FreeRiderBuyer{value: BUYER_PAYOUT}(
            attacker,
            address(nft)
        );
    }

    function testExploit() public {
        /** YOUR EXPLOIT GOES HERE */
        startHoax(attacker, attacker, 0.5 ether);
        FreeRiderAttacker attackerContract = new FreeRiderAttacker(
            address(uniswapPair),
            address(uniswapRouter),
            payable(address(marketplace)),
            address(buyerContract)
        );
        attackerContract.attack();
        vm.stopPrank();

        /** SUCCESS CONDITION */

        // Attacker must have earned all ETH from the payout
        assertGt(attacker.balance, BUYER_PAYOUT);
        assertEq(address(buyerContract).balance, 0);

        // The buyer extracts all NFTs from its associated contract
        startHoax(buyer);
        for (uint256 tokenId; tokenId != AMOUNT_OF_NFTS; ++tokenId) {
            nft.transferFrom(address(buyerContract), buyer, tokenId);
            assertEq(nft.ownerOf(tokenId), buyer);
        }
        vm.stopPrank();

        // Exchange must have lost NFTs and ETH
        assertEq(marketplace.amountOfOffers(), 0);
        assertLt(address(marketplace).balance, MARKETPLACE_INITIAL_ETH_BALANCE);
    }
}
