// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DecimalToken is ERC20 {

    uint8 private _decimals;
    constructor(uint8 decimals) ERC20("Test", "TST") {
        _decimals=decimals;
        _mint(msg.sender, 1000000  ether);
        _mint(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 1000000  ether);
        _mint(0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199, 1000000  ether);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}