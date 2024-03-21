// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {TokensCrowdSale} from "../src/TokensCrowdSale.sol";
import {console} from "forge-std/console.sol";

contract DeployTokensCrowdSale is Script {
   
    uint256 public deployerKey;
    address tokenAddress;
    function run() external returns (TokensCrowdSale) {
        if (block.chainid == 31337) {
            deployerKey = vm.envUint("PRIVATE_KEY_ANVIL");
        }else {
            deployerKey = vm.envUint("PRIVATE_KEY_SEPOLIA");
        }
        vm.startBroadcast(deployerKey);
        uint256  INITIAL_SUPPLY = 1000000 * 10 ** 18;
        uint256 startTime = block.timestamp + 1 days;
        uint256 deadline = startTime + 10 days;
        uint256 cliffDuration = deadline + 30 days;
        uint256 vestingDuration = cliffDuration + 90 days;
        TokensCrowdSale crowdSale = new TokensCrowdSale(
            INITIAL_SUPPLY,
            startTime,
            deadline,
            cliffDuration,
            vestingDuration
            );
        vm.stopBroadcast();
        return crowdSale;
        
    }
}