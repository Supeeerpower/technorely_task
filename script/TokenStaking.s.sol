// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {TokenStaking} from "../src/TokenStaking.sol";

contract TokenStakingScript is Script {
    TokenStaking public tokenStaking;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        tokenStaking = new TokenStaking();

        vm.stopBroadcast();
    }
}
