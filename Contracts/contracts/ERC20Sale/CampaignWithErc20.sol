// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.8;

// import "@openzeppelin/contracts/utils/Context.sol";
// // import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


// import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
// // import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import '../Lockers/DexLockerFactory.sol';
// import '../Lockers/DexLocker.sol';
// import "../Lockers/VestSchedule.sol";
// import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
// import "hardhat/console.sol";
// import {ICampaignList} from "../CampaignList.sol";

// contract CampaignWithErc20 is Initializable,Ownable, ReentrancyGuard {
//   using SafeERC20 for IERC20;

//   event AdminOwnershipTransferred(address indexed previousAdmin, address indexed newAdmin);
//   event ValueReceived(address user, uint amount);
//   event Withdrawn(address user, uint amount);
//   event Refunded(address user, uint amount);
//   event SoldOut();

//   struct CampaignSaleInfo {
//       //token attributes
//       address   tokenAddress; 
//       uint256  softCap; // Soft cap in coin
//       uint256  hardCap; // Max cap in coin
//       uint256  saleStartTime; // start sale time
//       uint256  saleEndTime; // end sale time
//       uint   liquidityPercent; // multiplied by 100 e.g 45% is 4500
//       uint   listRate; 
//       uint   dexListRate;
//       RefundType  refundType;
//       string logoUrl;
//       string desc;
//       string website;
//       string twitter;
//       string telegram;
//       string discord;
      
//   }
//   enum CampaignStatus{ 
//     CREATED,
//     TOKENS_SUBMITTED,//Owner has transferred the correct no of tokens and campaign is ready to receive
//     CANCELLED, // Cancelled before the start date
    
//     FAILED, // WIll need refund
//     LIQUIDITY_SETUP

//   }

//   bool   useWhiteList;//Use in only Tier 2
//   bool   public hasKYC;
//   bool _isAudited; 
//   string public auditUrl;
//   CampaignStatus public  status = CampaignStatus.CREATED;

//   address private _admin= 0xB7e16f5fa9941B84baCd1601F277B00911Aed339; //zsales admin - can setkyc and audited
    
//   CampaignSaleInfo public  saleInfo; 
  
//   address public dexRouterAddress;
//   uint256 public totalCoinReceived; // total  received
//   uint256 public totalCoinInTierOne; // total coin for tier one
//   uint256 public totalCoinInTierTwo; // total coin for tier Tier

//   address public purchaseTokenAddress=address(0); // Token address for Purchases for this campaign - address 0 is native currency
  
//   uint public totalParticipants; // total participants in ido
  

//   address public zsalesTokenAddress = 0x97CEe927A48dc119Fd0b0b1047a879153975e893;
//   uint zsaleFee;  // percent of native currency to take
//   uint zsaleTokenFee;  //percent fee of token to take


//   address zsalesWalletAddress; // receives commissions
//   address public _campaignFactory ;

//   uint private tier1TimeLineInHours = 2; // e.g 2 hours before startime
  
//   // max cap per tier
//   uint public tierOnehardCap;
//   uint public tierTwohardCap;
    
//   //total users per tier
//   uint public totalUserInTierOne;
//   uint public totalUserInTierTwo;
  
//   bool public useTokenVesting;
//   bool public useRaisedFundsVesting;

//     //Tier 1 - holders of our coin
//     //Tier 2 - Whitelisted or public
   
//   uint public minAllocationPerUser;
//   //max allocations per user in a tier
//   uint public maxAllocationPerUserTierOne;
//   uint public maxAllocationPerUserTierTwo; 
  
 
//   // // address array for tier one whitelist
//   // address[] private whitelistTierOne;  // every tokenholder is automatically whitelisted
  
//   // // address array for tier two whitelist
//   // address[] private whitelistTierTwo; 

//   bytes32 private _whitelistTierTwoMerkleRoot;
  

//   uint public campaignKey;
//   enum RefundType{ BURN, REFUND }
  
//   uint256 public liquidityReleaseTime; // time to relesase Lp tokens to owner

