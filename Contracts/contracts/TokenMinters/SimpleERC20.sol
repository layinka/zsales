// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleERC20 is ERC20{

    uint8 _decimals;
    uint tokenFeePercent = 50;  //0.5% - percent fee of token to take

    constructor(string memory name, string memory symbol, uint256 totalSupply, uint8 decimals,address tokenOwner,
    address tokenFeeCollector, uint _tokenFeePercent) ERC20(name, symbol) {
            
        tokenFeePercent=_tokenFeePercent;
        uint fee = totalSupply * tokenFeePercent/10000;
        _mint(tokenOwner, totalSupply - fee);
        _mint(tokenFeeCollector, fee);
        _decimals = decimals;
    }

    function decimals() public view virtual override returns(uint8){
        return _decimals;
    }

}