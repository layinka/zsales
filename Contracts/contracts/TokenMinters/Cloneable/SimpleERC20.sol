// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.13;

// import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
// // import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "hardhat/console.sol";

// contract SimpleERC20Cloneable is Initializable, ERC20Upgradeable{

//     uint8 _decimals;
//     uint tokenFeePercent = 200;  //2% - percent fee of token to take

//     // constructor(string memory name, string memory symbol, uint256 totalSupply, uint8 decimals,address tokenOwner,address tokenFeeCollector) ERC20(name, symbol){
//     //     uint fee = totalSupply * tokenFeePercent/10000;
//     //     _mint(tokenOwner, totalSupply - fee);
//     //     _mint(tokenFeeCollector, fee);
//     //     _decimals = decimals;
//     // }

//     function initialize(string memory name, string memory symbol, uint256 totalSupply, uint8 decimals,address tokenOwner,address tokenFeeCollector) public initializer {
//         __ERC20_init(name, symbol);
//         //__Ownable_init();

//         tokenFeePercent = 200;  //2% - percent fee of token to take
//         console.log("Initializing....");
//         uint fee = totalSupply * tokenFeePercent/10000;
//         _mint(tokenOwner, totalSupply - fee);
//         _mint(tokenFeeCollector, fee);
//         _decimals = decimals;
//     }

//     function decimals() public view virtual override returns(uint8){
//         return _decimals;
//     }

// }