//   //mapping the user purchase per tier
//   mapping(address => uint) public buyInOneTier;
//   mapping(address => uint) public buyInTwoTier;
//   mapping(address => uint) public buyInAllTiers;
//   DexLockerFactory private _dexLockerFactory;
//   address payable private _dexLockerAddress;
  

//   ///Do not leave an implementation contract uninitialized. An uninitialized implementation contract can be taken over by an attacker, which may impact the proxy. 
//   /// To prevent the implementation contract from being used, you should invoke the _disableInitializers function in the constructor to automatically lock it when it is deployed
//   /// @custom:oz-upgrades-unsafe-allow constructor
//   constructor() {
//       _disableInitializers();
//   }

//   function initialize(
    
//     /** address campaignOwner,
//     /* address campaignFactory,
//     /* address  _saletokenAddress, */
//     /* address  _purchaseTokenAddress, */
//     address[4] memory addresses,

//     /** uint256 _softCap,uint256 _hardCap,uint256 _saleStartTime,uint256 _saleEndTime, uint256 _tierOneHardCap, uint256 _tierTwoHardCap, uint256 _maxAllocationPerUserTierOne, uint256 _maxAllocationPerUserTierTwo ,uint _campaignKey,*/
//     uint256[10] memory capAndDate,  
    
//     RefundType _refundType, 
//     address _dexRouterAddress,

//     /**uint _liquidityPercent, 
//     /* uint liquidityReleaseTime,
//     /* uint _listRate, 
//     /* uint _dexListRate,**/
//     uint[4] memory liquidityAllocationAndRates,
    
//     bool[2] memory _useTokenOrRaisedFundVesting,
//     VestSchedule[8] memory teamTokenVestingDetails, 
//     uint256[3] memory raisedFundVestingDetails,
//     string[6] memory founderInfo,
//     DexLockerFactory dexLockerFactory 
//   ) public payable initializer {
//     _setDefaultValues();
//     campaignKey=capAndDate[9];
//     _campaignFactory= addresses[1];
//     _dexLockerFactory=dexLockerFactory;
//     purchaseTokenAddress=addresses[3];
    
//     // require(releaseTime > block.timestamp, "CAMPAIGN: release time above current time");
//     require(capAndDate[3] > capAndDate[2], "CAMPAIGN: Sale End time above start time");
//     require(liquidityAllocationAndRates[0] >= 5100, "CAMPAIGN: Liquidity allowed is > 51 %");
      
//      /* console.log(
//         "Transferring from %s to %s %s tokens",
//         msg.sender,
//         to,
//         amount
//     ); */

    
      
//     // //block scopin to avoid stack too deep 
//     {
      
//       // saleInfo= CampaignSaleInfo();
//       saleInfo.tokenAddress=addresses[2];
//       saleInfo.softCap=capAndDate[0];
//       saleInfo.hardCap=capAndDate[1];
//       // if(capAndDate[2] <= block.timestamp){
//       //   saleInfo.saleStartTime=block.timestamp;
//       // }else{
//       //   saleInfo.saleStartTime=capAndDate[2];
//       // }
//       saleInfo.saleStartTime=capAndDate[2];
      
//       saleInfo.saleEndTime=capAndDate[3];
//       saleInfo.liquidityPercent=liquidityAllocationAndRates[0];
//       saleInfo.listRate=liquidityAllocationAndRates[2];
//       saleInfo.dexListRate=liquidityAllocationAndRates[3];
//       saleInfo.refundType=_refundType;
//     }        
    
//     {    
//       dexRouterAddress=_dexRouterAddress; 
        
//     }
    
      
//     _updateCampaignFounderDetails(founderInfo[0],founderInfo[1],founderInfo[2],founderInfo[3],founderInfo[4], founderInfo[5]);
    
    
//     _updateTierDetails (capAndDate[4], capAndDate[5], capAndDate[6],capAndDate[7], capAndDate[8]);

    

//     _transferOwnership(addresses[0]);
    

//     _updateLockDetails(liquidityAllocationAndRates[1], _useTokenOrRaisedFundVesting[0], teamTokenVestingDetails,_useTokenOrRaisedFundVesting[1], raisedFundVestingDetails );

    
//   }

