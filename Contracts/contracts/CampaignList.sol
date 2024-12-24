// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/Context.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Campaign.sol";
import "./FairLaunchCampaign.sol";
import "./Confirmations/ConfirmAddress.sol";
import './Lockers/DexLockerFactory.sol';
import './Lockers/VestSchedule.sol';
import "hardhat/console.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import './Interfaces/Turnstile.sol';
import "./Errors.sol";

error NotEnoughBalance(uint balance);

interface ICampaignList{
    function zsaleFee() external view returns (uint);// 2%   - percent of purchase currency to take
    function zsaleTokenFee() external view returns (uint);// percent fee of token to take
    function campaignCreationPrice() external view returns (uint);// 
    function zsalesWalletAddress() external view returns (address); //receives commissions

    function zsalesAdmin() external view returns (address);
    function zsalesTokenAddress() external view returns (address);
    function zsalesNFTTokenAddress() external view returns (address);
    function getTierStatus(uint tier) external view returns (bool);
    function maxTiersToCheckForNFT() external view returns(uint);
}


contract CampaignList is Context,Ownable, ICampaignList  {
    error NoCampaignCreatePrice();
    error RequiresTokenContract();
    error ExistingCampaign();
    error TokensOnSaleRequired();

    using SafeERC20 for IERC20;
  // Add the library methods
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    
    // Declare a set state variable
    EnumerableMap.UintToAddressMap private _campaigns;

    uint private _counter;

    DexLockerFactory private _dexLockerFactory;

    ConfirmAddress addressConfirmer;

    /**
    * @dev percent of native currency to take multiplied by 100 i.e 200 for 2%.
    */
    uint public zsaleFee = 200;  //2%   - percent of native currency to take
    uint public zsaleTokenFee = 200;  //2% - percent fee of token to take
    uint public campaignCreationPrice = 0.00001 ether; 
    address public zsalesWalletAddress = 0xB7e16f5fa9941B84baCd1601F277B00911Aed339 ; // receives commissions

    address public zsalesAdmin  ;

    address public zsalesTokenAddress = 0x97CEe927A48dc119Fd0b0b1047a879153975e893 ;

    address public zsalesNFTTokenAddress = 0x97CEe927A48dc119Fd0b0b1047a879153975e893 ;

    mapping(address => uint256[]) private ownersCampaign; //owneraddress -> campaignIndex

    mapping(uint256 => bool) private _tierStatuses; //tier -> enable/disable

    mapping(address => uint256) public campaignTokensLocked; //owneraddress -> campaignIndex
    

    mapping(address => address payable ) public _tokenCampaigns; //tokenAddress=>Campaign

    event CampaignCreated(address indexed creator,uint256 indexed index, address createdCampaignAddress);
    
    uint public maxTiersToCheckForNFT= 5;
    
    address  _campaignImplementationAddress;

    address public turnstileAddress = address(0);
    Turnstile private turnstile;

    constructor(DexLockerFactory dexLockerFactory,address zsalesToken,address zsalesNFTToken, address campaignImplementationAddress) Ownable(msg.sender)  {      
       _dexLockerFactory=dexLockerFactory;
       _campaignImplementationAddress = campaignImplementationAddress;
       zsalesTokenAddress=zsalesToken;
       zsalesNFTTokenAddress=zsalesNFTToken;
       addressConfirmer=new ConfirmAddress();
       zsalesAdmin= _msgSender();
    }

    function updateTurnstileAddress(address newAddress) public onlyOwner{
        
        turnstileAddress=newAddress;
        turnstile = Turnstile(turnstileAddress);
        //Registers the smart contract with Turnstile
        //Mints the CSR NFT to the contract creator
        turnstile.register(tx.origin);

    }

    /**************************|
    |          Setters         |
    |_________________________*/
    function setCampaignImplementation(address campaignImplementationAddress) public onlyOwner  {   
       _campaignImplementationAddress = campaignImplementationAddress;
    }

    function setCampaignCreationPrice(uint256 newPrice) public onlyOwner{
        campaignCreationPrice=newPrice;
    }

    function setCampaignFee(uint256 saleFee, uint256 saleTokenFee) public onlyOwner{
        zsaleFee=saleFee;
        zsaleTokenFee=saleTokenFee;
    }

    function setFeeWallet(address salesWalletAddress) public onlyOwner{
        zsalesWalletAddress=salesWalletAddress;
    }

    function setAdmin(address newAdmin) public onlyOwner{
        zsalesAdmin=newAdmin;
    }

    function setZSalesMaxTiersToCheckForNFT(uint newMax) public onlyOwner{
        maxTiersToCheckForNFT=newMax;
    }

    function setZSalesNFTTokenAddress(address newAddress) public onlyOwner{
        zsalesNFTTokenAddress=newAddress;
    }

    function setZSalesTokenAddress(address newAddress) public onlyOwner{
        zsalesTokenAddress=newAddress;
    }

    function setTierStatus(uint tier,bool status) public onlyOwner{
        _tierStatuses[tier]=status;
    }

    function getTierStatus(uint tier) public view returns (bool){
        return _tierStatuses[tier];
    }

    function getCampaignValues(
        /** uint256 softCap,
         * uint256 hardCap,
         * uint256 _saleStartTime,
         * uint256 _saleEndTime,  
         * uint256 _minAllocationPerUser ,   
         * uint256 _maxAllocationPerUserTierTwo ,
         */
        uint256[6] memory _capAndDate
    ) public pure returns(uint256[10] memory capAndDate){
        for (uint i=0; i < 4; i += 1) {
            capAndDate[i] = _capAndDate[i];
        }
        capAndDate[4]=1000 * _capAndDate[1] / 4000;// tier 1 hardcap is 1/4th of hardcap
        capAndDate[5]=_capAndDate[1];// tier 2 hardcap is equal to hardcap
        capAndDate[6]=_capAndDate[4];//min allocation
        capAndDate[7]=_capAndDate[5];// max allocation
        capAndDate[8]=_capAndDate[5];// max allocation
        capAndDate[9]=0;
    }
    

    /**
    * @dev Create A new Campaign. Throws if Campaign for token already exists.
    */
    function createNewCampaign(address _tokenAddress, address _purchaseTokenAddress, 
        uint tokensOnSale,  //tokensOnSale ,if fairlaunch
        /** uint256 softCap,
     * uint256 hardCap,
     * uint256 _saleStartTime,
     * uint256 _saleEndTime,  
     * uint256 _minAllocationPerUser ,   
     * uint256 _maxAllocationPerUserTierTwo 
     */
        uint256[6] memory _capAndDate, address _dexRouterAddress,uint[4] memory liquidityAllocationAndRates,
        string[6] memory founderInfo,bool[2] memory _useTokenOrRaisedFundsVesting,
        // VestSchedule[8] memory teamTokenVestingDetails,
        uint256[5] memory teamTokenVestingDetails,
        /**
         * uint256 _percent,
         * uint256 _vestingDurationInDays,
         * uint256 _vestingCliffInDays,
         */
        uint256[3] memory raisedFundVestingDetails
    ) public payable  {
        /** uint256 _normalizedTo18DecimalsSoftCap,
         * uint256 __normalizedTo18DecimalsHardCap,
         * uint256 _saleStartTime,
         * uint256 _saleEndTime, 
         * 
         * uint256 _nomrlaizedTierOneHardCap, 
         * uint256 _nomrlaizedTierTwoHardCap, 
         * _minAllocationPerUser
         * uint256 _maxAllocationPerUserTierOne, 
         * uint256 _maxAllocationPerUserTierTwo ,
         * uint _campaignKey,*/
        uint256[10] memory capAndDate = getCampaignValues(_capAndDate);

        if(capAndDate[0]==0){//FairLaunch
            require(tokensOnSale>1, TokensOnSaleRequired());
        }

        if(capAndDate[0]!=0){//Capped campaign
            require(capAndDate[1]  <= capAndDate[0] * 4, HardCapGreaterThanX4OfSoftCap());
        }

        require(msg.value >= campaignCreationPrice, NoCampaignCreatePrice() );
        require(addressConfirmer.isContract(_tokenAddress), RequiresTokenContract());        
        if(_tokenCampaigns[_tokenAddress] != address(0)){
            Campaign ct = Campaign(_tokenCampaigns[_tokenAddress]);
            require(ct.status() == Campaign.CampaignStatus.CANCELLED || ct.status() == Campaign.CampaignStatus.FAILED, ExistingCampaign());
        }
        
        {     
            _counter++; 
            capAndDate[9] = _counter;
            
            if(_purchaseTokenAddress!= address(0)){
                uint purchaseDecimals = IERC20Metadata(_purchaseTokenAddress).decimals();
                if( purchaseDecimals !=18){
                    capAndDate[0]=normalizeTokenAmount(capAndDate[0], purchaseDecimals); //Softcap
                    capAndDate[1]=normalizeTokenAmount(capAndDate[1], purchaseDecimals);

                    capAndDate[4]=normalizeTokenAmount(capAndDate[4], purchaseDecimals); 
                    capAndDate[5]=normalizeTokenAmount(capAndDate[5], purchaseDecimals);

                    capAndDate[6]=normalizeTokenAmount(capAndDate[6], purchaseDecimals); 
                    capAndDate[7]=normalizeTokenAmount(capAndDate[7], purchaseDecimals);
                    capAndDate[8]=normalizeTokenAmount(capAndDate[8], purchaseDecimals);
                }else if(purchaseDecimals >18){
                    revert OnlyDecimals18AndBelow();
                }
            }

            address payable newCampaignCloneAddress = payable(Clones.clone(_campaignImplementationAddress) );
            Campaign(newCampaignCloneAddress).initialize([msg.sender, address(this) ,  _tokenAddress, _purchaseTokenAddress],
                capAndDate[0]==0?tokensOnSale:0, 
                capAndDate, _dexRouterAddress,liquidityAllocationAndRates,teamTokenVestingDetails, raisedFundVestingDetails,
                 _useTokenOrRaisedFundsVesting, founderInfo, _dexLockerFactory);

             _campaigns.set(_counter, newCampaignCloneAddress);
            ownersCampaign[msg.sender].push( _counter);        
            _tokenCampaigns[_tokenAddress]= payable(newCampaignCloneAddress);


            emit CampaignCreated(msg.sender, _counter,newCampaignCloneAddress);

            _transferTokensRequired(Campaign(newCampaignCloneAddress),liquidityAllocationAndRates[0],capAndDate[0],capAndDate[1], liquidityAllocationAndRates[2],tokensOnSale,  _useTokenOrRaisedFundsVesting[0], teamTokenVestingDetails[0]);

        }
    }

    function _transferTokensRequired(Campaign ct,uint liquidityPercent,uint softCap, uint hardCap, uint listRate, uint tokensOnSale, bool useTeamTokenVesting, uint totalTeamTokensToBeVested) private 
    {               
        uint tokenDecimals = IERC20Metadata(ct.tokenAddress()).decimals();
        
        //tokensForLiquidity // in 18 digits
        uint amountOfTokensToLock = softCap !=0 ?  (ct.getDexListRate() * liquidityPercent * hardCap)  / 10000 : liquidityPercent * normalizeTokenAmount(tokensOnSale, tokenDecimals ) /10000;
        
        //tokensForSale // in 18 digits
        uint tokensForSale = softCap !=0 ?  (listRate * hardCap) : normalizeTokenAmount(tokensOnSale, tokenDecimals );
        amountOfTokensToLock += tokensForSale;
               

        // add zsale fee
        uint256 feeAmount =  softCap !=0? ((zsaleTokenFee *  ct.getHardCap() )/10000) * ct.getDexListRate() : (zsaleTokenFee *  normalizeTokenAmount(tokensOnSale, tokenDecimals ) /10000);

        uint total = ((amountOfTokensToLock + feeAmount) / (10**(18 - tokenDecimals )) );
        
        if(useTeamTokenVesting){
            
            total += totalTeamTokensToBeVested;
            // console.log('CONTRACT::  Vested Tokens: %d, norm: %d, FINALTOTAL: %d', totalTeamTokensToBeVested, normalizeTokenAmount(totalTeamTokensToBeVested, tokenDecimals ), total );
        }

        IERC20 _token = IERC20(ct.tokenAddress());
        
        _token.safeTransferFrom(_msgSender(), address(ct), total);

        campaignTokensLocked[address(ct)]=total;//(amountOfTokensToLock+feeAmount) * (10**tokenDecimals ) / (10**(18 - tokenDecimals ));//  * (10**(18 - tokenDecimals ))  ;
        
        // _token.safeTransfer( address(ct), total);
        ct.startReceivingBids();
    }

    

    function hasExistingCampaign(address _tokenAddress) external view returns (bool){
        return _tokenCampaigns[_tokenAddress] != address(0);
    }

    function allOwnersCampaignsSize() public view returns (uint256) {
        return ownersCampaign[msg.sender].length;
    }
    function allOwnersCampaignsSize(address owner) public view returns (uint256) {
        return ownersCampaign[owner].length;
    }

    //offset 
    function allOwnersCampaigns( uint256 start, uint256 offset) public view returns (uint256[] memory) {
        uint256[] memory list = new uint256[](offset) ;
        for (uint256 i=start; i < start + offset ; i++) {
            list[i-start] = ownersCampaign[msg.sender][i]; 
        }
        return list;
    }

    function allOwnersCampaigns(address owner, uint256 start, uint256 offset) public view returns (uint256[] memory) {
        uint256[] memory list = new uint256[](offset) ;
        for (uint256 i=start; i < start + offset ; i++) {
            list[i-start] = ownersCampaign[owner][i]; 
        }
        return list;
    }

    
    function campaignSize() public view returns (uint256) {
        return _campaigns.length();
    }

    

        

    function contains(uint256 key) public view returns (bool) {
        return _campaigns.contains(key);
    }

        

    function campaignAt(uint256 index) public view returns (uint256 key, address value) {
        return _campaigns.at(index);
    }

    function tryGetCampaignByKey(uint256 key) public view returns (bool, address) {
        return _campaigns.tryGet(key);
    }

    function tryGetCampaignByTokenAddress(address _tokenAddress) public view returns ( address) {
        return _tokenCampaigns[_tokenAddress];
    }

    receive() external payable {
        
    }

    // //abi.encodePacked(x)
    // function concatenate(string memory s1, string memory s2) public pure returns (string memory) {
    //     return string(abi.encodePacked(s1, s2));
    // }

    // function concatenate(string memory s1, address s2) public pure returns (string memory) {
    //     return string(abi.encodePacked(s1, s2));
    // }


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
    
    // Sends to th 'to' address or the zsalesWalletAddress if to address is zeroAddress
    function  withdrawFee(address to, uint amount) public onlyOwner  {
        
        uint balance = address(this).balance;
        if(amount>=balance){
            if(to==address(0)){
                to=zsalesWalletAddress;
            }

            payable(to).transfer(amount);
        }else {
            revert NotEnoughBalance(balance);
        }
    }

}