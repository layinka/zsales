// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./VestSchedule.sol";
import "./TokenLocker.sol";
import "../Errors.sol";

import "./PurchasedCoinVestingVault.sol";
// import "./LiquidityLocker.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "hardhat/console.sol";

error NotEnoughCoinsForRaisedFundsLock();
error LiquidityAmountTransferFailed();

/// @title IDexLocker
/// @notice Manages liquidity and vesting for tokens raised in sales campaigns
interface IDexLocker {
    function initialize(
        // address dexRouterAddress,
        address token,
        address purchaseToken,
        address deployer,
        address owner,
        address purchasedCoinVestingVaultImplementationAddress
    ) external;

    function setupLock(
        
        // uint minRaisedFunds,uint maxRaisedFunds, 
        uint[2] calldata raisedFunds,
        // bool isFairLaunch, 
        // uint256 saleListPrice,  uint256 dexListPrice, 
        uint256[2] calldata saleAndDexRates,

        bool useTeamTokenVesting, 
        uint256[5] calldata teamTokenVestingDetails, 
        bool useRaisedFundsVesting, 
        uint256[3] calldata raisedFundVestingDetails 
    ) external;

     
     /// @dev If campaign Locks raised fund, lock the calculated amount
     ///
    function startRaisedFundsLock(uint256 raisedAmountAfterAllDeductions) external payable;

    function lockERC20(address tokenAddress,address tokenOwner, uint totalTokens, uint firstReleasePercent, uint firstReleaseDays, 
        uint subsequentReleasePercent, uint subsequentReleaseDays ) external returns(address lockerAddress);

    function getOwner() external view returns (address);

    function releaseTeamTokens() external;

    function releaseCoinVaultETH() external;

    function raisedFundsVaultAddress() external view returns (address);

    function raisedFundsPercent() external view returns (uint);

    function tokenLockerAddress() external view returns (address);

    // function liquidityLockerAddress() external view returns (address);

    // function totalTokensExpectedToBeLocked() external view returns(uint);
}

