// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;


// import {IDexRouter, IDexFactory} from "../IDexRouter.sol";
// import "hardhat/console.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";




// // locks liquidity for LP tokens based on % of raised funds
// contract LiquidityLockerTest{

//     using SafeERC20 for IERC20;
//     // using SafeMath for uint256;

    

//      // timestamp when token release is enabled
//     uint256 private _releaseTime;

//     uint256 private _price; 
    

//     address private _owner; 

//     address private _deployer;

//     uint256 constant private MAX_INT = 2**256 - 1;

//     uint256 public totalTokensExpected ;
//     uint256 public totalEthExpected ;
    

//     address private _token;
//     address public lpTokenPairAddress;

//     IDexRouter private _dexRouter;
//     IDexFactory private _dexFactory;


    

    

//     constructor(address dexRouterAddress, address token, address owner, uint256 price,uint256 releaseTime, uint liquidityPercentOfRaisedFunds,uint maxRaisedFunds) {
//         require(releaseTime > block.timestamp, "LiquidityLocker: release time is before current time");
//         _releaseTime = releaseTime;
//         _dexRouter = IDexRouter(dexRouterAddress);
//         _dexFactory = IDexFactory(_dexRouter.factory());

//         _deployer = msg.sender;
//         _price = price;
//         _owner = owner;
//         _token = token;
//         console.log("liquidityPercentOfRaisedFunds:", liquidityPercentOfRaisedFunds);
//         console.log("maxRaisedFunds:", maxRaisedFunds);
//         console.log("_price:", _price);
//         totalEthExpected = (liquidityPercentOfRaisedFunds* maxRaisedFunds)  / 100;
//         totalTokensExpected = _price * totalEthExpected;

//         console.log("totalEthExpected:", totalEthExpected);
//         console.log("totalTokensExpected:", totalTokensExpected);
//     }

//     receive() external payable {

//     }

//     /**
//     * @dev Add Liquidity to Dex at defined price, if no pool exists it will create one.
//     *  Approve token for router, require contract to have the necessary tokens
//     *
//      */
//     function addLiquidity() public {
        
        
//         require(msg.sender == address(_deployer), "LiquidityLocker: Only deployer can call this function");
//         require(_token != address(0), "LiquidityLocker: Token can not be zero");
//         uint256 etherBalance = address(this).balance;
        
//         uint256 tokensAmount = _price * etherBalance;
//         uint256 tokensAmountMin = tokensAmount - (_price * etherBalance);
//         require(etherBalance >= totalEthExpected, "LiquidityLocker: no ether to add liquidity"); 

              
//         require( IERC20(_token).balanceOf(address(this)) >= totalTokensExpected, "LiquidityLocker: no token balance to add liquidity");
        
        
//         lpTokenPairAddress = _dexFactory.getPair(_token, _dexRouter.WETH() );
//         if(lpTokenPairAddress==address(0)){
//           lpTokenPairAddress = _dexFactory.createPair(_token, _dexRouter.WETH());          
//         }        
        
//         // _factory.createPair(address(this), _router.WETH());
//         IERC20(_token).approve(address(_dexRouter), MAX_INT);
//         IERC20(_token).approve(lpTokenPairAddress, MAX_INT);
//         console.log("lpTokenPairAddress:", lpTokenPairAddress);
//         _dexRouter.addLiquidityETH{value: totalEthExpected}(_token, tokensAmount , tokensAmount, totalEthExpected, address(this), block.timestamp + 100);

        
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
//         // solhint-disable-next-line not-rely-on-time
//         require(block.timestamp >= _releaseTime, "LiquidityLocker: current time is before release time");

//         IERC20 lptoken=IERC20(lpTokenPairAddress);
//         uint256 amount = lptoken.balanceOf(address(this));
//         require(amount > 0, "LiquidityLocker: no LP tokens to release");

//         lptoken.safeTransfer(_owner, amount); 
//     }

//     /**
//      * @notice Transfers tokens held by Lock to owner.
//        @dev Able to withdraw LP funds after release time 
//      */
//     function release() public {
//         // solhint-disable-next-line not-rely-on-time
//         require(block.timestamp >= _releaseTime, "LiquidityLocker: current time is before release time");

//         uint256 amount = IERC20(_token).balanceOf(address(this));
//         require(amount > 0, "LiquidityLocker: no tokens to release");

//         IERC20(_token).safeTransfer(_owner, amount); 
//     }

//        /**
//      * @notice Transfers ETH back to the owner
//        @dev Function used only if it was not used all the ETH
//      */
//     function releaseETH() public {
//         // solhint-disable-next-line not-rely-on-time
//         require(block.timestamp >= _releaseTime, "LiquidityLocker: current time is before release time");
//         require(address(this).balance > 0, "LiquidityLocker: no Eth to release");

//         payable(getOwner()).transfer(address(this).balance);
//     }
// }