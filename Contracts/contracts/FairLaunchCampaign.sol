// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.28;

// import "@openzeppelin/contracts/utils/Context.sol";
// // import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// // import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

// import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
// // import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

// import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import './Lockers/DexLockerFactory.sol';
// import {IDexLocker} from './Lockers/DexLocker.sol';
// // import './Lockers/TokenLocker.sol';
// import "./Lockers/VestSchedule.sol";
// import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
// import "hardhat/console.sol";
// import {IDexRouter, IDexFactory} from "./IDexRouter.sol";
// import {ICampaignList} from "./CampaignList.sol";
// import {PlatFormDetails} from "./Campaign.sol";
// import "./Errors.sol";

// contract FairLaunchCampaign is Initializable,Ownable, ReentrancyGuard {
//   using SafeERC20 for IERC20;
//   error InsufficientBalance();
//   error NoSendValue();

//   uint256 constant private MAX_INT = 2**256 - 1;

//   event AdminOwnershipTransferred(address indexed previousAdmin, address indexed newAdmin);
//   event ValueReceived(address user, uint amount);
//   event Withdrawn(address user, uint amount);
//   event Refunded(address user, uint amount);
//   event SoldOut();
//   event LiquidityAddedToRouter(address indexed router, address indexed token1,address indexed token2, uint amountToken1, uint amountToken2);

//   struct CampaignSaleInfo {
//       //token attributes
//       address   tokenAddress; 
//       uint256  softCap; // Soft cap in coin
//       uint256  hardCap; // Max cap in coin
//       uint256  saleStartTime; // start sale time
//       uint256  saleEndTime; // end sale time
//       uint   liquidityPercent; // multiplied by 100 e.g 45% is 4500
//       uint   tokensOnSale; 
//       // RefundType  refundType;
//       string logoUrl;
//       string desc;
//       string website;
//       string twitter;
//       string telegram;
//       string discord;
//       // string bannerImage;
      
//   }

//   enum CampaignStatus{ 
//     CREATED,
//     TOKENS_SUBMITTED,//Owner has transferred the correct no of tokens and campaign is ready to receive
//     CANCELLED, // Cancelled before the start date
    
//     FAILED, // WIll need refund
//     LIQUIDITY_SETUP

//   }

//   bool   public useWhiteList;//Use in only Tier 2
//   bool   public hasKYC;
//   uint public totalTeamTokensToBeVested=0;
//   bool _isAudited; 
//   string public auditUrl;
//   CampaignStatus public  status = CampaignStatus.CREATED;

//   address public liquidityPairAddress;
//   address public liquidityPairLockerAddress;

  
  
  
//   CampaignSaleInfo public  saleInfo;
  
  
//   address public dexRouterAddress;
//   uint256 public totalCoinReceived; // total  received
//   uint256 public totalCoinInTierZero;
//   uint256 public totalCoinInTierOne; // total coin for tier one
//   uint256 public totalCoinInTierTwo; // total coin for tier Tier

//   address public purchaseTokenAddress=address(0); // Token address for Purchases for this campaign - address 0 is native currency
  

//   uint public totalParticipants; // total participants in ido
  

//   PlatFormDetails zsalesPlatformDetails;
//   // address private _admin= 0xB7e16f5fa9941B84baCd1601F277B00911Aed339; //zsales admin - can setkyc and audited
//   // address public zsalesTokenAddress = 0x97CEe927A48dc119Fd0b0b1047a879153975e893;
//   // uint zsaleFee = 200;  //2%   - percent of native currency to take
//   // uint zsaleTokenFee = 200;  //2% - percent fee of token to take

//   // address public zsalesNFTTokenAddress = 0x97CEe927A48dc119Fd0b0b1047a879153975e893;
//   // address zsalesWalletAddress = 0xB7e16f5fa9941B84baCd1601F277B00911Aed339 ; // receives commissions
//   address public _campaignFactoryAddress ;

//   uint private tier1TimeLineInHours = 2; // e.g 2 hours before startime
//   uint private tier0TimeLineInHours = 3;

//   bool private ownerHasWithdrawnTokens=false;
  
//   // max cap per tier
//   uint public tierZerohardCap;
//   uint public tierOnehardCap;
//   uint public tierTwohardCap;
    
//   //total users per tier
//   // uint public totalUserInTierZero;
//   // uint public totalUserInTierOne;
//   // uint public totalUserInTierTwo;
  
//   bool public useTokenVesting;
//   bool public useRaisedFundsVesting;


