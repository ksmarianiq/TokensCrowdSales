// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";
import {console} from "forge-std/console.sol";

contract DeployMyToken is Script {
    uint256 public constant INITIAL_SUPPLY = 100000 ether; // 1 million tokens with 18 decimal places
 
    uint256 public deployerKey;
    address tokenAddress;
    function run() external returns (MyToken) {
        if (block.chainid == 31337) {
            deployerKey = vm.envUint("PRIVATE_KEY_ANVIL");
        }else {
            deployerKey = vm.envUint("PRIVATE_KEY_SEPOLIA");
        }
        vm.startBroadcast(deployerKey);
        MyToken token = new MyToken(100000 ether);
        vm.stopBroadcast();
        return token;
        
    }
}