/// @title DexLocker
/// @notice Manages vesting for tokens raised in sales campaigns, LP TOkens and Team Vesting tokens
contract DexLocker is Initializable, IDexLocker{
    error DLOnlyDeployer();
    error DLReleaseBeforeTime();
    error TokenCannotBeAddressZero();
    using SafeERC20 for IERC20;

    event ERC20LockCreated(address indexed lockerAddress, address indexed token, address indexed owner, uint totalTokensLocked);
    
    address private _owner;

    address private _deployer;

    uint256 constant private MAX_INT = 2**256 - 1;

    // uint public totalTokensExpectedToBeLocked;

    address private _token;
    address private _purchaseToken;

    TokenLocker private _teamTokensLocker;
    PurchasedCoinVestingVault private _purchasedCoinVestingVault;
    // LiquidityLocker private _liquidityLocker;
    // uint private _liquidityPercentOfRaisedFunds;

    /**
    Maps to 
    
        uint256 _percentOfRaisedFundsToLock,
        uint256 _vestingDurationInDays,
        uint256 _vestingCliffInDays
     */
    uint256[3] _raisedFundVestingDetails;
    bool _useRaisedFundsVesting;

    address  _purchasedCoinVestingVaultImplementationAddress;

    ///Do not leave an implementation contract uninitialized. An uninitialized implementation contract can be taken over by an attacker, which may impact the proxy. 
    /// To prevent the implementation contract from being used, you should invoke the _disableInitializers function in the constructor to automatically lock it when it is deployed
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize( address token, address purchaseToken,address deployer,address owner, address purchasedCoinVestingVaultImplementationAddress ) public initializer  {
        require(token != address(0), InvalidSalesTokenAddress(token));
        require(deployer != address(0), InvalidDeployerAddress(deployer));
        require(owner != address(0), InvalidOwnerAddress(owner));

        
        _deployer = deployer; //msg.sender;
        
        _owner = owner;
        _token = token; 
        _purchaseToken=purchaseToken;
        _purchasedCoinVestingVaultImplementationAddress=purchasedCoinVestingVaultImplementationAddress;       
    }

    
    function setupLock(
        // uint minRaisedFunds,uint maxRaisedFunds, 
        uint[2] calldata raisedFunds,  
        // bool isFairLaunch,      
        // uint256 saleListPrice,  uint256 dexListPrice, 
        uint256[2] calldata saleAndDexRates,
        bool useTeamTokenVesting, 
        uint256[5] calldata teamTokenVestingDetails, 
        bool useRaisedFundsVesting, 
        uint256[3] calldata raisedFundVestingDetails 
    ) public {
        
        require(msg.sender == _deployer, DLOnlyDeployer());        

        // totalTokensExpectedToBeLocked = 0;
        
        // if(!isFairLaunch){
        //     //Sold tokens
        //     totalTokensExpectedToBeLocked += saleAndDexRates[0] * raisedFunds[1];
        // }
        
        if(useTeamTokenVesting){
            
            _teamTokensLocker = new TokenLocker(_token, _owner,teamTokenVestingDetails[0],teamTokenVestingDetails[1],teamTokenVestingDetails[2],teamTokenVestingDetails[3],teamTokenVestingDetails[4] );
            //totalTokensExpectedToBeLocked += normalizeTokenAmount(teamTokenVestingDetails[0], IERC20Metadata(_token).decimals());
        }
        

        _useRaisedFundsVesting=useRaisedFundsVesting;
        if(_useRaisedFundsVesting){
            for (uint8 i=0; i < 3 ; i++) {
                _raisedFundVestingDetails[i] = raisedFundVestingDetails[i]; 
            }
        }
        
    }

    /**
     * Raised funds
     */
    function startRaisedFundsLock(uint256 _raisedAmountAfterAllDeductions) public payable {
        require(msg.sender == _deployer, DLOnlyDeployer());
        
        if(_useRaisedFundsVesting){
           if(_purchaseToken==address(0) && msg.value< _raisedFundVestingDetails[0] * _raisedAmountAfterAllDeductions /10000 ) revert NotEnoughCoinsForRaisedFundsLock();
            address newCoinVaultCloneAddress = Clones.clone(_purchasedCoinVestingVaultImplementationAddress);
            _purchasedCoinVestingVault = PurchasedCoinVestingVault(payable(newCoinVaultCloneAddress) );
            
            _purchasedCoinVestingVault.initialize(_owner,block.timestamp, _raisedFundVestingDetails[0] * _raisedAmountAfterAllDeductions /10000, _raisedFundVestingDetails[1],_raisedFundVestingDetails[2], _purchaseToken);
            
            //Send coins
            if(_purchaseToken==address(0)){
                payable(_purchasedCoinVestingVault).transfer(_raisedFundVestingDetails[0] * _raisedAmountAfterAllDeductions /10000);
            }else{
                IERC20(_purchaseToken).safeTransfer(address(_purchasedCoinVestingVault),_raisedFundVestingDetails[0] * _raisedAmountAfterAllDeductions /10000);
                //_purchasedCoinVestingVault.receiveTokens(_raisedFundVestingDetails[0] * _raisedAmountAfterAllDeductions /10000 );
            }
            
        }
        
    }

    receive() external payable {
        // payable(_coinLocker).transfer(msg.value);
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

    function lockERC20(address tokenAddress,address tokenOwner, uint totalTokens, uint firstReleasePercent, uint firstReleaseDays, 
        uint subsequentReleasePercent, uint subsequentReleaseDays ) public returns(address lockerAddress) {
        require(tokenAddress!=address(0), TokenCannotBeAddressZero());
        TokenLocker tokenLocker= new TokenLocker(tokenAddress, tokenOwner,totalTokens, firstReleasePercent,firstReleaseDays,subsequentReleasePercent,subsequentReleaseDays );
        lockerAddress= address(tokenLocker);
        emit ERC20LockCreated(lockerAddress,tokenAddress, tokenOwner ,totalTokens );
    }
  

//    /**
//      * @return the time when the LP tokens are released.
//      */
//     function getLiquidityReleaseTime() public view returns (uint256) {
//         return _lpReleaseTime;
//     }

      /**
     * @return the owner of the locked funds
     */
    function getOwner() public view returns (address) {
        return _owner;
    }
    
    // /**
    //  * @notice Transfers tokens held by Lock to owner.
    //    @dev Able to withdraw LP funds after release time 
    //  */
    // function releaseLPTokens() public {
    //     _liquidityLocker.releaseLPTokens(); 
    // }

    /**
     * @notice Transfers tokens held by Lock to owner.
     */
    function releaseTeamTokens() public {
        _teamTokensLocker.release();
    }

    /**
     * @notice Transfers ETH back to the owner
     */
    function releaseCoinVaultETH() public {
        _purchasedCoinVestingVault.claimVestedCoins();
    }

    function raisedFundsVaultAddress() public view returns (address) {
        return address(_purchasedCoinVestingVault);
    }

    function raisedFundsPercent() public view returns (uint) {
        return _raisedFundVestingDetails[0];
    }

    function tokenLockerAddress() public view returns (address) {
        return address(_teamTokensLocker);
    }

    // function liquidityLockerAddress() public view returns (address) {
    //     return address(_liquidityLocker);
    // }
}