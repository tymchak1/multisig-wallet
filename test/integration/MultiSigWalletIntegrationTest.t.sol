// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MultiSigWallet} from "../../src/MultiSigWallet.sol";
import {DeployMultiSigWallet} from "../../script/DeployMultiSigWallet.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Reverter} from "../mocks/Reverter.sol";

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
    event Cancel(uint256 indexed txId);

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
        wallet.getTransactionCount() == 1;
    }

    /*//////////////////////////////////////////////////////////////
                              CANCEL TESTS
    //////////////////////////////////////////////////////////////*/

    function testCancelFailIfNotAnOwner() public {
        vm.startPrank(owners[0]);
        wallet.submit(RANDOM_USER, 1 ether, "");
        vm.stopPrank();

        vm.startPrank(RANDOM_USER);
        vm.expectRevert(MultiSigWallet.NotAnOwner.selector);
        wallet.cancel(0);
        vm.stopPrank();
    }

    function testCancelFailIfTxDoesNotExist() public {
        vm.startPrank(owners[0]);
        vm.expectRevert(MultiSigWallet.TransactionDoesNotExist.selector);
        wallet.cancel(999);
        vm.stopPrank();
    }

    function testCancelFailIfAlreadyExecuted() public {
        // Submit and approve
        vm.startPrank(owners[0]);
        wallet.submit(RANDOM_USER, 1 ether, "");
        wallet.approve(0);
        vm.stopPrank();

        // Get enough approvals (2)
        vm.startPrank(owners[1]);
        wallet.approve(0);
        vm.stopPrank();

        // Execute
        vm.startPrank(owners[0]);
        wallet.execute(0);
        vm.stopPrank();

        vm.startPrank(owners[0]);
        vm.expectRevert(MultiSigWallet.AlreadyExecuted.selector);
        wallet.cancel(0);
        vm.stopPrank();
    }

    function testCancelFailIfAlreadyCanceled() public {
        vm.startPrank(owners[0]);
        wallet.submit(RANDOM_USER, 1 ether, "");
        wallet.cancel(0);
        vm.expectRevert(MultiSigWallet.AlreadyCanceled.selector);
        wallet.cancel(0);
        vm.stopPrank();
    }

    function testCancelFailIfHasEnoughApproves() public {
        vm.startPrank(owners[0]);
        wallet.submit(RANDOM_USER, 1 ether, "");
        wallet.approve(0);
        vm.stopPrank();

        vm.startPrank(owners[1]);
        wallet.approve(0);
        vm.stopPrank();

        vm.startPrank(owners[2]);
        vm.expectRevert(MultiSigWallet.AlreadyApproved.selector);
        wallet.cancel(0);
        vm.stopPrank();
    }

    function testCancelSuccessAndEmitsEvent() public {
        vm.startPrank(owners[0]);
        wallet.submit(RANDOM_USER, 1 ether, "");

        vm.expectEmit(true, false, false, false);
        emit Cancel(0);

        wallet.cancel(0);
        vm.stopPrank();

        assertTrue(wallet.getTransactionById(0).canceled);
    }

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

    function testApproveFailIfAlreadyExecuted() public {
        // Submit and approve
        vm.startPrank(owners[0]);
        wallet.submit(RANDOM_USER, 1 ether, "");
        wallet.approve(0);
        vm.stopPrank();

        // Get enough approvals (2)
        vm.startPrank(owners[1]);
        wallet.approve(0);
        vm.stopPrank();

        // Execute
        vm.startPrank(owners[0]);
        wallet.execute(0);
        vm.stopPrank();

        vm.startPrank(owners[2]);
        vm.expectRevert(MultiSigWallet.AlreadyExecuted.selector);
        wallet.approve(0);
        vm.stopPrank();
    }

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

    function testRevokeFailIfAlreadyExecuted() public {
        // Submit and approve
        vm.startPrank(owners[0]);
        wallet.submit(RANDOM_USER, 1 ether, "");
        wallet.approve(0);
        vm.stopPrank();

        // Get enough approvals (2)
        vm.startPrank(owners[1]);
        wallet.approve(0);
        vm.stopPrank();

        // Execute
        vm.startPrank(owners[0]);
        wallet.execute(0);
        vm.stopPrank();

        vm.startPrank(owners[2]);
        vm.expectRevert(MultiSigWallet.AlreadyExecuted.selector);
        wallet.revoke(0);
        vm.stopPrank();
    }

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

    function testRevokeFailIfHasEnoughApproves() public {
        vm.startPrank(owners[0]);
        wallet.submit(RANDOM_USER, 1 ether, "");
        wallet.approve(0);
        vm.stopPrank();

        vm.startPrank(owners[1]);
        wallet.approve(0);
        vm.stopPrank();

        vm.startPrank(owners[1]);
        vm.expectRevert(MultiSigWallet.AlreadyApproved.selector);
        wallet.revoke(0);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                              EXECUTE TESTS
    //////////////////////////////////////////////////////////////*/

    function testExecuteFailIfNotAnOwner() public {
        vm.startPrank(owners[0]);
        wallet.submit(RANDOM_USER, 1 ether, "");
        vm.stopPrank();

        vm.startPrank(RANDOM_USER);
        vm.expectRevert(MultiSigWallet.NotAnOwner.selector);
        wallet.execute(0);
        vm.stopPrank();
    }

    function testExecuteFailIfTxDoesNotExist() public {
        vm.startPrank(owners[0]);
        vm.expectRevert(MultiSigWallet.TransactionDoesNotExist.selector);
        wallet.execute(999);
        vm.stopPrank();
    }

    function testExecuteFailIfAlreadyExecuted() public {
        vm.startPrank(owners[0]);
        wallet.submit(RANDOM_USER, 1 ether, "");
        wallet.approve(0);
        vm.stopPrank();

        vm.startPrank(owners[1]);
        wallet.approve(0);
        vm.stopPrank();

        vm.startPrank(owners[0]);
        wallet.execute(0);
        vm.expectRevert(MultiSigWallet.AlreadyExecuted.selector);
        wallet.execute(0);
        vm.stopPrank();
    }

    function testExecuteFailIfCanceled() public {
        vm.startPrank(owners[0]);
        wallet.submit(RANDOM_USER, 1 ether, "");
        wallet.cancel(0);
        vm.stopPrank();

        vm.startPrank(owners[0]);
        vm.expectRevert(MultiSigWallet.AlreadyCanceled.selector);
        wallet.execute(0);
        vm.stopPrank();
    }

    function testExecuteFailIfNotEnoughApprovals() public {
        vm.startPrank(owners[0]);
        wallet.submit(RANDOM_USER, 1 ether, "");
        vm.expectRevert(MultiSigWallet.NotApproved.selector);
        wallet.execute(0);
        vm.stopPrank();
    }

    function testExecuteFailIfTransactionFails() public {
        address target = address(new Reverter());
        vm.startPrank(owners[0]);
        wallet.submit(target, 0, "");
        wallet.approve(0);
        vm.stopPrank();

        vm.startPrank(owners[1]);
        wallet.approve(0);
        vm.stopPrank();

        vm.startPrank(owners[0]);
        vm.expectRevert(MultiSigWallet.TransactionFailed.selector);
        wallet.execute(0);
        vm.stopPrank();
    }

    function testExecuteSuccess() public {
        uint256 startBalance = RANDOM_USER.balance;

        vm.startPrank(owners[0]);
        wallet.submit(RANDOM_USER, 1 ether, "");
        wallet.approve(0);
        vm.stopPrank();

        vm.startPrank(owners[1]);
        wallet.approve(0);
        vm.stopPrank();

        vm.startPrank(owners[0]);
        wallet.execute(0);
        vm.stopPrank();

        assertEq(RANDOM_USER.balance, startBalance + 1 ether);
        assertTrue(wallet.getTransactionById(0).executed);
    }

    /*//////////////////////////////////////////////////////////////
                              GETTER TESTS
    //////////////////////////////////////////////////////////////*/

    function testGetWalletBalanceReturnsCorrectValue() public {
        uint256 initialBalance = wallet.getWalletBalance();
        assertEq(initialBalance, STARTING_WALLET_BALANCE);

        (bool sent,) = address(wallet).call{value: 3 ether}("");
        require(sent, "ETH transfer failed");

        uint256 newBalance = wallet.getWalletBalance();
        assertEq(newBalance, STARTING_WALLET_BALANCE + 3 ether);
    }

    function testGetTransactionByIdReturnsCorrectData() public {
        vm.startPrank(owners[0]);
        wallet.submit(RANDOM_USER, 1 ether, hex"1234");
        vm.stopPrank();

        MultiSigWallet.Transaction memory txData = wallet.getTransactionById(0);
        assertEq(txData.to, RANDOM_USER);
        assertEq(txData.value, 1 ether);
        assertEq(txData.data, hex"1234");
        assertFalse(txData.executed);
        assertFalse(txData.canceled);
    }

    function testGetOwnersReturnsAllOwners() public view {
        address[] memory returnedOwners = wallet.getOwners();
        assertEq(returnedOwners.length, owners.length);
        for (uint256 i = 0; i < owners.length; i++) {
            assertEq(returnedOwners[i], owners[i]);
        }
    }

    function testAddressIsOwnerTrue() public view {
        assertTrue(wallet.addressIsOwner(owners[0]));
    }

    function testAddressIsOwnerFalse() public view {
        assertFalse(wallet.addressIsOwner(RANDOM_USER));
    }

    function testGetThresholdReturnsCorrectValue() public view {
        assertEq(wallet.getThreshold(), threshold);
    }

    function testGetBalanceReturnsCorrectETHBalance() public {
        // Send ETH to the wallet
        (bool sent,) = address(wallet).call{value: 5 ether}("");
        if (!sent) {
            revert();
        }

        assertEq(wallet.getBalance(address(wallet)), STARTING_WALLET_BALANCE + 5 ether);
    }

    function testGetTransactionsLengthReturnsCorrectValue() public {
        assertEq(wallet.getTransactionCount(), 0);

        vm.startPrank(owners[0]);
        wallet.submit(RANDOM_USER, 1 ether, "");
        wallet.submit(RANDOM_USER, 2 ether, "");
        vm.stopPrank();

        assertEq(wallet.getTransactionCount(), 2);
    }

    function testGetOwnerByIndexReturnsCorrectOwner() public view {
        for (uint256 i = 0; i < owners.length; i++) {
            address ownerFromContract = wallet.getOwnerByIndex(i);
            assertEq(ownerFromContract, owners[i]);
        }
    }

    function testGetOwnerByIndexRevertsIfInvalidIndex() public {
        uint256 invalidIndex = owners.length;
        vm.expectRevert(MultiSigWallet.InvalidAddress.selector);
        wallet.getOwnerByIndex(invalidIndex);
    }
}
