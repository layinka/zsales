// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract NFTERC1155 is ERC1155 {
    uint256 public constant OG = 0;
    uint256 public constant EARLY_ADOPTERS = 1;
    uint256 public constant TG_APP = 2;

    constructor() ERC1155("https://zsales.xyz/nft/item/{id}.json") {
        _mint(msg.sender, OG, 1000, "");
        _mint(msg.sender, EARLY_ADOPTERS, 10 ** 3, "");
        _mint(msg.sender, TG_APP, 1, "");
    }
}