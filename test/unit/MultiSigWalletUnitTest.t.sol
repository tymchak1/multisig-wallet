// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MultiSigWallet} from "../../src/MultiSigWallet.sol";

contract MultiSigWalletUnitTest is Test {
    MultiSigWallet public wallet;
    address[] public owners;
    uint256 public constant THRESHOLD = 2;
    uint256 public constant STARTING_USER_BALANCE = 1 ether;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    function setUp() public {
        owners.push(alice);
        owners.push(bob);
        owners.push(charlie);

        wallet = new MultiSigWallet(owners, THRESHOLD);
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
        vm.deal(charlie, 1 ether);
    }

    /*//////////////////////////////////////////////////////////////
                           CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/

    function testConstructorSetsOwnersCorrectly() public view {
        assertEq(wallet.getOwners().length, 3);
        assertTrue(wallet.addressIsOwner(alice));
        assertTrue(wallet.addressIsOwner(bob));
        assertTrue(wallet.addressIsOwner(charlie));
    }

    function testConstructorSetsThresholdCorrectly() public view {
        assertEq(wallet.getThreshold(), THRESHOLD);
    }

    function testConstructorRevertsWithNoOwners() public {
        address[] memory noOwners;

        vm.expectRevert(MultiSigWallet.InvalidAddress.selector);
        new MultiSigWallet(noOwners, 1);
    }

    function testConstructorRevertsWithZeroAddress() public {
        address[] memory invalidOwners = new address[](2);
        invalidOwners[0] = alice;
        invalidOwners[1] = address(0);

        vm.expectRevert(MultiSigWallet.InvalidAddress.selector);
        new MultiSigWallet(invalidOwners, 1);
    }

    function testConstructorRevertsWithDuplicateOwners() public {
        address[] memory duplicateOwners = new address[](2);
        duplicateOwners[0] = alice;
        duplicateOwners[1] = alice;

        vm.expectRevert(MultiSigWallet.IsAlreadyOwner.selector);
        new MultiSigWallet(duplicateOwners, 1);
    }

    function testConstructorRevertsWithInvalidThreshold() public {
        vm.expectRevert(MultiSigWallet.InvalidThreshold.selector);
        new MultiSigWallet(owners, 0);

        vm.expectRevert(MultiSigWallet.InvalidThreshold.selector);
        new MultiSigWallet(owners, 4);
    }
}
