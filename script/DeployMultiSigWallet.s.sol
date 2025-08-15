// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployMultiSigWallet is Script {
    function run() public returns (MultiSigWallet, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        vm.startBroadcast();
        (address[] memory owners, uint256 threshold) = helperConfig.getActiveNetworkConfig();
        MultiSigWallet multiSigWallet = new MultiSigWallet(owners, threshold);
        vm.stopBroadcast();
        return (multiSigWallet, helperConfig);
    }
}
