// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DepositOnWallet_MultiSigWallet is Script {
    error DepositFailed();

    uint256 constant SEND_VALUE = 0.01 ether;

    function depositOnWallet(address mostRecentlyDeployed) public {
        MultiSigWallet multiSigWallet = MultiSigWallet(payable(mostRecentlyDeployed));

        vm.startBroadcast();
        (bool success,) = address(multiSigWallet).call{value: SEND_VALUE}("");
        if (!success) revert DepositFailed();
        vm.stopBroadcast();

        console.log("Funded MultiSigWallet with %s ETH", SEND_VALUE);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MultiSigWallet", block.chainid);
        depositOnWallet(mostRecentlyDeployed);
    }
}

contract Submit_MultiSigWallet is Script {
    function submit_MultiSigWallet(address mostRecentlyDeployed) public {
        MultiSigWallet multiSigWallet = MultiSigWallet(payable(mostRecentlyDeployed));
        vm.startBroadcast();
        multiSigWallet.submit(address(0x1234567890123456789012345678901234567890), 0.01 ether, "0x");
        vm.stopBroadcast();
        console.log("Submited transaction on address", 0x1234567890123456789012345678901234567890);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MultiSigWallet", block.chainid);
        submit_MultiSigWallet(mostRecentlyDeployed);
    }
}

contract ApproveTransaction_MultiSigWallet is Script {
    function approve_MultiSigWallet(address mostRecentlyDeployed, uint256 txId) public {
        vm.startBroadcast();
        MultiSigWallet multiSigWallet = MultiSigWallet(payable(mostRecentlyDeployed));
        uint256 useTxId = txId;
        if (txId == type(uint256).max) {
            useTxId = multiSigWallet.getTransactionCount() - 1;
        }
        multiSigWallet.approve(useTxId);
        vm.stopBroadcast();
        console.log("Approved transaction with txId %s", useTxId);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MultiSigWallet", block.chainid);
        approve_MultiSigWallet(mostRecentlyDeployed, type(uint256).max);
    }
}

contract RevokeTransaction_MultiSigWallet is Script {
    function revoke_MultiSigWallet(address mostRecentlyDeployed, uint256 txId) public {
        vm.startBroadcast();
        MultiSigWallet multiSigWallet = MultiSigWallet(payable(mostRecentlyDeployed));
        uint256 useTxId = txId;
        if (txId == type(uint256).max) {
            useTxId = multiSigWallet.getTransactionCount() - 1;
        }
        multiSigWallet.revoke(useTxId);
        vm.stopBroadcast();
        console.log("Revoked transaction with txId %s", useTxId);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MultiSigWallet", block.chainid);
        revoke_MultiSigWallet(mostRecentlyDeployed, type(uint256).max);
    }
}

contract CancelTransaction_MultiSigWallet is Script {
    function cancel_MultiSigWallet(address mostRecentlyDeployed, uint256 txId) public {
        vm.startBroadcast();
        MultiSigWallet multiSigWallet = MultiSigWallet(payable(mostRecentlyDeployed));
        uint256 useTxId = txId;
        if (txId == type(uint256).max) {
            useTxId = multiSigWallet.getTransactionCount() - 1;
        }
        multiSigWallet.cancel(useTxId);
        vm.stopBroadcast();
        console.log("Canceled transaction with txId %s", useTxId);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MultiSigWallet", block.chainid);
        cancel_MultiSigWallet(mostRecentlyDeployed, type(uint256).max);
    }
}

contract ExecuteTransaction_MultiSigWallet is Script {
    function execute_MultiSigWallet(address mostRecentlyDeployed, uint256 txId) public {
        vm.startBroadcast();
        MultiSigWallet multiSigWallet = MultiSigWallet(payable(mostRecentlyDeployed));
        uint256 useTxId = txId;
        if (txId == type(uint256).max) {
            useTxId = multiSigWallet.getTransactionCount() - 1;
        }
        multiSigWallet.execute(useTxId);
        vm.stopBroadcast();
        console.log("Executed transaction with txId %s", useTxId);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MultiSigWallet", block.chainid);
        execute_MultiSigWallet(mostRecentlyDeployed, type(uint256).max);
    }
}