//   //Tier 0 - holders of our NFT
//   //Tier 1 - holders of our coin
//   //Tier 2 - Whitelisted or public   
//   uint public minAllocationPerUser;
//   //max allocations per user in a tier
//   uint public maxAllocationPerUserTierZero;
//   uint public maxAllocationPerUserTierOne;
//   uint public maxAllocationPerUserTierTwo; 
  
 
//   // // address array for tier one whitelist
//   // address[] private whitelistTierOne;  // every tokenholder is automatically whitelisted
  
//   // // address array for tier two whitelist
//   // address[] private whitelistTierTwo; 

//   bytes32 private _whitelistTierTwoMerkleRoot;
  

//   uint public campaignKey;
//   // enum RefundType{ BURN, REFUND }
  
//   uint256 public liquidityReleaseInDays; // days to release Lp tokens to owner

//   //mapping the user purchase per tier
//   mapping(address => uint) public buyInZeroTier;
//   mapping(address => uint) public buyInOneTier;
//   mapping(address => uint) public buyInTwoTier;
//   mapping(address => uint) public buyInAllTiers;
//   DexLockerFactory private _dexLockerFactory;
  
//   IDexLocker public _dexLocker;
//   uint private tokenDecimals;
//   uint private purchaseCoinDecimals;
  

//   ///Do not leave an implementation contract uninitialized. An uninitialized implementation contract can be taken over by an attacker, which may impact the proxy. 
//   /// To prevent the implementation contract from being used, you should invoke the _disableInitializers function in the constructor to automatically lock it when it is deployed
//   /// @custom:oz-upgrades-unsafe-allow constructor
//   constructor() Ownable(msg.sender) {
//       _disableInitializers();
//   }

//   function initialize(
    
//     /** address campaignOwner,
//     /* address campaignFactory,
//     /* address  _saletokenAddress, */
//     /* address  _purchaseTokenAddress, */
//     address[4] memory addresses,

//     uint tokensOnSale,

//     /** uint256 _normalizedTo18DecimalsSoftCap,
//      * uint256 __normalizedTo18DecimalsHardCap,
//      * uint256 _saleStartTime,
//      * uint256 _saleEndTime, 
//      * uint256 _nomrlaizedTierOneHardCap, 
//      * uint256 _nomrlaizedTierTwoHardCap,
//      * uint _minAllocationPerUser, 
//      * uint256 _maxAllocationPerUserTierOne, 
//      * uint256 _maxAllocationPerUserTierTwo ,
//      * uint _campaignKey,*/
//     uint256[10] memory capAndDate,  
    
//     // RefundType _refundType, 
//     address _dexRouterAddress,

//     /**uint _liquidityPercent, 
//     /* uint liquidityReleaseTime,
//     /* uint _listRate, 
//     /* uint _dexListRate,**/
//     uint[4] memory liquidityAllocationAndRates,

//     /**uint totalTeamTokensToBeVested, 
//     /* uint firstReleasePercent,  
//     /* uint firstReleaseDays,
//     /* uint subsequentReleasePercent, 
//     /* uint subsequentReleaseDays,,**/
//     uint256[5] memory teamTokenVestingDetails,

//     uint256[3] memory raisedFundVestingDetails,
    
//     // UseTeamTokenVesting,
//     // UseRaisedFundVesting
//     bool[2] memory _useTokenOrRaisedFundVesting,
//     // VestSchedule[8] memory teamTokenVestingDetails, 

    
//     string[6] memory founderInfo,
//     DexLockerFactory dexLockerFactory 
//   ) public payable initializer {

//     {
//       // require(capAndDate[3] > capAndDate[2], "Sale End time needs to be above start time");
//       // require(liquidityAllocationAndRates[0] >= 5100, "Liquidity allowed is > 51 %");
//       if (capAndDate[3] <= capAndDate[2]) revert SaleEndTimeBeforeStartTime();
//       if (liquidityAllocationAndRates[0] < 5100) revert LiquidityAboveLimit(5100);

//       _campaignFactoryAddress= addresses[1];
//       _setDefaultValues();
//       campaignKey=capAndDate[9];
      
//       _dexLockerFactory=dexLockerFactory;
//       purchaseTokenAddress=addresses[3]; 
//     }
    
      
//     // //block scopin to avoid stack too deep 
//     {
     
//       saleInfo = CampaignSaleInfo({
//         tokenAddress: addresses[2],
//         softCap: capAndDate[0],
//         hardCap: capAndDate[1],
//         saleStartTime: capAndDate[2], 
//         saleEndTime: capAndDate[3],   
//         liquidityPercent: liquidityAllocationAndRates[0],
//         tokensOnSale: tokensOnSale,
//         // refundType: _refundType, 
//         logoUrl: founderInfo[0],
//         desc: founderInfo[1],
//         website: founderInfo[2],
//         twitter: founderInfo[3],
//         telegram: founderInfo[4],
//         discord: founderInfo[5]
//       });

