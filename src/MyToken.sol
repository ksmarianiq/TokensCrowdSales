// SPDX-License-Identifier : MIT


pragma solidity ^0.8.19;
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";


contract MyToken is ERC20{
    constructor(uint256 totalSupply) ERC20 ("Tokenus","TKN"){
      _mint(msg.sender, totalSupply* 10 ** decimals());
    }
}



  