//   //needed since initializable contracts do not have constructors
//   function _setDefaultValues() private {
//     status = CampaignStatus.CREATED;

//     _admin= 0xB7e16f5fa9941B84baCd1601F277B00911Aed339; //zsales admin - can setkyc and audited
//     ICampaignList cList = ICampaignList(_campaignFactory);

//     zsalesTokenAddress = cList.zsalesTokenAddress();
//     zsaleFee = cList.zsaleFee();  //2%   - percent of native currency to take
//     zsaleTokenFee = cList.zsaleTokenFee();  //2% - percent fee of token to take
//     zsalesWalletAddress = cList.zsalesWalletAddress() ; // receives commissions
//     tier1TimeLineInHours = 2; // e.g 2 hours before startime
//   }
  
//   // function to update other details not initialized in constructor - this is bcos solidity limits how many variables u can pass in at once
//   function _updateLockDetails(uint liquidityReleaseTimeDays, //Time to add to startTime in days
//     bool _useTokenVesting,
//     VestSchedule[8] memory teamTokenVestingDetails,
//     bool _useRaisedFundsVesting, 
//     uint256[3] memory raisedFundVestingDetails
      
//   ) private /*public onlyOwner*/ {
//     liquidityReleaseTime  = saleInfo.saleEndTime + (liquidityReleaseTimeDays * 1 days);
//     useTokenVesting=_useTokenVesting;
//     useRaisedFundsVesting=_useRaisedFundsVesting;

    
//     //Set dexLock
//     DexLocker dexLocker = DexLocker(payable(_dexLockerFactory.createDexLocker(dexRouterAddress,saleInfo.tokenAddress,address(this), msg.sender) ) );
    
    
//     dexLocker.setupLock(saleInfo.liquidityPercent,saleInfo.softCap,saleInfo.hardCap, liquidityReleaseTime,  saleInfo.dexListRate,useTokenVesting, teamTokenVestingDetails, _useRaisedFundsVesting,  raisedFundVestingDetails);

    
//     _dexLockerAddress= payable(dexLocker);
    
//     status = CampaignStatus.CREATED;

    

//     //if doesnt use tokenvesting , _startReceivingBids();
//     if(!useTokenVesting){
//       _startReceivingBids();
//     }

    

//   }

//   function _updateCampaignFounderDetails(
//     string memory logoUrl,
//     string memory desc,
//     string memory website,
//     string memory twitter,
//     string memory telegram,
//     string memory discord
//   ) private {
//     saleInfo.logoUrl= logoUrl;
//     saleInfo.desc= desc;
//     saleInfo.website= website;
//     saleInfo.twitter= twitter;
//     saleInfo.telegram= telegram;
//     saleInfo.discord= discord;
//   }

//   function updateCampaignFounderDetails(
//     string memory logoUrl,
//     string memory desc,
//     string memory website,
//     string memory twitter,
//     string memory telegram,
//     string memory discord
//   ) external onlyOwner {

//     require(block.timestamp <= saleInfo.saleStartTime, 'CAMPAIGN: Can only updateTierDetails before Sale StartTime');
//     _updateCampaignFounderDetails(logoUrl,desc,website,twitter,telegram,discord);
//   }
    
//   // function to update the tiers users value manually
//   function _updateTierDetails(uint256 _tierOneHardCap, uint256 _tierTwoHardCap, uint256 _minAllocationPerUser, uint256 _maxAllocationPerUserTierOne, uint256 _maxAllocationPerUserTierTwo) private {
    
//     require(_tierOneHardCap > (saleInfo.hardCap * 3000 / 10000), "CAMPAIGN: Tier Caps must be greater than 30 %" );
//     // require(_tierOneHardCap + _tierTwoHardCap == saleInfo.hardCap, "CAMPAIGN: Tier 1 & 2 Caps must be equal to hard cap" );
//     require(_tierOneHardCap <= saleInfo.hardCap, "CAMPAIGN: Tier 1 Caps must be Less than or equal to hard cap" );
//     require(_tierTwoHardCap <= saleInfo.hardCap, "CAMPAIGN: Tier 2 Caps must be Less than or  equal to hard cap" );
    
