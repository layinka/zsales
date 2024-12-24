// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("Test", "TST") {
        _mint(msg.sender, 700_000  ether);
        _mint(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 150_000  ether);
        _mint(0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199, 150_000  ether);
    }
}