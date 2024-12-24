// // SPDX-License-Identifier: UNLICENSED

// pragma solidity ^0.8.13;

// import "@openzeppelin/contracts/utils/Context.sol";
// import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

// // import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
// import "hardhat/console.sol";

// import './Cloneable/SimpleERC20.sol';
// import './Cloneable/StandardERC20.sol';
// import './Cloneable/BurnMintable.sol';


// contract TokenMinterFactoryCloneable is Context,Ownable  {
//     using SafeERC20 for IERC20;

//     enum TokenTypes{ 
//         SIMPLE,
//         STANDARD,
//         BURNMINTABLE
//     }

    
//     using EnumerableMap for EnumerableMap.UintToAddressMap;
    
//     // Declare a set state variable
//     EnumerableMap.UintToAddressMap private _tokens;

//     uint private _counter;

    
    
//     mapping(TokenTypes => uint) private nativeFees; //TokenType -> fee 

//     address private tokenFeeCollector ;

//     mapping(address => uint256[]) private ownersToken; //owneraddress -> tokensIndex    

//     address[] public _tokensList; //tokenAddress

//     event TokenCreated(address creator, uint256 indexed index, address createdTokenAddress);

//     mapping(TokenTypes => uint) private tokenTypeCount;

//     constructor() Ownable(msg.sender)  {      
//        tokenFeeCollector= address(this);

//        nativeFees[TokenTypes.SIMPLE]=0.001 ether;
//        nativeFees[TokenTypes.STANDARD]=0.0015 ether;
//        nativeFees[TokenTypes.BURNMINTABLE]=0.003 ether;
//     }

//     function setTokenFeeCollector(address newAddress) public onlyOwner{
//         tokenFeeCollector=newAddress;
//     }

//     function setZSaleNativeFee(TokenTypes tokenType, uint256 newPrice) public onlyOwner{
        
//         nativeFees[tokenType]=newPrice;
//     }

    
//     function createNewToken(TokenTypes tokenType,
//         string memory name,
//         string memory symbol,
//         uint8 decimals,
//         uint totalSupply
//     ) public payable  {

//         require(msg.value >= nativeFees[tokenType], 'TokenFactory: Requires Token Creation Price' );
            
//         _counter++; 
//         uint index = _counter;

//         address sender = msg.sender;

//         tokenTypeCount[tokenType]++;

//         if(tokenType == TokenTypes.SIMPLE){
//             // SimpleERC20Cloneable s= new SimpleERC20Cloneable();
//             // // s.initialize(name, symbol, totalSupply, decimals, sender, tokenFeeCollector);
            
//             // address newTokenAddress = address(s);
//             // console.log('newTokenAddress: ', newTokenAddress);
//             // (bool success, bytes memory returndata) = newTokenAddress.delegatecall(abi.encodeWithSignature("initialize(string,string,uint256,uint8,address,address)", name, symbol, totalSupply, decimals, sender, tokenFeeCollector));

//             //  // if the function call reverted
//             // if (success == false) {
//             //     // if there is a return reason string
//             //     if (returndata.length > 0) {
//             //         // bubble up any reason for revert
//             //         assembly {
//             //             let returndata_size := mload(returndata)
//             //             revert(add(32, returndata), returndata_size)
//             //         }
//             //     } else {
//             //         revert("Function call reverted");
//             //     }
//             // }

//             // _tokens.set(index, newTokenAddress);
//             // ownersToken[sender].push( index);
//             // _tokensList.push(newTokenAddress);
//             // emit TokenCreated(sender,index, newTokenAddress);
//         }else if(tokenType == TokenTypes.STANDARD){
//             // StandardERC20Cloneable s= new StandardERC20Cloneable(name, symbol, totalSupply, decimals, sender, tokenFeeCollector);
//             // address newTokenAddress = address(s);
//             // _tokens.set(index, newTokenAddress);
//             // ownersToken[sender].push( index);
//             // _tokensList.push(newTokenAddress);
//             // emit TokenCreated(sender,index, newTokenAddress);
//         }else if(tokenType == TokenTypes.BURNMINTABLE){
//             // BurnMintableCloneable s= new BurnMintableCloneable(name, symbol, totalSupply, decimals, sender, tokenFeeCollector);
//             // address newTokenAddress = address(s);
//             // _tokens.set(index, newTokenAddress);
//             // ownersToken[sender].push( index);
//             // _tokensList.push(newTokenAddress);
//             // emit TokenCreated(sender,index, newTokenAddress);
//         }

        

    
//     }


//     function getTokenTypeCount(TokenTypes tokenType) public view returns (uint256 count){
        
//         return tokenTypeCount[tokenType];
//     }

//     //offset 
//     function allOwnersTokens(uint256 limit, uint256 offset) public view returns (uint256[] memory) {
//         uint256[] memory list = new uint256[](offset) ;
//         for (uint256 i=limit; i < limit + offset ; i++) {
//             list[i-limit] = ownersToken[msg.sender][i]; 
//         }
//         return list;
//     }

    
//     function tokensCount() public view returns (uint256) {
//         return _counter;
//     }

//     function withdrawTokens(address tokenAddress) public onlyOwner  
//     {
//         IERC20 _token = IERC20(tokenAddress);
//         uint amount = _token.balanceOf(address(this));
//         require(amount > 0, "TokenMinterFactory: No Tokens to claim");
//         _token.safeTransfer( _msgSender(), amount);
//     }

    

      

//     function tokenAt(uint256 index) public view returns (uint256 key, address value) {
//         return _tokens.at(index);
//     }

//     function tryGetTokenByKey(uint256 key) public view returns (bool, address) {
//         return _tokens.tryGet(key);
//     }

    

//     // //abi.encodePacked(x)
//     // function concatenate(string memory s1, string memory s2) public pure returns (string memory) {
//     //     return string(abi.encodePacked(s1, s2));
//     // }

//     // function concatenate(string memory s1, address s2) public pure returns (string memory) {
//     //     return string(abi.encodePacked(s1, s2));
//     // }

// }