//       dexRouterAddress=_dexRouterAddress; 
//     }        
    
    
    
//     { 
//           // _updateTierDetails(capAndDate[4], capAndDate[5], capAndDate[6],capAndDate[7], capAndDate[8]);
//       _updateTierDetails(capAndDate);
    

//       _transferOwnership(addresses[0]);
      

//       _updateLockDetails(liquidityAllocationAndRates[1], _useTokenOrRaisedFundVesting[0], teamTokenVestingDetails,_useTokenOrRaisedFundVesting[1], raisedFundVestingDetails );
//     }
    
//   }

//   //needed since initializable contracts do not have constructors
//   function _setDefaultValues() private {
//     //status = CampaignStatus.CREATED;
//     tier0TimeLineInHours = 3; // e.g 3 hours before startime
//     tier1TimeLineInHours = 2; // e.g 2 hours before startime

    
//     ICampaignList cList = ICampaignList(_campaignFactoryAddress);
//     zsalesPlatformDetails= PlatFormDetails({
//       admin: cList.zsalesAdmin(), //zsales admin - can setkyc and audited
//       zsalesTokenAddress : cList.zsalesTokenAddress(),
//       zsaleFee : cList.zsaleFee(),  //2%   - percent of native currency to take
//       zsaleTokenFee : cList.zsaleTokenFee(),  //2% - percent fee of token to take
//       zsalesWalletAddress : cList.zsalesWalletAddress(), // receives commissions      
//       zsalesNFTTokenAddress: cList.zsalesNFTTokenAddress()
//     });
//     // _admin= cList.zsalesAdmin(); //zsales admin - can setkyc and audited
//     // zsalesTokenAddress = cList.zsalesTokenAddress();
//     // zsaleFee = cList.zsaleFee();  //2%   - percent of native currency to take
//     // zsaleTokenFee = cList.zsaleTokenFee();  //2% - percent fee of token to take
//     // zsalesWalletAddress = cList.zsalesWalletAddress() ; // receives commissions
    
//     // zsalesNFTTokenAddress= cList.zsalesNFTTokenAddress();
//   }
  
//   // function to update other details not initialized in constructor - this is bcos solidity limits how many variables u can pass in at once
//   function _updateLockDetails(
//     uint liquidityReleaseTimeDays, //Time to add to startTime in days
//     bool _useTokenVesting,
//     uint256[5] memory teamTokenVestingDetails,
//     bool _useRaisedFundsVesting, 
//     uint256[3] memory raisedFundVestingDetails
      
//   ) private /*public onlyOwner*/ {
//     liquidityReleaseInDays  = liquidityReleaseTimeDays;
//     useTokenVesting=_useTokenVesting;
//     useRaisedFundsVesting=_useRaisedFundsVesting;

    
//     //Set dexLock
//     _dexLocker = IDexLocker(payable(_dexLockerFactory.createDexLocker(dexRouterAddress,saleInfo.tokenAddress, purchaseTokenAddress, address(this), msg.sender) ) );
    
    
//     _dexLocker.setupLock([saleInfo.softCap,saleInfo.hardCap],  [uint256(0),uint256(0)],useTokenVesting, teamTokenVestingDetails, _useRaisedFundsVesting,  raisedFundVestingDetails);
    
//     status = CampaignStatus.CREATED;
//     totalTeamTokensToBeVested = teamTokenVestingDetails[0];
    

//     // //if doesnt use tokenvesting , _startReceivingBids();
//     // if(!useTokenVesting){
//     //   _startReceivingBids();
//     // }

    

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
//     if (block.timestamp > saleInfo.saleStartTime) revert UpdateAfterSaleStartTime();
//     _updateCampaignFounderDetails(logoUrl,desc,website,twitter,telegram,discord);
//   }

//   function _updateTierDetails(uint256[10] memory capAndDate) private {
    
//     _updateTierDetails(capAndDate[4], capAndDate[5], capAndDate[6],capAndDate[7], capAndDate[8]);
//   }
    
//   // function to update the tiers users value manually
//   function _updateTierDetails(uint256 _tierOneHardCap, uint256 _tierTwoHardCap, uint256 _minAllocationPerUser, uint256 _maxAllocationPerUserTierOne, uint256 _maxAllocationPerUserTierTwo) private {
    
