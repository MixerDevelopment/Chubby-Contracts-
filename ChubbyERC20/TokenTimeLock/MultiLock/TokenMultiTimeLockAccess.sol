// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AccessLock{
    ERC20 public token;

    constructor(address tokenAddress_){
        token = ERC20(tokenAddress_);
    }

    function approveForLock(address adr, uint amount) external onlyOwner{
        token.approve(adr, amount);
    }
    
}