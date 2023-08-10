// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../BaseTest.sol";

contract IntegrationOnlyOwnerTest is BaseTest {
    using MarketLib for Market;
    using FixedPointMathLib for uint256;

    function testSetOwnerWhenNotOwner(address addressFuzz) public {
        vm.assume(addressFuzz != OWNER);

        vm.prank(addressFuzz);
        vm.expectRevert(bytes(ErrorsLib.NOT_OWNER));
        blue.setOwner(addressFuzz);
    }

    function testSetOwner(address newOwner) public {
        vm.assume(newOwner != OWNER);

        vm.prank(OWNER);
        vm.expectEmit(true, true, true, true, address(blue));
        emit EventsLib.SetOwner(newOwner);
        blue.setOwner(newOwner);

        assertEq(blue.owner(), newOwner, "owner is not set");
    }

    function testEnableIrmWhenNotOwner(address addressFuzz, address irmFuzz) public {
        vm.assume(addressFuzz != OWNER);
        vm.assume(irmFuzz != address(irm));

        vm.prank(addressFuzz);
        vm.expectRevert(bytes(ErrorsLib.NOT_OWNER));
        blue.enableIrm(irmFuzz);
    }

    function testEnableIrm(address irmFuzz) public {
        vm.assume(irmFuzz != address(irm));

        vm.prank(OWNER);
        vm.expectEmit(true, true, true, true, address(blue));
        emit EventsLib.EnableIrm(irmFuzz);
        blue.enableIrm(irmFuzz);

        assertTrue(blue.isIrmEnabled(irmFuzz), "IRM is not enabled");
    }

    function testEnableLltvWhenNotOwner(address addressFuzz, uint256 lltvFuzz) public {
        vm.assume(addressFuzz != OWNER);
        vm.assume(lltvFuzz != LLTV);

        vm.prank(addressFuzz);
        vm.expectRevert(bytes(ErrorsLib.NOT_OWNER));
        blue.enableLltv(lltvFuzz);
    }

    function testEnableTooHighLltv(uint256 lltvFuzz) public {
        lltvFuzz = _boundInvalidLltv(lltvFuzz);

        vm.prank(OWNER);
        vm.expectRevert(bytes(ErrorsLib.LLTV_TOO_HIGH));
        blue.enableLltv(lltvFuzz);
    }

    function testEnableLltv(uint256 lltvFuzz) public {
        lltvFuzz = _boundValidLltv(lltvFuzz);

        vm.prank(OWNER);
        vm.expectEmit(true, true, true, true, address(blue));
        emit EventsLib.EnableLltv(lltvFuzz);
        blue.enableLltv(lltvFuzz);

        assertTrue(blue.isLltvEnabled(lltvFuzz), "LLTV is not enabled");
    }

    function testSetFeeWhenNotOwner(address addressFuzz, uint256 feeFuzz) public {
        vm.assume(addressFuzz != OWNER);

        vm.prank(addressFuzz);
        vm.expectRevert(bytes(ErrorsLib.NOT_OWNER));
        blue.setFee(market, feeFuzz);
    }

    function testSetFeeWhenMarketNotCreated(Market memory marketFuzz, uint256 feeFuzz) public {
        vm.assume(neq(marketFuzz, market));

        vm.prank(OWNER);
        vm.expectRevert(bytes(ErrorsLib.MARKET_NOT_CREATED));
        blue.setFee(marketFuzz, feeFuzz);
    }

    function testSetTooHighFee(uint256 feeFuzz) public {
        feeFuzz = bound(feeFuzz, MAX_FEE + 1, type(uint256).max);

        vm.prank(OWNER);
        vm.expectRevert(bytes(ErrorsLib.MAX_FEE_EXCEEDED));
        blue.setFee(market, feeFuzz);
    }

    function testSetFee(uint256 feeFuzz) public {
        feeFuzz = bound(feeFuzz, 0, MAX_FEE);

        vm.prank(OWNER);
        vm.expectEmit(true, true, true, true, address(blue));
        emit EventsLib.SetFee(id, feeFuzz);
        blue.setFee(market, feeFuzz);

        assertEq(blue.fee(id), feeFuzz);
    }

    function testSetFeeRecipientWhenNotOwner(address addressFuzz) public {
        vm.assume(addressFuzz != OWNER);

        vm.prank(addressFuzz);
        vm.expectRevert(bytes(ErrorsLib.NOT_OWNER));
        blue.setFeeRecipient(addressFuzz);
    }

    function testSetFeeRecipient(address newFeeRecipient) public {
        vm.assume(newFeeRecipient != OWNER);

        vm.prank(OWNER);
        vm.expectEmit(true, true, true, true, address(blue));
        emit EventsLib.SetFeeRecipient(newFeeRecipient);
        blue.setFeeRecipient(newFeeRecipient);

        assertEq(blue.feeRecipient(), newFeeRecipient);
    }
}
