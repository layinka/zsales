// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.28;


// import {IDexRouter, IDexFactory} from "../IDexRouter.sol";

// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
// import "hardhat/console.sol";
// import "../Errors.sol";





// // locks liquidity for LP tokens based on % of raised funds
// contract LiquidityLocker{

//     using SafeERC20 for IERC20;
//     // using SafeMath for uint256;

    

//      // timestamp when token release is enabled
//     uint256 private _releaseTime;

//     uint256 private _price; 
    

//     address private _owner; 

//     address private _deployer;

//     uint256 constant private MAX_INT = 2**256 - 1;

//     uint256 public minTokensExpected ;
//     uint256 public maxTokensExpected ;
//     uint256 public minPurchaseTokenExpected ;
//     uint256 public maxPurchaseTokenExpected ;
    

//     address private _token;
//     address purchaseTokenAddress;
//     address public lpTokenPairAddress;

//     IDexRouter private _dexRouter;
//     IDexFactory private _dexFactory;

//     bool private _campaignSucceded;

//     event LiquidityAddedToRouter(address indexed router, address indexed token1,address indexed token2, uint amountToken1, uint amountToken2);


//     constructor(address dexRouterAddress, address token,address purchaseToken, address owner, 
//       uint256 price,uint256 releaseTime, 
//     uint liquidityPercentOfRaisedFunds,uint minRaisedFunds, uint maxRaisedFunds) {
        
//         if(releaseTime <= block.timestamp){
//           revert CurrentTimeIsBeforeRelease();
//         }
//         _releaseTime = releaseTime;
//         _dexRouter = IDexRouter(dexRouterAddress);
//         _dexFactory = IDexFactory(_dexRouter.factory());

//         _deployer = msg.sender;
//         _price = price;
//         _owner = owner;
//         _token = token;
//         purchaseTokenAddress=purchaseToken;
//         minPurchaseTokenExpected = (liquidityPercentOfRaisedFunds* minRaisedFunds)  / 10000;
//         minTokensExpected = _price * minPurchaseTokenExpected;

//         maxPurchaseTokenExpected = (liquidityPercentOfRaisedFunds * maxRaisedFunds)  / 10000;
//         maxTokensExpected = _price * maxPurchaseTokenExpected;

//     }

//     receive() external payable {

//     }

//     // function receivePurchaseTokens(uint256 amount) public payable {
//     //   IERC20(purchaseTokenAddress).safeTransferFrom(msg.sender, address(this), amount);
//     // }

//     /**
//     * @dev Add Liquidity to Dex at defined price, if no pool exists it will create one.
//     *  Approve token for router, require contract to have the necessary tokens
//     *
//     */
//     function addLiquidity() public {
//         if (msg.sender != address(_deployer)) revert OnlyDeployer();
//         if (_token == address(0)) revert NoZeroTokenAddress();
//         if (purchaseTokenAddress == address(0)) {
//             _addLiquidityWithEth();
//         } else {
//             _addLiquidityWithErc20PurchaseToken();
//         }
//     }

//     function _addLiquidityWithEth() private {
//         uint256 etherBalance = address(this).balance;
//         uint256 tokensAmount = _price * etherBalance/ 10**(18 - IERC20Metadata(_token).decimals());
        
//         // uint256 tokensAmountMin = tokensAmount - (_price * etherBalance);
//         if (etherBalance < minPurchaseTokenExpected) revert NoEthForLiquidity();
//         if (IERC20(_token).balanceOf(address(this)) < minTokensExpected) revert NoTokenBalanceForLiquidity();
        
//         lpTokenPairAddress = _dexFactory.getPair(_token, _dexRouter.WETH());
//         if (lpTokenPairAddress == address(0)) {
//             lpTokenPairAddress = _dexFactory.createPair(_token, _dexRouter.WETH());
//         }
        
//         IERC20(_token).approve(address(_dexRouter), MAX_INT);
//         IERC20(_token).approve(lpTokenPairAddress, MAX_INT);

//         IERC20(_dexRouter.WETH()).approve(address(_dexRouter), MAX_INT);
//         IERC20(_dexRouter.WETH()).approve(lpTokenPairAddress, MAX_INT);
        
//         _dexRouter.addLiquidityETH{value: etherBalance}(
//             _token,
//             tokensAmount,
//             tokensAmount,
//             etherBalance,
//             address(this),
//             block.timestamp + 100
//         );
        