//     require(_minAllocationPerUser > 0, "CAMPAIGN: Min Allocation must be greater than 0" );
//     require(_maxAllocationPerUserTierOne > 0, "CAMPAIGN: Tier 1 Max Allocation must be greater than 0" );
//     require(_maxAllocationPerUserTierTwo > 0, "CAMPAIGN: Tier 2 Max Allocation must be greater than 0" );
    
    
//     tierOnehardCap =_tierOneHardCap;
//     tierTwohardCap = _tierTwoHardCap;    
    
//     minAllocationPerUser=_minAllocationPerUser; 
//     maxAllocationPerUserTierOne = _maxAllocationPerUserTierOne;
//     maxAllocationPerUserTierTwo = _maxAllocationPerUserTierTwo;
//   }

//   function updateTierDetails(uint256 _tierOneHardCap, uint256 _tierTwoHardCap, uint256 _minAllocationPerUser, uint256 _maxAllocationPerUserTierOne, uint256 _maxAllocationPerUserTierTwo) public onlyOwner {
//     require(block.timestamp <= saleInfo.saleStartTime, 'Can only updateTierDetails before Sale StartTime');
//     _updateTierDetails(_tierOneHardCap, _tierTwoHardCap, _minAllocationPerUser, _maxAllocationPerUserTierOne, _maxAllocationPerUserTierTwo);    
//   }

//   function _startReceivingBids() private 
//   {    
//     status = CampaignStatus.TOKENS_SUBMITTED;
//   }

//   function startReceivingBids() public 
//   {
//     //can only be called by _campaignFactory
//     require(_campaignFactory== _msgSender(), 'CAMPAIGNList: startReceivingBids - Not Owner');
//     _startReceivingBids();
//   }


//   function cancelCampaign() public onlyOwner{
//     require(block.timestamp < saleInfo.saleStartTime, 'Can only cancel before Sale StartTime');
//     status=CampaignStatus.CANCELLED;
//   }

//   function postponeSale(uint newDate, uint newEndDate) public onlyOwner  {
//       require(block.timestamp< saleInfo.saleStartTime, 'CAMPAIGN: Can only postpone before Sale StartTime');
//       require(newDate > saleInfo.saleStartTime , 'CAMPAIGN: New date must be grt than oldDate');
//       require(newEndDate > newDate, 'CAMPAIGN: End Date must be grt than Sale StartTime');
//       saleInfo.saleStartTime = newDate;
//       saleInfo.saleEndTime = newEndDate;
//   }

//   function getEndDate() public view returns (uint256) {
//     return saleInfo.saleEndTime;
//   }

//   function totalTokensExpectedToBeLocked() public view returns (uint256) {
//     return DexLocker(_dexLockerAddress).totalTokensExpectedToBeLocked();
//   }

 
//   function setZSalesTokenAddress(address _tokenAddress) public onlyAdmin {
//     zsalesTokenAddress = _tokenAddress;
//   }


//   /**************************|
//   |          Tier Info       |
//   |_________________________*/
//   //add the address in Whitelist tier two to invest
//   function disableTier2Whitelist() public onlyOwner {    
//     useWhiteList= false;
//   }

//   //add the address in Whitelist tier two to invest
//   function submitTier2Whitelist(bytes32 whitelistMerkleRoot) public onlyOwner {
//     require(block.timestamp < saleInfo.saleStartTime, 'CAMPAIGN: Can only alter whitelisting before Sale StartTime');
//     useWhiteList= true;
//     _whitelistTierTwoMerkleRoot=whitelistMerkleRoot;
//   }

//   // check the address is a Token Holder
//   function isAllowedInTier1(address _address) public view returns(bool) {

//     IERC20 token = IERC20(zsalesTokenAddress);
//     return token.balanceOf(_address) > 0;
//   }


//   // check the address in whitelist tier two
//   function isInTier2WhiteList(bytes32[] memory proof, address claimer) public view returns(bool) {
    
