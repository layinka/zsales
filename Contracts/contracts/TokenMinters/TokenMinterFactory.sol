// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.26;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "hardhat/console.sol";

import './SimpleERC20.sol';
import './StandardERC20.sol';
import './BurnMintable.sol';

import '../Interfaces/Turnstile.sol';

error InSufficientFee();

contract TokenMinterFactory is Context,Ownable  {
    using SafeERC20 for IERC20;

    enum TokenTypes{ 
        SIMPLE,
        STANDARD,
        BURNMINTABLE
    }

    
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    
    // Declare a set state variable
    EnumerableMap.UintToAddressMap private _tokens;

    uint private _counter;

    address public turnstileAddress = address(0);
    Turnstile private turnstile;
        
    
    mapping(TokenTypes => uint) public nativeFees; //TokenType -> fee 
    mapping(TokenTypes => uint) public tokenFees; //TokenType -> fee 

    address private tokenFeeCollector ;

    mapping(address => uint256[]) private ownersToken; //owneraddress -> tokensIndex    

    address[] public _tokensList; //tokenAddress

    event TokenCreated(address creator, uint256 indexed index, address createdTokenAddress);

    mapping(TokenTypes => uint) private tokenTypeCount;

    constructor(uint[3] memory _nativeFees, uint[3] memory _tokenFees) Ownable(msg.sender)  {      
       tokenFeeCollector= address(this);

       nativeFees[TokenTypes.SIMPLE]=_nativeFees[0];// 0.001 ether;
       nativeFees[TokenTypes.STANDARD]=_nativeFees[1];//0.0015 ether;
       nativeFees[TokenTypes.BURNMINTABLE]=_nativeFees[2];//0.003 ether;

       tokenFees[TokenTypes.SIMPLE]=_tokenFees[0];// 0.001 ether;
       tokenFees[TokenTypes.STANDARD]=_tokenFees[1];//0.0015 ether;
       tokenFees[TokenTypes.BURNMINTABLE]=_tokenFees[2];//0.003 ether;
    }

    function setTokenFeeCollector(address newAddress) public onlyOwner{
        tokenFeeCollector=newAddress;
    }

    function setNativeFee(TokenTypes tokenType, uint256 newPrice) public onlyOwner{
        
        nativeFees[tokenType]=newPrice;
    }

    function setTokenFee(TokenTypes tokenType, uint256 newPrice) public onlyOwner{
        
        tokenFees[tokenType]=newPrice;
    }

    function updateTurnstileAddress(address newAddress) public onlyOwner{
        
        turnstileAddress=newAddress;
        turnstile = Turnstile(turnstileAddress);
        //Registers the smart contract with Turnstile
        //Mints the CSR NFT to the contract creator
        turnstile.register(tx.origin);

    }


    
    function createNewToken(TokenTypes tokenType,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint totalSupply
    ) public payable  {

        require(msg.value >= nativeFees[tokenType], InSufficientFee() );
            
        _counter++; 
        uint index = _counter;

        address sender = msg.sender;

        tokenTypeCount[tokenType]++;

        address newTokenAddress;

        if(tokenType == TokenTypes.SIMPLE){
            SimpleERC20 s= new SimpleERC20(name, symbol, totalSupply, decimals, sender, tokenFeeCollector, tokenFees[tokenType]);
            newTokenAddress = address(s);
        }else if(tokenType == TokenTypes.STANDARD){
            StandardERC20 s= new StandardERC20(name, symbol, totalSupply, decimals, sender, tokenFeeCollector, tokenFees[tokenType]);
            newTokenAddress = address(s);
        }else if(tokenType == TokenTypes.BURNMINTABLE){
            BurnMintable s= new BurnMintable(name, symbol, totalSupply, decimals, sender, tokenFeeCollector, tokenFees[tokenType]);
            newTokenAddress = address(s);
        }

        _tokens.set(index, newTokenAddress);
        ownersToken[sender].push( index);
        _tokensList.push(newTokenAddress);
        emit TokenCreated(sender,index, newTokenAddress);

    
    }


    function getTokenTypeCount(TokenTypes tokenType) public view returns (uint256 count){
        
        return tokenTypeCount[tokenType];
    }

    //offset 
    function allOwnersTokens(uint256 limit, uint256 offset) public view returns (uint256[] memory) {
        uint256[] memory list = new uint256[](offset) ;
        for (uint256 i=limit; i < limit + offset ; i++) {
            list[i-limit] = ownersToken[msg.sender][i]; 
        }
        return list;
    }

    
    function tokensCount() public view returns (uint256) {
        return _counter;
    }

    function withdrawTokens(address tokenAddress) public onlyOwner  
    {
        IERC20 _token = IERC20(tokenAddress);
        uint amount = _token.balanceOf(address(this));
        require(amount > 0, "TokenMinterFactory: No Tokens to claim");
        _token.safeTransfer( _msgSender(), amount);
    }

    

      

    function tokenAt(uint256 index) public view returns (uint256 key, address value) {
        return _tokens.at(index);
    }

    function tryGetTokenByKey(uint256 key) public view returns (bool, address) {
        return _tokens.tryGet(key);
    }

    

    // //abi.encodePacked(x)
    // function concatenate(string memory s1, string memory s2) public pure returns (string memory) {
    //     return string(abi.encodePacked(s1, s2));
    // }

    // function concatenate(string memory s1, address s2) public pure returns (string memory) {
    //     return string(abi.encodePacked(s1, s2));
    // }

}