//         emit LiquidityAddedToRouter(address(_dexRouter), address(0),_token,etherBalance,tokensAmount  );
//     }


    

//     function _addLiquidityWithErc20PurchaseToken() private {       
      
//       uint256 puchaseTokenBalance = IERC20(purchaseTokenAddress).balanceOf(address(this));
//       uint256 tokenBalance = IERC20(_token).balanceOf(address(this));

//       uint256 tokensAmount = _price * puchaseTokenBalance;
//       // uint256 tokensAmountMin = tokensAmount - (_price * puchaseTokenBalance); 
//       if (puchaseTokenBalance < minPurchaseTokenExpected) revert NoPurchaseTokensForLiquidity();
//       if (tokenBalance < minTokensExpected) revert NoTokensForLiquidity();
       
      
//       lpTokenPairAddress = _dexFactory.getPair(_token, purchaseTokenAddress );
//       if(lpTokenPairAddress==address(0)){
//         lpTokenPairAddress = _dexFactory.createPair(_token, purchaseTokenAddress);          
//       }        
      
//       IERC20(_token).approve(address(_dexRouter), MAX_INT);
//       IERC20(purchaseTokenAddress).approve(address(_dexRouter), MAX_INT);
//       IERC20(_token).approve(lpTokenPairAddress, MAX_INT);
//       IERC20(purchaseTokenAddress).approve(lpTokenPairAddress, MAX_INT);


//       _dexRouter.addLiquidity(
//           _token,
//           purchaseTokenAddress,
//           tokenBalance,
//           puchaseTokenBalance,
//           tokenBalance,
//           puchaseTokenBalance,            
//           address(this),
//           block.timestamp + 100
//       );
      
//       emit LiquidityAddedToRouter(address(_dexRouter), purchaseTokenAddress,_token,puchaseTokenBalance,tokenBalance  );
//     }

//     function setCampaignSucceded(bool status) public  {      
//       if (msg.sender != address(_deployer)) revert OnlyDeployer();
//       _campaignSucceded=status;
//     }

//    /**
//      * @return the time when the tokens are released.
//      */
//     function getReleaseTime() public view returns (uint256) {
//         return _releaseTime;
//     }

//       /**
//      * @return the owner of the locked funds
//      */
//     function getOwner() public view returns (address) {
//         return _owner;
//     }
    
//     /**
//      * @notice Transfers LP tokens held by Lock to owner.
//        @dev Able to withdraw LP funds after release time 
//      */
//     function releaseLPTokens() public {
//       if (block.timestamp < _releaseTime) revert CurrentTimeIsBeforeRelease();
//       if (lpTokenPairAddress == address(0)) revert AddLiquidityNotCalledYet();

//       IERC20 lptoken = IERC20(lpTokenPairAddress);
//       uint256 amount = lptoken.balanceOf(address(this));
//       if (amount == 0) revert NoLPTokensToRelease();

//       lptoken.safeTransfer(_owner, amount);
//     }

//     /**
//      * @notice Transfers tokens held by Lock to owner.
//        @dev Able to withdraw LP funds after release time 
//      */
//     function releaseSalesTokens() public {
//       if (block.timestamp < _releaseTime) revert CurrentTimeIsBeforeRelease();
//       if (_campaignSucceded && lpTokenPairAddress == address(0)) revert AddLiquidityNotCalledYet();

//       uint256 amount = IERC20(_token).balanceOf(address(this));
//       if (amount == 0) revert NoTokensToRelease();

//       IERC20(_token).safeTransfer(_owner, amount);
//     }

//     /**
//      * @notice Transfers ETH/Purchase tokens back to the owner
//        @dev Function used only if it was not used all the ETH
//      */
//     function releasePurchaseTokens() public {
//       if (block.timestamp < _releaseTime) revert CurrentTimeIsBeforeRelease();
//       uint256 balance = 0;

//       if (purchaseTokenAddress == address(0)) {
//           balance = address(this).balance;
//       } else {
//           balance = IERC20(purchaseTokenAddress).balanceOf(address(this));
//       }
//       if (balance == 0) revert NoPurchaseTokensToRelease();

//       if (_campaignSucceded && lpTokenPairAddress == address(0)) revert AddLiquidityNotCalledYet();

//       if (purchaseTokenAddress == address(0)) {
//           payable(getOwner()).transfer(address(this).balance);
//       } else {
//           IERC20(purchaseTokenAddress).safeTransfer(_owner, balance);
//       }
//     }
    
// }