//     bytes32 _leaf = keccak256(abi.encodePacked(claimer));
//     return MerkleProof.verify(proof, _whitelistTierTwoMerkleRoot, _leaf);
    
//   }

//   /**
//     * @dev Throws if called by any account other than the owner.
//   */
//   modifier onlyAdmin() {
//       require(_admin == _msgSender(), "ADMIN: caller is not the admin");
//       _;
//   }

//   function changeAdmin(address newAdmin) public onlyAdmin  {
//       require(_msgSender() == _admin, 'ADMIN: Only Admin can change');
//       address oldOwner = _admin;
//       _admin=newAdmin;

//       emit AdminOwnershipTransferred(oldOwner, newAdmin);
//   }

  
//   function getHardCap() public view returns (uint) {
//     return saleInfo.hardCap;
//   }

//   /**************************|
//   |          Setters         |
//   |_________________________*/
//   function setKYC(bool kyc) public onlyAdmin  {
//       require(block.timestamp< saleInfo.saleStartTime, 'CAMPAIGN: Can only change KYC before Sale StartTime');
//       hasKYC= kyc;
//   } 

//   function setTier1TimeLineInHours (uint newValue) public onlyAdmin {
//     tier1TimeLineInHours=newValue;
//   }

  
//   function setAudited(bool audit) public onlyAdmin  {
//     require(block.timestamp< saleInfo.saleStartTime, 'CAMPAIGN: Can only change Audit state before Sale StartTime');
//       _isAudited= audit;
//   }
//   function isAudited() public view returns (bool, string memory ) {
//     return (_isAudited, auditUrl);
//   }


//   /**
//     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
//     * `recipient`, forwarding all available gas and reverting on errors.
//     *
//     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
//     * of certain opcodes, possibly making contracts go over the 2300 gas limit
//     * imposed by `transfer`, making them unable to receive funds via
//     * `transfer`. {sendValue} removes this limitation.
//     *
//     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
//     *
//     * IMPORTANT: because control is transferred to `recipient`, care must be
//     * taken to not create reentrancy vulnerabilities. Consider using
//     * {ReentrancyGuard} or the
//     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
//     */
//   function sendValue(address payable recipient, uint256 amount) internal {
//       require(address(this).balance >= amount, "Address: insufficient balance");

//       // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
//       (bool success, ) = recipient.call{ value: amount }("");
//       require(success, "Address: unable to send value, recipient may have reverted");
//   }

  
//   // send coin to the contract address
//   function submitBid(bytes32[] calldata proof) public payable  {
//     uint256 bid = msg.value;
//     require(status != CampaignStatus.CANCELLED, 'Campaign: Sale Cancelled');
//     require(status != CampaignStatus.FAILED , "Campaign: Failed, Refunded is activated");
//     require(status == CampaignStatus.TOKENS_SUBMITTED , "Campaign: Tokens not submitted");
//     require(totalCoinReceived < saleInfo.hardCap, 'Campaign: Sale Sold out');

//     //require(block.timestamp >= saleInfo.saleStartTime, "Campaign:The sale is not started yet "); // solhint-disable
//     require(block.timestamp <= saleInfo.saleEndTime, "Campaign:The sale is closed"); // solhint-disable
//     require(totalCoinReceived + bid <= saleInfo.hardCap, "Campaign: purchase would exceed max cap");
//     // minAllocationPerUser
    
//     require( bid >= minAllocationPerUser ,"Campaign:You are investing less than Min Buy limit!");
          
//     address sender = _msgSender();

//     if(block.timestamp >= saleInfo.saleStartTime) {
//         if(useWhiteList){          
//           require(isInTier2WhiteList(proof,sender ), "Campaign: You are not in whitelist");
//         }
//         require(totalCoinInTierTwo + bid <= tierTwohardCap, "Campaign: purchase would exceed Tier two max cap");
//         require(buyInTwoTier[sender] + bid <= maxAllocationPerUserTierTwo ,"Campaign:You are investing more than your tier-2 limit!");
//         buyInTwoTier[sender] += bid;
//         buyInAllTiers[sender] += bid;
//         totalCoinReceived += bid;
//         totalCoinInTierTwo += bid;
//         totalParticipants++;
    
