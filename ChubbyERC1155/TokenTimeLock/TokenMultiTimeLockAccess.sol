// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract AccessLock is Ownable, ERC1155Holder {
    ERC1155 public token;

    constructor(address tokenAddress_) {
        token = ERC1155(tokenAddress_);
    }

    function approveForLock(address adr) external onlyOwner {
        token.setApprovalForAll(adr, true);
    }
}