//     tokenDecimals = IERC20Metadata(saleInfo.tokenAddress).decimals();
//     purchaseCoinDecimals=18;
//     if(purchaseTokenAddress!=address(0)){
//       purchaseCoinDecimals = IERC20Metadata(purchaseTokenAddress).decimals();
//     }
    
//     if (_tierOneHardCap < saleInfo.hardCap * 2500 / 10000) revert TierCapTooLow(25);
//     // if (_tierOneHardCap + _tierTwoHardCap != saleInfo.hardCap) revert TierCapsExceedHardCap();
//     if (_tierOneHardCap > saleInfo.hardCap) revert TierOneCapExceedsHardCap();
//     if (_tierTwoHardCap > saleInfo.hardCap) revert TierTwoCapExceedsHardCap();

//     if (_minAllocationPerUser < 0) revert MinAllocationOutOfRange();
//     if (_maxAllocationPerUserTierOne <= 0) revert TierOneMaxAllocationOutOfRange();
//     if (_maxAllocationPerUserTierTwo <= 0) revert TierTwoMaxAllocationOutOfRange();
    
    
//     tierZerohardCap = _tierOneHardCap;
//     tierOnehardCap =_tierOneHardCap;
//     tierTwohardCap = _tierTwoHardCap;    
    
//     minAllocationPerUser=_minAllocationPerUser; 
//     maxAllocationPerUserTierZero = _maxAllocationPerUserTierOne;//same alloc for tier 0 and 1
//     maxAllocationPerUserTierOne = _maxAllocationPerUserTierOne;
//     maxAllocationPerUserTierTwo = _maxAllocationPerUserTierTwo;
//   }

//   function updateTierDetails(uint256 _tierOneHardCap, uint256 _tierTwoHardCap, uint256 _minAllocationPerUser, uint256 _maxAllocationPerUserTierOne, uint256 _maxAllocationPerUserTierTwo) public onlyOwner {
    
//     if(block.timestamp > saleInfo.saleStartTime){
//       revert UpdateAfterSaleStartTime();
//     }
//     _updateTierDetails(_tierOneHardCap, _tierTwoHardCap, _minAllocationPerUser, _maxAllocationPerUserTierOne, _maxAllocationPerUserTierTwo);    
//   }

//   function _startReceivingBids() private 
//   {    
//     status = CampaignStatus.TOKENS_SUBMITTED;
//   }

//   function startReceivingBids() public {
//     if (_campaignFactoryAddress != _msgSender()) revert NotOwner();
//     _startReceivingBids();
//   }

//   function cancelCampaign() public onlyOwner {
//       if (block.timestamp >= saleInfo.saleStartTime) revert CannotCancelAfterSaleStartTime();
//       status = CampaignStatus.CANCELLED;
//   }

//   function calcFairLaunchRate() public view returns (uint256 tokenRate) {
//     uint256 balance = purchaseTokenAddress==address(0) ? (address(this).balance) : IERC20(purchaseTokenAddress).balanceOf(address(this));
//     tokenRate = 10 ** 18 / balance * saleInfo.tokensOnSale;
//   }

//   function postponeSale(uint newDate, uint newEndDate) public onlyOwner {
//       if (block.timestamp >= saleInfo.saleStartTime) revert PostponeBeforeSaleStartTime();
//       if (newDate <= saleInfo.saleStartTime) revert NewDateLessThanOldDate();
//       if (newEndDate <= newDate) revert EndDateLessThanStartTime();

//       saleInfo.saleStartTime = newDate;
//       saleInfo.saleEndTime = newEndDate;
//   }

//   function getDexListRate() public view returns (uint256) {
//     return 0;
//   }

//   function getEndDate() public view returns (uint256) {
//     return saleInfo.saleEndTime;
//   }

//   function totalTokensExpectedToBeLocked() public view returns (uint256) {
//     //Amount for sale + amount for liquidity
//     uint tokensForLiquidity = (saleInfo.tokensOnSale * saleInfo.liquidityPercent )  / 10000;
//     return tokensForLiquidity ;// + _dexLocker.totalTokensExpectedToBeLocked();
//   }

 
//   function setZSalesTokenAddress(address _tokenAddress) public onlyAdmin {
//     zsalesPlatformDetails.zsalesTokenAddress = _tokenAddress;
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
    
//     if (block.timestamp >= saleInfo.saleStartTime) revert AlterWhitelistingAfterSaleStartTime();
//     useWhiteList= true;
//     _whitelistTierTwoMerkleRoot=whitelistMerkleRoot;
//   }

//   // check the address is a Token Holder
//   function isAllowedInTier1(address _address) public view returns(bool) {

//     IERC20 token = IERC20(zsalesPlatformDetails.zsalesTokenAddress);
//     return token.balanceOf(_address) > 0;
//   }

