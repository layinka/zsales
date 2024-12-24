// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StandardERC20Cloneable is ERC20{

    uint8 _decimals;
    uint tokenFeePercent = 250;  //2.5% - percent fee of token to take

    constructor(string memory name, string memory symbol,uint256 totalSupply, uint8 decimals,address tokenOwner,address tokenFeeCollector) ERC20(name, symbol){
        uint fee = totalSupply * tokenFeePercent/10000;
        _mint(tokenOwner, totalSupply - fee);
        _mint(tokenFeeCollector, fee);
        _decimals = decimals;
    }

    function decimals() public view virtual override returns(uint8){
        return _decimals;
    }
}