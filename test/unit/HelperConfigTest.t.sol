// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {HelperConfig} from "../../script/HelperConfig.s.sol";
import "forge-std/Test.sol";

contract HelperConfigTest is Test {
    HelperConfig config;

    function setUp() public {
        config = new HelperConfig();
    }

    /*//////////////////////////////////////////////////////////////
                       CONSTRUCTOR TESTS
    ////////////////////////////////////////////////////////////*/

    function testConstructor_Sepolia() public {
        vm.chainId(11155111);
        HelperConfig localConfig = new HelperConfig(); // локальний для цього тесту

        (address[] memory owners, uint256 threshold) = localConfig.getActiveNetworkConfig();
        assertEq(owners.length, 3);
        assertEq(owners[0], 0x7eF78e0ef51A18Ce23269707CA3A256b69F884c1);
        assertEq(owners[1], 0xCd926c7cfC17adF27Cf8DE5Ffe1079dEb8EEa908);
        assertEq(owners[2], 0x00A9cc0DC6C0c982aD7b818AAA074017b13cac13);
        assertEq(threshold, 2);
    }

    function testConstructor_Anvil() public {
        vm.chainId(1337);
        HelperConfig localConfig = new HelperConfig(); // локальний для цього тесту

        (address[] memory owners, uint256 threshold) = localConfig.getActiveNetworkConfig();
        assertEq(owners.length, 3);
        assertEq(threshold, 2);

        for (uint256 i = 0; i < 3; i++) {
            assert(owners[i] != address(0));
        }
    }

    /*//////////////////////////////////////////////////////////////
                           FUNCTIONS TESTS
    //////////////////////////////////////////////////////////////*/

    function testGetActiveNetworkConfigReturnsValidData() public view {
        (address[] memory owners, uint256 threshold) = config.getActiveNetworkConfig();
        assertGt(owners.length, 0, "Owners array should not be empty");
        assertGt(threshold, 0, "Threshold should be positive");
        assertLe(threshold, owners.length, "Threshold cannot exceed owners count");
    }

    function testGetOrCreateAnvilEthConfigReturnsValidData() public {
        HelperConfig.NetworkConfig memory cfg = config.getOrCreateAnvilEthConfig();
        assertGt(cfg.owners.length, 0, "Owners array should not be empty");
        assertGt(cfg.threshold, 0, "Threshold should be positive");
    }

    function testGetSepoliaEthConfigReturnsValidData() public view {
        HelperConfig.NetworkConfig memory cfg = config.getSepoliaEthConfig();
        assertGt(cfg.owners.length, 0, "Owners array should not be empty");
        assertGt(cfg.threshold, 0, "Threshold should be positive");
    }
}