//   // check the address is a NFT Token Holder
//   function isAllowedInTier0(address _address) public view returns(bool) {

//     uint maxTiersToCheck= 5;
//     IERC1155 token = IERC1155(zsalesPlatformDetails.zsalesNFTTokenAddress);
//     address[] memory addresses=new address[](maxTiersToCheck);
//     addresses[0]=_address;

//     uint[] memory tokenIds=new uint[](maxTiersToCheck);
    
//     for (uint256 i = 0; i < maxTiersToCheck; i++) {
//         tokenIds[i]=i;
//     }

//     uint[] memory balances = token.balanceOfBatch(addresses,tokenIds) ;
//     uint balance = 0;
//     for (uint256 i = 0; i < maxTiersToCheck; i++) {
//         balance += balances[i];
//     }
//     return balance>0;
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
//       require(zsalesPlatformDetails.admin == _msgSender(), NotAdmin() );
//       _;
//   }

//   function changeAdmin(address newAdmin) public onlyAdmin  {
//       // require(_msgSender() == _admin, 'ADMIN: Only Admin can change');
//       if(_msgSender() != zsalesPlatformDetails.admin) revert NotAdmin();
//       address oldOwner = zsalesPlatformDetails.admin;
//       zsalesPlatformDetails.admin=newAdmin;

//       emit AdminOwnershipTransferred(oldOwner, newAdmin);
//   }

  
//   function getHardCap() public view returns (uint) {
//     return saleInfo.hardCap;
//   }

//   /**************************|
//   |          Setters         |
//   |_________________________*/
  
//   function setKYC(bool kyc) public onlyAdmin {
//     if (block.timestamp >= saleInfo.saleStartTime) revert KYCAfterSaleStartTime();
//     hasKYC = kyc;
//   } 

//   function setAudited(bool audit) public onlyAdmin {
//       if (block.timestamp >= saleInfo.saleStartTime) revert AuditAfterSaleStartTime();
//       _isAudited = audit;
//   }
//   function setTier1TimeLineInHours (uint newValue) public onlyAdmin {
//     tier1TimeLineInHours=newValue;
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
//   function sendValue(address recipient, uint256 amount) internal {
//       require(address(this).balance >= amount, InsufficientBalance());

//       // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
//       (bool success, ) = recipient.call{ value: amount }("");
//       require(success, NoSendValue());//Address: unable to send value, recipient may have reverted
//   }
  
  
//   // send coin to the contract address
//   function submitBid(bytes32[] calldata proof, uint256 purchasedAmount) public payable nonReentrant  {
    
//     uint256 normalizedBid ;
//     if(purchaseTokenAddress==address(0)){
//       normalizedBid= msg.value;
//     }else{
//       normalizedBid= purchasedAmount * 10**(18-purchaseCoinDecimals);//normalize
//       IERC20(purchaseTokenAddress).safeTransferFrom(msg.sender, address(this), purchasedAmount);
//     }
    
    
//     if (status == CampaignStatus.CANCELLED) revert SaleCancelled();
//     if (status == CampaignStatus.FAILED) revert SaleFailed();
//     if (status != CampaignStatus.TOKENS_SUBMITTED) revert NotTokenSubmitted();
//     if (totalCoinReceived >= saleInfo.hardCap) revert SoldOutError();
//     if (block.timestamp > saleInfo.saleEndTime) revert ClosedSale();
//     if (totalCoinReceived + normalizedBid > saleInfo.hardCap) revert ExceedMaxCap();
//     if (normalizedBid < minAllocationPerUser) revert LessThanMinBuy();
    
          
//     address sender = _msgSender();
//     if (block.timestamp >= saleInfo.saleStartTime) {
//         if (useWhiteList) {
//             if (!isInTier2WhiteList(proof, sender)) revert NotInTier2Whitelist();
//         }
//         if (totalCoinInTierTwo + normalizedBid > tierTwohardCap) revert ExceedTierTwoMaxCap();
//         if (buyInTwoTier[sender] + normalizedBid > maxAllocationPerUserTierTwo) revert ExceedTierTwoUserLimit();
//         buyInTwoTier[sender] += normalizedBid;
//         buyInAllTiers[sender] += normalizedBid;
//         totalCoinReceived += normalizedBid;
//         totalCoinInTierTwo += normalizedBid;
//         totalParticipants++;