//         emit ValueReceived(sender, bid);

        
//     }
//     else if (block.timestamp >= saleInfo.saleStartTime - (tier1TimeLineInHours * 1 hours ) ) {  // istokenholder and isstill in tokenholder sales part  //  isInTier1WhiteList(msg.sender)
//         require(isAllowedInTier1(msg.sender) , "Campaign: Only Tokenholders are allowed to buy in Tier 1 window");
//         require(totalCoinInTierOne + bid <= tierOnehardCap, "Campaign: purchase would exceed Tier one max cap");
//         require(buyInOneTier[msg.sender] + bid <= maxAllocationPerUserTierOne ,"Campaign:You are investing more than your tier-1 limit!");
//         buyInOneTier[msg.sender] += bid;
//         buyInAllTiers[msg.sender] += bid;
//         totalCoinReceived += bid;
//         totalCoinInTierOne += bid;
//         totalParticipants++;

//         emit ValueReceived(msg.sender, bid);

    
//     }    
//     else{
//       revert("Campaign:The sale is not started yet");
//     }

//     // return '';
//   }

//   /**
//   * @dev Withdraw tokens or coin by user after end time
//   * If this project does not reach softcap, return their funds otherwise get tokens 
//   */
//   function withdrawFunds () public   {
    
//     address usr = _msgSender();

//     require(usr!= owner(), 'CAMPAIGN: Owners cannot withdraw' );
//     // require(status.isCancelled, 'Campaign: Can only withdraw if Campaign Cancelled');

//     // if campaign is sold out no need to wait for endtime finalize and setup liquidity
//     require(block.timestamp >= saleInfo.saleEndTime || totalCoinReceived>= saleInfo.hardCap  , "CAMPAIGN: ongoing sales");

//     require(buyInAllTiers[usr] > 0, "CAMPAIGN: No COIN to claim");

//     if(totalCoinReceived < saleInfo.softCap){
//       status= CampaignStatus.FAILED ;
//     }
    
    
//     uint256 amount =  buyInAllTiers[usr];
//     buyInAllTiers[usr] = 0;
//     uint256 amountTokens =  amount * saleInfo.listRate;
    
//     if(status== CampaignStatus.FAILED){
//         // return back funds
//         payable(usr).transfer(amount);
//         emit Refunded(usr, amount);
        
//     }else{
//       IERC20 _token = IERC20(saleInfo.tokenAddress);
//       // Transfer Tokens to User
//       _token.safeTransfer(usr, amountTokens);
      
//       emit Withdrawn(usr, amountTokens);
//     }    
//   }

//   /**
//   * @dev Withdraw owner tokens If this project does not reach softcap
//   */
//   function withdrawOwnerTokens () public   onlyOwner {
    
    
//     require(status== CampaignStatus.FAILED || status== CampaignStatus.CANCELLED, 'Campaign: Can only withdraw if Campaign Cancelled or Failed');

    
//     require(block.timestamp >= saleInfo.saleEndTime , "CAMPAIGN: Can only withdraw after End date");

    
    
//     IERC20 _token = IERC20(saleInfo.tokenAddress);
//     uint256 tokensAmount = _token.balanceOf(address(this));
    
//     require(tokensAmount > 0, "CAMPAIGN: No Tokens to claim");
//     _token.safeTransfer(msg.sender, tokensAmount);
//   }

