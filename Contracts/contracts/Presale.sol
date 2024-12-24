// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract Presale {
    using Math for uint256;

    address public admin;
    address public tokenAddress;
    address public baseCurrencyAddress;
    uint256 public rate;

    event TokensPurchased(address buyer, uint256 amountPaid, uint256 amountBought);

    constructor(
        address _tokenAddress,
        address _baseCurrencyAddress,
        uint256 _rate
    ) {
        admin = msg.sender;
        tokenAddress = _tokenAddress;
        baseCurrencyAddress = _baseCurrencyAddress;
        rate = _rate;
    }

    function buyTokens(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        IERC20 baseCurrency = IERC20(baseCurrencyAddress);
        if(address(0)!=baseCurrencyAddress){
            

            uint256 allowance = baseCurrency.allowance(msg.sender, address(this));
            require(allowance >= amount, "Allowance not sufficient");
        }
        
        uint256 tokensToBuy = amount*rate/(10**getDecimals(baseCurrencyAddress));
        require(tokensToBuy > 0, "Insufficient tokens available for purchase");

        baseCurrency.transferFrom(msg.sender, address(this), amount);
        IERC20(tokenAddress).transfer(msg.sender, tokensToBuy);

        emit TokensPurchased(msg.sender, amount, tokensToBuy);
    }

    function calcRates(uint256 amount) public view returns  (uint,uint,uint) {
        require(amount > 0, "Amount must be greater than 0");

        // IERC20 baseCurrency = IERC20(baseCurrencyAddress);
        // if(address(0)!=baseCurrencyAddress){
            

        //     uint256 allowance = baseCurrency.allowance(msg.sender, address(this));
        //     require(allowance >= amount, "Allowance not sufficient");
        // }
        
        uint256 tokensToBuy = amount*rate/(10**getDecimals(baseCurrencyAddress));
        require(tokensToBuy > 0, "Insufficient tokens available for purchase");

        // baseCurrency.transferFrom(msg.sender, address(this), amount);
        // IERC20(tokenAddress).transfer(msg.sender, tokensToBuy);

        return  (
            tokensToBuy, 
            amount*rate/(10**getDecimals(tokenAddress)),
            amount*rate/(10** (getDecimals(baseCurrencyAddress) - getDecimals(tokenAddress))) 
        ) ;
    }

    function multiply(uint a,uint aDecimal, uint b, uint bDecimal) public pure returns(uint){
        a= normalizeTokenAmount(a, aDecimal);
        b= normalizeTokenAmount(b, bDecimal);

        return a*b;
    }

    /**
     * Normalization function that adjusts token amounts to a common decimal base (18 decimals in this case). 
     * This function either scales up or scales down the token amount based on the number of decimals the token uses,
     * ensuring the final amount will be always displayed with 18 decimals. 
     * Of course this can result in a minor truncation if tokens >18 decimals are being used, this must be considered
     */
    function normalizeTokenAmount(uint tokenAmount, uint tokenDecimals) public pure returns (uint) {
        uint standardDecimal = 18;
        if(tokenDecimals>standardDecimal){
            return tokenAmount / (10 ** (tokenDecimals-standardDecimal));
        }
        else if(tokenDecimals< standardDecimal){
            return tokenAmount * (10 ** (standardDecimal - tokenDecimals));
        }
        else{
            return tokenAmount;
        }
    }



    function getDecimals(address _tokenAddress) private view returns (uint256) {
        if (_tokenAddress == address(0)) {
            return 18; // Assuming native currency has 18 decimals
        } else {
            return IERC20Metadata(_tokenAddress).decimals();
        }
    }
}
