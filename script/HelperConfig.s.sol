// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address[] owners;
        uint256 threshold;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        address[] memory owners = new address[](3);
        owners[0] = 0x7eF78e0ef51A18Ce23269707CA3A256b69F884c1;
        owners[1] = 0xCd926c7cfC17adF27Cf8DE5Ffe1079dEb8EEa908;
        owners[2] = 0x00A9cc0DC6C0c982aD7b818AAA074017b13cac13;

        return NetworkConfig({owners: owners, threshold: 2});
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.owners.length != 0) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        address owner1 = vm.addr(1);
        address owner2 = vm.addr(2);
        address owner3 = vm.addr(3);
        vm.stopBroadcast();

        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        return NetworkConfig({owners: owners, threshold: 2});
    }

    function getActiveNetworkConfig() public view returns (address[] memory, uint256) {
        return (activeNetworkConfig.owners, activeNetworkConfig.threshold);
    }
}
