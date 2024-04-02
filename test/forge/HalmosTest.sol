// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../../lib/forge-std/src/Test.sol";
import {SymTest} from "../../lib/halmos-cheatcodes/src/SymTest.sol";

import {IMorpho} from "../../src/interfaces/IMorpho.sol";
import {IrmMock} from "../../src/mocks/IrmMock.sol";
import {ERC20Mock} from "../../src/mocks/ERC20Mock.sol";
import {OracleMock} from "../../src/mocks/OracleMock.sol";

import "../../src/Morpho.sol";
import "../../src/libraries/ConstantsLib.sol";
import {MorphoLib} from "../../src/libraries/periphery/MorphoLib.sol";

/// @custom:halmos --solver-timeout-assertion 0
contract HalmosTest is SymTest, Test {
    using MorphoLib for IMorpho;
    using MarketParamsLib for MarketParams;

    uint256 internal constant BLOCK_TIME = 1;
    uint256 internal constant DEFAULT_TEST_LLTV = 0.8 ether;

    address internal OWNER;
    address internal FEE_RECIPIENT;

    IMorpho internal morpho;
    ERC20Mock internal loanToken;
    ERC20Mock internal collateralToken;
    OracleMock internal oracle;
    IrmMock internal irm;

    MarketParams internal marketParams;
    Id internal id;

    function setUp() public virtual {
        OWNER = address(0x10);
        FEE_RECIPIENT = address(0x11);

        morpho = IMorpho(address(new Morpho(OWNER)));

        loanToken = new ERC20Mock();
        collateralToken = new ERC20Mock();
        oracle = new OracleMock();
        oracle.setPrice(ORACLE_PRICE_SCALE);
        irm = new IrmMock();

        vm.startPrank(OWNER);
        morpho.enableIrm(address(0));
        morpho.enableIrm(address(irm));
        morpho.enableLltv(0);
        morpho.setFeeRecipient(FEE_RECIPIENT);
        vm.stopPrank();

        _setLltv(DEFAULT_TEST_LLTV);
    }

    function _setLltv(uint256 lltv) internal {
        marketParams = MarketParams(address(loanToken), address(collateralToken), address(oracle), address(irm), lltv);
        id = marketParams.id();

        vm.startPrank(OWNER);
        if (!morpho.isLltvEnabled(lltv)) morpho.enableLltv(lltv);
        if (morpho.lastUpdate(id) == 0) morpho.createMarket(marketParams);
        vm.stopPrank();

        _forward(1);
    }

    /// @dev Rolls & warps the given number of blocks forward the blockchain.
    function _forward(uint256 blocks) internal {
        vm.roll(block.number + blocks);
        vm.warp(block.timestamp + blocks * BLOCK_TIME);
    }

    function check_fee(bytes4 selector, address caller) public {
        bytes memory args = svm.createBytes(1024, "data");

        vm.prank(caller);
        (bool success,) = address(morpho).call(abi.encodePacked(selector, args));
        vm.assume(success);

        assert(morpho.fee(id) < MAX_FEE);
    }
}
