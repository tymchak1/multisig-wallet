// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MultiSigWallet} from "../../src/MultiSigWallet.sol";
import {DeployMultiSigWallet} from "../../script/DeployMultiSigWallet.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract MultiSigWalletIntegrationTest is Test {
    MultiSigWallet public wallet;
    DeployMultiSigWallet public deployer;
    HelperConfig public helperConfig;

    address[] public owners;
    uint256 public threshold;

    address public RANDOM_USER = makeAddr("RANDOM_USER");

    uint256 public constant STARTING_USER_BALANCE = 1 ether;
    uint256 public constant STARTING_WALLET_BALANCE = 10 ether;

    event Submit(uint256 indexed txId);
    event Approve(address indexed owner, uint256 indexed txId);
    event Revoke(address indexed owner, uint256 indexed txId);

    function setUp() public {
        deployer = new DeployMultiSigWallet();
        (wallet, helperConfig) = deployer.run();

        (owners, threshold) = helperConfig.getActiveNetworkConfig();

        for (uint256 i = 1; i < owners.length; i++) {
            vm.deal(owners[i], STARTING_USER_BALANCE);
        }
        vm.deal(address(wallet), STARTING_WALLET_BALANCE);
    }

    /*//////////////////////////////////////////////////////////////
                           CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/

    function testConstructorSetsOwnersCorrectly() public view {
        assertEq(wallet.getOwners().length, 3);
        assertTrue(wallet.addressIsOwner(owners[0]));
        assertTrue(wallet.addressIsOwner(owners[1]));
        assertTrue(wallet.addressIsOwner(owners[2]));
    }

    function testConstructorSetsThresholdCorrectly() public view {
        assertEq(wallet.getThreshold(), threshold);
    }

    /*//////////////////////////////////////////////////////////////
                              SUBMIT TESTS
    //////////////////////////////////////////////////////////////*/

    function testSubmitFailIfNotAnOwner() public {
        vm.expectRevert(MultiSigWallet.NotAnOwner.selector);

        vm.startPrank(RANDOM_USER);
        wallet.submit(address(1), 1 ether, "");
        vm.stopPrank();
    }

    function testSubmitSuccessAndEmitsEvent() public {
        address owner = owners[0];

        vm.expectEmit(true, false, false, false);
        emit Submit(0);

        vm.startPrank(owner);
        wallet.submit(RANDOM_USER, 1 ether, "");
        vm.stopPrank();
        wallet.getTransactionsLength() == 1;
    }

    // EMITS EVENT

    /*//////////////////////////////////////////////////////////////
                              APPROVE TESTS
    //////////////////////////////////////////////////////////////*/

    function testApproveFailIfNotAnOwner() public {
        vm.startPrank(owners[0]);
        wallet.submit(RANDOM_USER, 1 ether, "");
        vm.stopPrank();

        vm.startPrank(RANDOM_USER);
        vm.expectRevert(MultiSigWallet.NotAnOwner.selector);
        wallet.approve(0);
        vm.stopPrank();
    }

    function testApproveFailIfTxDoesNotExist() public {
        vm.startPrank(owners[0]);
        vm.expectRevert(MultiSigWallet.TransactionDoesNotExist.selector);
        wallet.approve(999);
        vm.stopPrank();
    }

    function testApproveFailIfAlreadyApproved() public {
        vm.startPrank(owners[0]);
        wallet.submit(RANDOM_USER, 1 ether, "");
        wallet.approve(0);
        vm.expectRevert(MultiSigWallet.AlreadyApproved.selector);
        wallet.approve(0);
        vm.stopPrank();
    }

    // function testApproveFailIfAlreadyExecuted() public {}

    function testApproveFailIfCanceled() public {
        vm.startPrank(owners[0]);
        wallet.submit(RANDOM_USER, 1 ether, "");
        wallet.cancel(0);
        vm.expectRevert(MultiSigWallet.AlreadyCanceled.selector);
        wallet.approve(0);
        vm.stopPrank();
    }

    function testApproveSuccessAndEmitsEvent() public {
        vm.startPrank(owners[0]);
        wallet.submit(RANDOM_USER, 1 ether, "");

        vm.expectEmit(true, true, false, false);
        emit Approve(owners[0], 0);

        wallet.approve(0);
        vm.stopPrank();

        assertTrue(wallet.approved(0, owners[0]));
    }

    /*//////////////////////////////////////////////////////////////
                              REVOKE TESTS
    //////////////////////////////////////////////////////////////*/

    function testRevokeFailIfNotAnOwner() public {
        vm.startPrank(owners[0]);
        wallet.submit(RANDOM_USER, 1 ether, "");
        wallet.approve(0);
        vm.stopPrank();

        vm.startPrank(RANDOM_USER);
        vm.expectRevert(MultiSigWallet.NotAnOwner.selector);
        wallet.revoke(0);
        vm.stopPrank();
    }

    function testRevokeFailIfTxDoesNotExist() public {
        vm.startPrank(owners[0]);
        vm.expectRevert(MultiSigWallet.TransactionDoesNotExist.selector);
        wallet.revoke(999);
        vm.stopPrank();
    }

    function testRevokeFailIfNotApproved() public {
        vm.startPrank(owners[0]);
        wallet.submit(RANDOM_USER, 1 ether, "");

        vm.expectRevert(MultiSigWallet.NotApproved.selector);
        wallet.revoke(0);
        vm.stopPrank();
    }

    /* function testRevokeFailIfAlreadyExecuted() public {
        vm.startPrank(owners[0]);
        wallet.submit(RANDOM_USER, 1 ether, "");
        wallet.approve(0);
        vm.stopPrank();

        vm.startPrank(owners[1]);
        wallet.approve(0);
        vm.stopPrank();

        vm.store(
            address(wallet),
            keccak256(abi.encode(uint256(0), uint256(4))), // slot executed у Transaction[0]
            bytes32(uint256(1))
        );

        // Спроба відкликати після виконання
        vm.startPrank(owners[0]);
        vm.expectRevert(MultiSigWallet.AlreadyExecuted.selector);
        wallet.revoke(0);
        vm.stopPrank();
    } */

    function testRevokeFailIfCanceled() public {
        vm.startPrank(owners[0]);
        wallet.submit(RANDOM_USER, 1 ether, "");
        wallet.approve(0);
        wallet.cancel(0);
        vm.expectRevert(MultiSigWallet.AlreadyCanceled.selector);
        wallet.revoke(0);
        vm.stopPrank();
    }

    function testRevokeSuccessAndEmitsEvent() public {
        vm.startPrank(owners[0]);
        wallet.submit(RANDOM_USER, 1 ether, "");
        wallet.approve(0);

        vm.expectEmit(true, true, false, false);
        emit Revoke(owners[0], 0);

        wallet.revoke(0);
        vm.stopPrank();

        assertFalse(wallet.approved(0, owners[0]));
    }
}