//   /**
//     * Setup liquidity and transfer all amounts according to defined percents, if softcap not reached set Refunded flag
//     */
//   function finalizeAndSetupLiquidity() public nonReentrant {
//     require(totalCoinReceived>= saleInfo.hardCap || block.timestamp > saleInfo.saleEndTime , "Campaign: not sold out or time not elapsed yet" );
//     require(status != CampaignStatus.FAILED, "CAMPAIGN: campaign will be refunded");
//     require(status != CampaignStatus.CANCELLED, "CAMPAIGN: campaign was cancelled");
//     //
//     if(totalCoinReceived < saleInfo.softCap){ // set to failed and stop
//         status= CampaignStatus.FAILED ;
//         return;
//     }

    
//     IERC20 _token = IERC20(saleInfo.tokenAddress);

    
//     uint256 currentCoinBalance = address(this).balance;
//     require(currentCoinBalance > 0, "CAMPAIGN: Coin balance needs to be above zero" );
//     uint256 liquidityAmount = (currentCoinBalance * saleInfo.liquidityPercent) / 10000;
//     uint256 tokensAmount = _token.balanceOf(address(this));
//     require(tokensAmount >= liquidityAmount * saleInfo.dexListRate  , "CAMPAIGN: Not sufficient tokens amount");
    

//     uint256 zsaleFeeAmount = currentCoinBalance * zsaleFee / 10000;
//     uint256 zsaleTokenFeeAmount = currentCoinBalance * zsaleTokenFee/ 10000;
    
//     //Fees
//     payable(zsalesWalletAddress).transfer(zsaleFeeAmount);
//     _token.safeTransfer(zsalesWalletAddress, zsaleTokenFeeAmount);
//     // payable(_teamWallet).transfer(teamAmount);

    
//     //liquidity pair
//     // payable(_dexLockerAddress).transfer(liquidityAmount);
//     (bool success,) = _dexLockerAddress.call{ value: liquidityAmount }("");
//     require(success, "CAMPAIGN: Transfer to DExLocker failed");//use call , since dexlocker is a proxy
    
//     _token.safeTransfer(_dexLockerAddress, liquidityAmount * saleInfo.dexListRate );

//     DexLocker locker = DexLocker(_dexLockerAddress);    
//     if(useRaisedFundsVesting){
//       locker.startRaisedFundsLock( totalCoinReceived );
//     }
//     locker.addLiquidity(currentCoinBalance);
    
//     status=CampaignStatus.LIQUIDITY_SETUP;
//   }

  
//   function getCampaignInfo() public view returns( uint256 softcap, uint256 hardcap,uint256 saleStartTime, uint256 saleEndTime,uint256 listRate, uint256 dexListRate, uint liquidity,uint _liquidityReleaseTime ,uint256 totalCoins, uint256 totalParticipant, bool useWhiteList, bool hasKyc, bool isAuditd ){
//       return ( saleInfo.softCap, saleInfo.hardCap,saleInfo.saleStartTime, saleInfo.saleEndTime, saleInfo.listRate, saleInfo.dexListRate, saleInfo.liquidityPercent, liquidityReleaseTime, totalCoinReceived,totalParticipants, useWhiteList,hasKYC, _isAudited );
//   }

  

//   function getCampaignStatus() public view returns(CampaignStatus ){
//       return status ;
//   }

//   function getCampaignPeriod() public view returns(uint256 saleStartTime, uint256 saleEndTime ){
//       return (saleInfo.saleStartTime, saleInfo.saleEndTime );
//   }

//   function getCampaignSalePriceInfo() public view returns(uint256 , uint256,uint256 , uint256,uint256 , uint256,uint256 ){
//       return (saleInfo.listRate, saleInfo.dexListRate, saleInfo.softCap, saleInfo.hardCap, tierOnehardCap,tierTwohardCap, maxAllocationPerUserTierTwo  );
//   }

//   /**
//     * 
//     */
//   function isSoldOut() public view returns (bool) {
//       return totalCoinReceived>= saleInfo.hardCap;
//   }

//     /**
//     * 
//     */
//   function hasFailed() public view returns (bool) {
//       return status == CampaignStatus.FAILED;
//   }

  
//   function dexLockerAddress() public view onlyAdmin returns (address) {
//       return _dexLockerAddress;
//   }

//   function tokenAddress() public view returns (address) {
//       return saleInfo.tokenAddress;
//   }

//   // Refund any mistakenly sent in ERC20
//   function refundERC20(IERC20 _token, address recipient, uint256 amount) public onlyAdmin {
      
//     _token.safeTransfer(recipient, amount);
//   }

// }