//         emit ValueReceived(sender, purchasedAmount);
//     } else if (ICampaignList(_campaignFactoryAddress).getTierStatus(0) && block.timestamp >= saleInfo.saleStartTime - (tier0TimeLineInHours * 1 hours)) {  
//         if (!isAllowedInTier0(sender)) revert NotInTier0();
//         if (totalCoinInTierZero + normalizedBid > tierZerohardCap) revert ExceedTierZeroMaxCap();
//         if (buyInZeroTier[sender] + normalizedBid > maxAllocationPerUserTierZero) revert ExceedTierZeroUserLimit();
//         buyInZeroTier[sender] += normalizedBid;
//         buyInAllTiers[sender] += normalizedBid;
//         totalCoinReceived += normalizedBid;
//         totalCoinInTierZero += normalizedBid;
//         totalParticipants++;

//         emit ValueReceived(sender, purchasedAmount);
//     } else if (ICampaignList(_campaignFactoryAddress).getTierStatus(1) && block.timestamp >= saleInfo.saleStartTime - (tier1TimeLineInHours * 1 hours)) {  
//         if (!isAllowedInTier1(sender)) revert NotInTier1();
//         if (totalCoinInTierOne + normalizedBid > tierOnehardCap) revert ExceedTierOneMaxCap();
//         if (buyInOneTier[sender] + normalizedBid > maxAllocationPerUserTierOne) revert ExceedTierOneUserLimit();
//         buyInOneTier[sender] += normalizedBid;
//         buyInAllTiers[sender] += normalizedBid;
//         totalCoinReceived += normalizedBid;
//         totalCoinInTierOne += normalizedBid;
//         totalParticipants++;

//         emit ValueReceived(sender, purchasedAmount);
//     } else {
//         revert SaleNotStarted();
//     }

    

//     // return '';
//   }

//   /**
//   * @dev Withdraw tokens or coin by user after end time
//   * If this project does not reach softcap, return their funds otherwise get tokens 
//   */
//   function withdrawFunds() public {
//     address usr = _msgSender();

//     if (usr == owner()) revert OwnersCannotWithdraw();
    
//     // if campaign is sold out no need to wait for endtime finalize and setup liquidity
//     if (block.timestamp < saleInfo.saleEndTime && totalCoinReceived < saleInfo.softCap) revert OngoingSales();
    
//     if (buyInAllTiers[usr] == 0) revert NoCoinsToClaim();

//     // if (totalCoinReceived < saleInfo.softCap) {
//     //     status = CampaignStatus.FAILED;
//     // }

//     uint256 amount = buyInAllTiers[usr];
//     buyInAllTiers[usr] = 0;
    

//     if (status == CampaignStatus.FAILED) {
//       // return back funds
//       if(purchaseTokenAddress==address(0)){
//         payable(usr).transfer(amount);
//       }else{
//         IERC20(purchaseTokenAddress).safeTransfer(usr, amount/10**(18-purchaseCoinDecimals));
//       }          
//       emit Refunded(usr, amount/10**(18-purchaseCoinDecimals));
//     } else {
//         uint256 amountTokens = amount * calcFairLaunchRate();
//         IERC20 _token = IERC20(saleInfo.tokenAddress);
//         // Transfer Tokens to User
//         _token.safeTransfer(usr, amountTokens/10**(18-tokenDecimals));

//         emit Withdrawn(usr, amountTokens/10**(18-tokenDecimals));
//     }    
//   }

//   /**
//   * @dev Withdraw owner tokens If this project does not reach softcap
//   */
 

//   function withdrawOwnerTokens() public onlyOwner {
//       if (status != CampaignStatus.FAILED && status != CampaignStatus.CANCELLED && status != CampaignStatus.LIQUIDITY_SETUP) revert RequireCancelorFail();
//       if (block.timestamp < saleInfo.saleEndTime) revert NotEndDate();
//       if(ownerHasWithdrawnTokens) revert OwnerHasWithdrawnAlready();

//       if(totalCoinReceived < saleInfo.softCap){
//         status= CampaignStatus.FAILED;
//       }

//       IERC20 _token = IERC20(saleInfo.tokenAddress);
//       //if (totalCoinReceived >= saleInfo.softCap ) revert AlreadyReachedSoftCap(saleInfo.softCap);
//       if(status == CampaignStatus.FAILED || status == CampaignStatus.CANCELLED){
        
//         uint256 tokensAmount = _token.balanceOf(address(this));

//         if (tokensAmount == 0) revert NoTokens();
//         ownerHasWithdrawnTokens=true;
//         _token.safeTransfer(msg.sender, tokensAmount);


//       }else if(status == CampaignStatus.LIQUIDITY_SETUP){
//         // // Todo
//         // uint tokensForUsers = saleInfo.tokensOnSale ;
//         // uint tokensForLiquidity = tokensForUsers *  saleInfo.liquidityPercent/10000;
//         // uint tokensForFees =zsalesPlatformDetails.zsaleTokenFee * tokensForUsers / 10000;

