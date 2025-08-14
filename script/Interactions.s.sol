// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

// for Sepolia

contract DepositOnWallet_MultiSigWallet is Script {
    error DepositFailed();

    uint256 SEND_VALUE = 0.01 ether;

    function depositOnWallet(address mostRecentlyDeployed) public {
        vm.startBroadcast();

        MultiSigWallet multiSigWallet = MultiSigWallet(payable(mostRecentlyDeployed));

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

contract SubmitTransaction_MultiSigWallet is Script {
    function submit_MultiSigWallet(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        MultiSigWallet multiSigWallet = MultiSigWallet(payable(mostRecentlyDeployed));
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
    function approve_MultiSigWallet(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        MultiSigWallet multiSigWallet = MultiSigWallet(payable(mostRecentlyDeployed));
        multiSigWallet.approve(0);
        vm.stopBroadcast();
        console.log("Approved transaction");
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MultiSigWallet", block.chainid);
        approve_MultiSigWallet(mostRecentlyDeployed);
    }
}

contract RevokeTransaction_MultiSigWallet is Script {
    function revoke_MultiSigWallet(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        MultiSigWallet multiSigWallet = MultiSigWallet(payable(mostRecentlyDeployed));
        multiSigWallet.revoke(0);
        vm.stopBroadcast();
        console.log("Revoked transaction");
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MultiSigWallet", block.chainid);
        revoke_MultiSigWallet(mostRecentlyDeployed);
    }
}

contract CancelTransaction_MultiSigWallet is Script {
    function cancel_MultiSigWallet(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        MultiSigWallet multiSigWallet = MultiSigWallet(payable(mostRecentlyDeployed));
        multiSigWallet.cancel(0);
        vm.stopBroadcast();
        console.log("Canceled transaction");
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MultiSigWallet", block.chainid);
        cancel_MultiSigWallet(mostRecentlyDeployed);
    }
}

contract ExecuteTransaction_MultiSigWallet is Script {
    function execute_MultiSigWallet(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        MultiSigWallet multiSigWallet = MultiSigWallet(payable(mostRecentlyDeployed));
        multiSigWallet.execute(0);
        vm.stopBroadcast();
        console.log("Executed transaction");
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MultiSigWallet", block.chainid);
        execute_MultiSigWallet(mostRecentlyDeployed);
    }
}
