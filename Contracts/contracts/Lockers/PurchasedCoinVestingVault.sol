// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;


import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";



error MustBeLessThanYears(string info,uint noOfYears);
error DurationLessThanCliff();
error DailyVestedAmountLessThanZero();
error OnlyOwner();
error AmountVestedLessThanZero();
/**
* Locks liquidity for Purchased Coins in a vested style. using Cliffs
* @dev 
*/
contract PurchasedCoinVestingVault is Initializable, ReentrancyGuard  {
    using SafeERC20 for IERC20;

    uint256 constant public SECONDS_PER_DAY = 86400;

    struct Grant {
        uint256 startTime;
        uint256 amount;
        uint256 vestingDuration;
        uint256 vestingCliff;
        uint256 daysClaimed;
        uint256 totalClaimed;
    }
    address private _owner;
    address public _deployer;

    address private _coinOrTokenAddress;
    
    event GrantTokensClaimed(address indexed recipient, uint256 amountClaimed);
    
    
    Grant public grant;

    ///Do not leave an implementation contract uninitialized. An uninitialized implementation contract can be taken over by an attacker, which may impact the proxy. 
    /// To prevent the implementation contract from being used, you should invoke the _disableInitializers function in the constructor to automatically lock it when it is deployed
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    

    function initialize(address vaultOwner, 
        uint256 _startTime,
        uint256 _amount,
        uint256 _vestingDurationInDays,
        uint256 _vestingCliffInDays,
        address coinOrTokenAddress) public initializer {

        _deployer=msg.sender;
        _owner=vaultOwner;
        _coinOrTokenAddress=coinOrTokenAddress;
        require(_vestingCliffInDays <= 10*365, MustBeLessThanYears('Cliff',10) );
        require(_vestingDurationInDays <= 25*365, MustBeLessThanYears('Duration',25));
        require(_vestingDurationInDays >= _vestingCliffInDays, DurationLessThanCliff());
        
        uint256 amountVestedPerDay = ((_amount * 100000000)/_vestingDurationInDays)/100000000;
        require(amountVestedPerDay > 0, DailyVestedAmountLessThanZero());

        // Transfer the grant tokens under the control of the vesting contract
        // require(token.transferFrom(owner(), address(this), _amount), "transfer failed");

        grant = Grant({
            startTime: _startTime == 0 ? currentTime() : _startTime,
            amount: _amount,
            vestingDuration: _vestingDurationInDays,
            vestingCliff: _vestingCliffInDays,
            daysClaimed: 0,
            totalClaimed: 0
        });
        
        
    }

    receive() external payable {

    }
    // or
    function receiveTokens(uint256 amount) public payable {
      IERC20(_coinOrTokenAddress).safeTransferFrom(msg.sender, address(this), amount);
    }

    function owner() public view returns (address) {
        
        return _owner;

    }

    function transferOwnership(address newOwner) public  {
        
        require(msg.sender== _owner, OnlyOwner());
        _owner=newOwner;

    }
    

    /// @notice Calculate the vested and unclaimed months and tokens available for `_grantId` to claim
    /// Due to rounding errors once grant duration is reached, returns the entire left grant amount
    /// Returns (0, 0) if cliff has not been reached
    function calculateGrantClaim() public view returns (uint256, uint256) {
        

        // For grants created with a future start date, that hasn't been reached, return 0, 0
        if (currentTime() < grant.startTime) {
            return (0, 0);
        }

        // Check cliff was reached
        uint elapsedTime = currentTime()-grant.startTime;
        uint elapsedDays = elapsedTime/SECONDS_PER_DAY;
        
        if (elapsedDays < grant.vestingCliff) {
            return (elapsedDays, 0);
        }

        // If over vesting duration, all tokens vested
        if (elapsedDays >= grant.vestingDuration) {
            uint256 remainingGrant = grant.amount-grant.totalClaimed;
            return (grant.vestingDuration, remainingGrant);
        } else {
            uint256 daysVested = elapsedDays-grant.daysClaimed;
            uint256 amountVestedPerDay = grant.amount/ grant.vestingDuration;
            uint256 amountVested = daysVested*amountVestedPerDay;
            return (daysVested, amountVested);
        }
    }

    /// @notice Allows a grant recipient to claim their vested tokens. Errors if no tokens have vested
    /// It is advised recipients check they are entitled to claim via `calculateGrantClaim` before calling this
    function claimVestedCoins() external nonReentrant {
        uint256 daysVested;
        uint256 amountVested;
        address recipient=owner();

        (daysVested, amountVested) = calculateGrantClaim();
        require(amountVested > 0, AmountVestedLessThanZero());

        
        grant.daysClaimed = grant.daysClaimed+ daysVested;
        grant.totalClaimed = grant.totalClaimed + amountVested;
        
        // token.safeTransfer(recipient, amountVested);
        if(_coinOrTokenAddress==address(0)){
            payable(recipient).transfer(amountVested);
        }else{            
            IERC20(_coinOrTokenAddress).safeTransfer(recipient, amountVested); 
        }
        
        emit GrantTokensClaimed(recipient, amountVested);
    }

    function currentTime() private view returns(uint256) {
        return block.timestamp;
    }

    function tokensVestedPerDay() public view returns(uint256) {
        
        return grant.amount/ grant.vestingDuration;
    }

    

}