//         // uint withdrawableTokens  = (tokensForLiquidity + tokensForUsers + tokensForFees )/ 10**(18-tokenDecimals);
//         // ownerHasWithdrawnTokens=true;

//         // _token.safeTransfer(msg.sender, withdrawableTokens);
//         uint256 tokensAmount = _token.balanceOf(address(this));

//         if (tokensAmount == 0) revert NoTokens();
//         ownerHasWithdrawnTokens=true;
//         _token.safeTransfer(msg.sender, tokensAmount);
//       }
      
//   }

  
  

//   /**
//     * Setup liquidity and transfer all amounts according to defined percents, if softcap not reached set Refunded flag
//     */
//   function finalizeAndSetupLiquidity() public nonReentrant {
    
//     require (totalCoinReceived >= saleInfo.hardCap || block.timestamp > saleInfo.saleEndTime, NoSoldOutOrEndDate());
//     if (status == CampaignStatus.FAILED) revert CampaignFailed();
//     if (status == CampaignStatus.CANCELLED) revert CampaignCancelled();
//     if (status == CampaignStatus.LIQUIDITY_SETUP) revert LiquiditySetupAlreadyDone();
//     //
//     if(totalCoinReceived < saleInfo.softCap){ // set to failed and stop
//         status= CampaignStatus.FAILED ;
//         return;
//     }

    
//     IERC20 tokenOnSale = IERC20(saleInfo.tokenAddress);

//     // Total amount invested
//     uint256 currentCoinBalance = address(this).balance;
//     if(purchaseTokenAddress!=address(0)){
//       currentCoinBalance = IERC20(purchaseTokenAddress).balanceOf(address(this));
//     }

//     if(currentCoinBalance<=0 || (totalCoinReceived/ 10**(18-purchaseCoinDecimals)) > currentCoinBalance ){
//        revert NoCoin();
//     }
    

//     uint256 zsaleFeeAmount = (totalCoinReceived * zsalesPlatformDetails.zsaleFee / 10000) / 10**(18-purchaseCoinDecimals);
    
//     uint256 sold_tokens_amount = calcFairLaunchRate() * totalCoinReceived / 10 ** (18 - tokenDecimals);
//     uint256 zsaleTokenFeeAmount = (sold_tokens_amount * zsalesPlatformDetails.zsaleTokenFee/ 10000); // /10**(18 -tokenDecimals);
    
//     //Fees charged in Purchase coin
//     if(purchaseTokenAddress==address(0)){
//       payable(zsalesPlatformDetails.zsalesWalletAddress).transfer(zsaleFeeAmount);
//     }else{
//       IERC20(purchaseTokenAddress).safeTransfer(zsalesPlatformDetails.zsalesWalletAddress, zsaleFeeAmount);
//     }
//     // //Fee charged in Token listed, 
//     tokenOnSale.safeTransfer(zsalesPlatformDetails.zsalesWalletAddress, zsaleTokenFeeAmount);


//     uint256 supplyAfterFees = purchaseTokenAddress==address(0) ? address(this).balance : IERC20(purchaseTokenAddress).balanceOf(address(this));
//     //Amount of Token to be sent to dex
//     if(purchaseTokenAddress!=address(0)){
//       supplyAfterFees = supplyAfterFees * (10 ** (18 - purchaseCoinDecimals));
//     }
    
//     uint256 tokensBalance =  tokenOnSale.balanceOf(address(this)) * (10 ** (18 - tokenDecimals));
//     // Amount to be sent to dex
//     uint256 liquidityAmount = (supplyAfterFees * saleInfo.liquidityPercent) / 10000;
//     if(tokensBalance < liquidityAmount * calcFairLaunchRate() ) revert NoTokensForLiquidity();

//     uint256 tokensForLiquidity = liquidityAmount * calcFairLaunchRate() / (10 ** (18 - tokenDecimals)); 
//     bool approvalSucess = tokenOnSale.approve(dexRouterAddress, tokensForLiquidity);
//     require(approvalSucess == true, RouterApprovalFailed());

    
//     IDexRouter _dexRouter=IDexRouter(dexRouterAddress);
//     if(purchaseTokenAddress==address(0)){
      
//       _dexRouter.addLiquidityETH{value: liquidityAmount}(
//             saleInfo.tokenAddress,
//             tokensForLiquidity,
//             0, // tokensForLiquidity,
//             0, //liquidityAmount,
//             address(this),
//             block.timestamp + 100
//       );
      
