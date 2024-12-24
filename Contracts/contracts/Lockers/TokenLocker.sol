// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;



import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./VestSchedule.sol";


/**
* Locks ERC20 Tokens in a vested style.
* @dev Percentages are specified normally, e.g. 50% is 50
*/
contract TokenLocker is ReentrancyGuard{
    error InvalidPercent();
    error NotEnoughTokens();
    error WrongToken();

    using SafeERC20 for IERC20;
    // using SafeMath for uint256;
    

   
    address private _owner;

    address private _deployer;    

    address private _token;
    

    uint _cycles ;

    event TokenReleased(address indexed token, uint256 amount);
    
    VestSchedule[] public tokenVestSchedule ;

    constructor( address tokenAddress, address owner, 
        uint totalTokens, uint firstReleasePercent, uint firstReleaseDays, uint subsequentReleasePercent, uint subsequentReleaseDays) {

        // require(schedule.length <= 8, "TokenLocker: Vesting cannot have more than 8 schedules");
        
     
        require(firstReleasePercent + subsequentReleasePercent <= 100, InvalidPercent());

        _deployer = msg.sender;
        
        _owner = owner;
        _token = tokenAddress;

        // 50, 25
        //30, 30
        // 30, 35
        uint subsequentCycles = subsequentReleasePercent==0?0: (100 -  firstReleasePercent)/ subsequentReleasePercent; 
        bool hasExtraCycle = 100 -  firstReleasePercent  - (subsequentCycles * subsequentReleasePercent) > 0; 
        uint cycles = 1 +  subsequentCycles + ( hasExtraCycle? 1: 0 );

        _cycles = cycles;

        // tokenVestSchedule = new VestSchedule[](cycles);

        // tokenVestSchedule[0] = VestSchedule({
        //     releaseDate: block.timestamp + (firstReleaseDays * 1 days),
        //     releaseAmount: firstReleasePercent * totalTokens * 10000/1000000,
        //     hasBeenClaimed: false
        // });


        // for (uint i=0; i < subsequentCycles ; i++) {
        //     //first index is firstRelease
        //     tokenVestSchedule[i+1] = VestSchedule({
        //         releaseDate: tokenVestSchedule[0].releaseDate + ((i+1) * subsequentReleaseDays * 1 days),
        //         releaseAmount: subsequentReleasePercent * totalTokens * 10000/1000000,
        //         hasBeenClaimed: false
        //     });
        // }

        // //any extra 
        // if(hasExtraCycle){
        //     // extra cycle will account for frist cycle and the subsequentscyels hence s + 1
        //     tokenVestSchedule[subsequentCycles + 1] = VestSchedule({
        //         releaseDate: tokenVestSchedule[subsequentCycles].releaseDate + ( subsequentReleaseDays * 1 days), // add days to last vesting day
        //         releaseAmount: (100 -  firstReleasePercent  - (subsequentCycles * subsequentReleasePercent)) * totalTokens * 10000/1000000,
        //         hasBeenClaimed: false
        //     });
        // }


        

        tokenVestSchedule.push( VestSchedule({
            releaseDate: block.timestamp + (firstReleaseDays * 1 days),
            releaseAmount: firstReleasePercent * totalTokens * 10000/1000000,
            hasBeenClaimed: false
        }) );


        for (uint i=0; i < subsequentCycles ; i++) {
            //first index is firstRelease
            tokenVestSchedule.push( VestSchedule({
                releaseDate: tokenVestSchedule[0].releaseDate + ((i+1) * subsequentReleaseDays * 1 days),
                releaseAmount: subsequentReleasePercent * totalTokens * 10000/1000000,
                hasBeenClaimed: false
            }) );
        }

        //any extra 
        if(hasExtraCycle){
            // extra cycle will account for frist cycle and the subsequentscyels hence s + 1
            tokenVestSchedule.push( VestSchedule({
                releaseDate: tokenVestSchedule[subsequentCycles].releaseDate + ( subsequentReleaseDays * 1 days), // add days to last vesting day
                releaseAmount: (100 -  firstReleasePercent  - (subsequentCycles * subsequentReleasePercent)) * totalTokens * 10000/1000000,
                hasBeenClaimed: false
            }) );
        }
    }

    /**
     * @return the owner of the locked funds
     */
    function getOwner() public view returns (address) {
        return _owner;
    }

    function getVestingCycle() public view returns (VestSchedule[] memory schedule) {

        schedule = new VestSchedule[](_cycles);

        for (uint i=0; i < _cycles ; i++) {
            
            schedule[i]= tokenVestSchedule[i];
        }
        return schedule;
    }
    
    
    /**
     * @notice Transfers tokens held by Lock to owner.
       @dev Able to withdraw tokens after release time 
     */
    function release() public nonReentrant {
        uint256 amountToReleaseThisTime =0;
        uint i;
        for (i=0; i < _cycles; i++) { 
            if(block.timestamp >= tokenVestSchedule[i].releaseDate && !tokenVestSchedule[i].hasBeenClaimed ) {
                amountToReleaseThisTime += tokenVestSchedule[i].releaseAmount;
                tokenVestSchedule[i].hasBeenClaimed = true;
            }            
        }
        
        uint256 balance = IERC20(_token).balanceOf(address(this));
        //require(balance > 0, "TokenLocker: no tokens to release");
        require(balance >= amountToReleaseThisTime, NotEnoughTokens());

        IERC20(_token).safeTransfer(_owner, amountToReleaseThisTime);

        emit TokenReleased(_token, amountToReleaseThisTime); 
    }


    /**
     * @notice Transfers any ETH back to the owner, ETH is not locked
       @dev Function used to transfer eth mistakenly sent here
     */
    function withdrawETH() public {
        require(address(this).balance > 0, "TokenLocker: no Eth to release");

        payable(getOwner()).transfer(address(this).balance);
    }


    /**
     * @notice Transfers any unrecognised token back to the owner, 
       @dev Function used to transfer Tokens mistakenly sent here
     */
    function withdrawToken(address tokenToSend) public {
        require(_token!=tokenToSend, WrongToken());
        require(IERC20(tokenToSend).balanceOf(address(this)) > 0, NotEnoughTokens());

        IERC20(tokenToSend).safeTransfer(getOwner(), IERC20(tokenToSend).balanceOf(address(this))); 
        
    }

    /**
     * @notice Getter for the amount of releasable token tokens. token should be the address of an IERC20 contract.
     */
    function released() public view returns (uint ){
        uint256 amount=0;
        uint i;
        for (i=0; i < _cycles; i++) { 
            if(tokenVestSchedule[i].hasBeenClaimed ) {
                amount += tokenVestSchedule[i].releaseAmount;
            }            
        }
        return amount;
    }

    /**
     * @notice Getter for the amount of releasable token tokens. token should be the address of an IERC20 contract.
     */
    function releasable() public view returns (uint ){
        uint256 amount=0;
        uint i;
        for (i=0; i < _cycles; i++) { 
            if( block.timestamp >= tokenVestSchedule[i].releaseDate && !tokenVestSchedule[i].hasBeenClaimed) {
                amount += tokenVestSchedule[i].releaseAmount;
            }            
        }
        return amount;
    }
}