//       emit LiquidityAddedToRouter(dexRouterAddress, address(0),saleInfo.tokenAddress,liquidityAmount,tokensForLiquidity  );

//     }else{
      
//       tokenOnSale.approve(dexRouterAddress, MAX_INT);
      
//       IERC20(purchaseTokenAddress).approve(dexRouterAddress, MAX_INT);
//       _dexRouter.addLiquidity(
//           address(tokenOnSale),
//           purchaseTokenAddress,
//           tokensForLiquidity,
//           liquidityAmount/(10** (18-purchaseCoinDecimals)),
//           0,
//           0,            
//           address(this),
//           block.timestamp + 100
//       );
//       emit LiquidityAddedToRouter(dexRouterAddress, purchaseTokenAddress,address(tokenOnSale),liquidityAmount,tokensForLiquidity  );

//     }

        
//     // get lp address from factory
//     IDexFactory _dexFactory = IDexFactory(_dexRouter.factory());
//     liquidityPairAddress = _dexFactory.getPair(saleInfo.tokenAddress, purchaseTokenAddress==address(0)?_dexRouter.WETH(): purchaseTokenAddress );
//     uint lpPairbalance=IERC20(liquidityPairAddress).balanceOf(address(this));
//     liquidityPairLockerAddress = _dexLocker.lockERC20(liquidityPairAddress, owner(),lpPairbalance, 100,liquidityReleaseInDays,0,0);// address(tokenLocker);
    
//     IERC20(liquidityPairAddress).safeTransfer(liquidityPairLockerAddress, lpPairbalance);

//     uint256 balanceAfterLiquidityAndFees = purchaseTokenAddress==address(0) ? address(this).balance : IERC20(purchaseTokenAddress).balanceOf(address(this));
//     if(useRaisedFundsVesting){
//       //send raised funds to Lock
//       // Remainder after all dedeuctions and liquidity
//       if(purchaseTokenAddress==address(0)){
        
//         _dexLocker.startRaisedFundsLock{value: (_dexLocker.raisedFundsPercent() * balanceAfterLiquidityAndFees) / 10000 }( balanceAfterLiquidityAndFees );
        
//       }else{
//         IERC20(purchaseTokenAddress).safeTransfer(address(_dexLocker),(_dexLocker.raisedFundsPercent() * balanceAfterLiquidityAndFees) / 10000);
//         _dexLocker.startRaisedFundsLock( balanceAfterLiquidityAndFees );
//       }
//     }  

//     // Send Balance to Owner
//     if(purchaseTokenAddress==address(0)){
//       sendValue(owner(),address(this).balance);      
//     }else{
//       IERC20(purchaseTokenAddress).safeTransfer(owner(),IERC20(purchaseTokenAddress).balanceOf(address(this)) );
      
//     }  
    
//     status=CampaignStatus.LIQUIDITY_SETUP;
//   }

  
//   function getCampaignInfo() public view returns( uint256 softcap, uint256 hardcap,uint256 saleStartTime, uint256 saleEndTime,uint256 listRate, uint256 dexListRate,uint tokensOnSale, uint liquidity,uint _liquidityReleaseTime ,uint256 totalCoins, uint256 totalParticipant, bool use_WhiteList, bool hasKyc, bool isAuditd, string memory _auditUrl ){
//       return ( saleInfo.softCap, MAX_INT,saleInfo.saleStartTime, saleInfo.saleEndTime, 0, 0,saleInfo.tokensOnSale, saleInfo.liquidityPercent, liquidityReleaseInDays, totalCoinReceived,totalParticipants, useWhiteList,hasKYC, _isAudited, auditUrl );
//   }

  

//   function getCampaignStatus() public view returns(CampaignStatus ){
//       return status ;
//   }

//   function getCampaignPeriod() public view returns(uint256 saleStartTime, uint256 saleEndTime ){
//       return (saleInfo.saleStartTime, saleInfo.saleEndTime );
//   }

//   function getCampaignSalePriceInfo() public view returns(uint256 , uint256,uint256 , uint256,uint256 , uint256,uint256 ){
//       return (0, 0, saleInfo.softCap, saleInfo.hardCap, tierOnehardCap,tierTwohardCap, maxAllocationPerUserTierTwo  );
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
//       return address( _dexLocker);
//   }

//   function tokenAddress() public view returns (address) {
//       return saleInfo.tokenAddress;
//   }

//   // Refund any mistakenly sent in ERC20
//   function refundERC20(IERC20 _token, address recipient, uint256 amount) public onlyAdmin {      
//     _token.safeTransfer(recipient, amount);
//   }

// }