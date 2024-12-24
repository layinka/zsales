import { assert, expect } from "chai";
import { ethers } from "hardhat";
import { utils } from "../typechain-types/@openzeppelin/contracts";
import {advanceTimeTo, getCurrentBlockTimeStamp, takeSnapshot, revertToSnapshot, getDateFromEther, formatEtherDateToJs} from './utils';
import { formatEther, parseEther } from "ethers/lib/utils";
import { BigNumber, Contract } from "ethers";
import { CampaignList__factory, DexLocker__factory, PurchasedCoinVestingVault__factory } from "../typechain-types";
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');


describe("CampaignList", function () {
  
   this.timeout(100000);

  const now = new Date();
  const thirtySecondsTime = now.setSeconds(now.getSeconds()+15);
  const twoHoursTime = now.setHours(now.getHours()+2);
  const fourHoursLater = now.setHours(now.getHours()+4);
  const thirtyDaysLater = now.setDate(now.getDate()+30);
  let CampaignFactoryArtifact: any = undefined;
  let TokenArtifact: any = undefined;
  let DecimalTokenArtifact: any = undefined;
  let Token2Artifact: any = undefined;
  let CampaignArtifact:any  = undefined;
  let DexLockerFactoryArtifact = undefined;
  let PurchasedCoinVestingVaultArtifact=undefined;
  let DexLockerArtifact:any = undefined;
  let FactoryV2Artifact = undefined;
  let RouterV2Artifact = undefined;
  let WBNBV2Artifact = undefined;
  let NFTERC1155Artifact = undefined;
  const zsaleTokenFee=200;

  let routerv2;

  //let router = '0xeD37AEDD777B44d34621Fe5cb1CF594dc39C8192';
  //let router = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";// 

  /* (BTTC Testnet)
	  CampaignList
Factory Address: 0xb40E51f657EFa934D43A05cd4cC9f0a11faA05d0
WBNB Address: 0xED2E8410ECd1e71dDd0d9E045dc8ADA7C4509278
Router Address: 0x932102Bc1916f9d74E271dB6685aba0276f112F2 
  */
  let router = "0x932102Bc1916f9d74E271dB6685aba0276f112F2";// BTTC Test


  let  campaignFactory: any;
  let campaign:any;
  let  token: any;
  let campaignAddress: string;
  const softCap = 1;// ethers.utils.formatUnits( ethers.utils.parseEther("0"), 'wei');
  const hardCap = 4; //ethers.utils.formatUnits( ethers.utils.parseEther("1"), 'wei')
  let usdcToken: any;

  let zsalesNftToken: any;

  before('Initialize and Deploy SmartContracts', async () => {
      
      CampaignFactoryArtifact = await ethers.getContractFactory("CampaignList");
      TokenArtifact = await ethers.getContractFactory("Token");
      Token2Artifact = await ethers.getContractFactory("Token2");
      DecimalTokenArtifact = await ethers.getContractFactory("DecimalToken");
      CampaignArtifact = await ethers.getContractFactory("Campaign");
      DexLockerFactoryArtifact = await ethers.getContractFactory("DexLockerFactory");
      DexLockerArtifact = await ethers.getContractFactory("DexLocker");
      PurchasedCoinVestingVaultArtifact = await ethers.getContractFactory("PurchasedCoinVestingVault");
      NFTERC1155Artifact= await ethers.getContractFactory("NFTERC1155")

      const ZSalesTokenArtifact = await ethers.getContractFactory("NFTToken");

      FactoryV2Artifact = await ethers.getContractFactory("PancakeFactory");
      RouterV2Artifact = await ethers.getContractFactory("PancakeRouter");
      WBNBV2Artifact = await ethers.getContractFactory("WBNB");

      const [owner] = await ethers.getSigners();
      const factoryv2 = await FactoryV2Artifact.deploy(owner.address);
      await factoryv2.deployed();

      const wbnb = await WBNBV2Artifact.deploy();
      await wbnb.deployed();

      routerv2 = await RouterV2Artifact.deploy(factoryv2.address, wbnb.address);
      await routerv2.deployed();

      router = routerv2.address;

      
      // //celo test
      // router = '0x0e6991d3033B7904913177CF866d52c16B7a8C90'

      

      token = await TokenArtifact.deploy();
      await token.deployed();
      

      const zsalesToken = await TokenArtifact.deploy();
      await zsalesToken.deployed();
      

      usdcToken = await Token2Artifact.deploy('USD Coin','USDC');
      await usdcToken.deployed();
      console.log('USDC Token Deployed at  ', usdcToken.address );

      let extraToken = await TokenArtifact.deploy();
      await extraToken.deployed();
      console.log('extraToken Deployed at  ', extraToken.address );

      let campaignImplementation = await CampaignArtifact.deploy();
      await campaignImplementation.deployed();
      

      let dexLockerImplementation = await DexLockerArtifact.deploy();
      await dexLockerImplementation.deployed();
      

      let coinVault = await PurchasedCoinVestingVaultArtifact.deploy();
      await coinVault.deployed();
      
      
      const dexLockerFactory = await DexLockerFactoryArtifact.deploy(dexLockerImplementation.address, coinVault.address);
      await dexLockerFactory.deployed();

      zsalesNftToken = await NFTERC1155Artifact.deploy();
      await zsalesNftToken.deployed();
      console.log('zsalesNftToken(ERC1155) Deployed at  ', zsalesNftToken.address );
      
      campaignFactory = await CampaignFactoryArtifact.deploy(dexLockerFactory.address ,zsalesToken.address,zsalesNftToken.address, campaignImplementation.address);
      await campaignFactory.deployed();
      console.log('Using Campaign List Deployed at  ', campaignFactory.address );

      // //celo test
      // campaignFactory = await CampaignFactoryArtifact.attach('0x1045Bc8e0557645a50f692d030AFDD01D893c9C9');


      /*
      Token2 Deployed at   0x54B15d18c32032767d55AEB199ae488708cF6845
Campaign Implemntation Deployed at   0xE47050824F0Ec836a3A0EA0bfcdBfbF4743bEe77
dexLocker Implemntation Deployed at   0x6A75daCCA1fAeFec99F20f88866b4a3F6cD61467
coinVesting Implemntation Deployed at   0x54DB465CAdd676690DBbe1fDa03FE532fDa44628
Using Campaign List Deployed at   0xA1C16951Ad300Be8D2fb2976303d52ABa5Aa1b25*/

		// campaignFactory = await CampaignFactoryArtifact.attach('0xA1C16951Ad300Be8D2fb2976303d52ABa5Aa1b25');
      
  });

  async function createNewCampaign( start: any,end: any, purchaseTokenAddress="0x0000000000000000000000000000000000000000", _softCap?: number, _hardCap?: number, tokenAdress=undefined){
    const [owner] = await ethers.getSigners();
    let token;
    if(tokenAdress){
      token= await TokenArtifact.attach(tokenAdress)
    }else{
      token = await TokenArtifact.deploy();
      await token.deployed();
    }
    

    let purchaseCoinDecimals = 18
    if(purchaseTokenAddress != '0x0000000000000000000000000000000000000000' ){
      purchaseCoinDecimals = await TokenArtifact.attach(purchaseTokenAddress).decimals();
      //console.log('PURCHASE DECIMALS:: ',await TokenArtifact.attach(purchaseTokenAddress).decimals() )
    } 

    console.log('Hardcap and softcap',(_hardCap??hardCap), (_softCap??softCap))

    //Approve token
    await (await token.approve(campaignFactory.address, ethers.utils.parseEther('1000000000'))).wait();

    const createCampaignTx = await campaignFactory.createNewCampaign(token.address,
        purchaseTokenAddress,
        0,
        [
          ethers.utils.parseUnits((_softCap??softCap).toString(), purchaseCoinDecimals) ,
          ethers.utils.parseUnits((_hardCap??hardCap).toString(), purchaseCoinDecimals) ,
          Math.floor(start/1000) ,//  Math.floor(new Date().getTime() / 1000) , // twoHoursTime, thirtySecondsTime
          Math.floor(end/1000) , 
          ethers.utils.parseUnits("0.1", purchaseCoinDecimals),//_minAllocationPerUser
          ethers.utils.parseUnits("1", purchaseCoinDecimals),////_maxAllocationPerUserTierOne
          
        ],
        router,
        [6000,30, '1000','1000'],
        //founderinfo
        //[formData.logo,'',formData.website, formData.twitter, formData.telegram, formData.discord ]
        ['https://place-hold.it/110','dsec', 'https://testtoken.org','https://twitter.com/test','https://testtoken.org', 'http://discord.me'],
        [
          false,//useTeamTokenVesting
          false //UseRaisedFundsvesting
        ],
          //teamtokenvesting
          [0,0,0,0,0],
        //   [
        //     1000,
        //     50,
        //     30,
        //     10,
        //     30
        //   ],

        //   [
        //   {releaseDate: fourHoursLater, releaseAmount: ethers.utils.parseEther("0.05"), hasBeenClaimed: false},
        //   {releaseDate: fourHoursLater, releaseAmount: ethers.utils.parseEther("0.02"), hasBeenClaimed: false},
        //   {releaseDate: fourHoursLater, releaseAmount: ethers.utils.parseEther("0.05"), hasBeenClaimed: false},
        //   {releaseDate: fourHoursLater, releaseAmount: ethers.utils.parseEther("0.02"), hasBeenClaimed: false},
        //   {releaseDate: fourHoursLater, releaseAmount: '0', hasBeenClaimed: false},
        //   {releaseDate: fourHoursLater, releaseAmount: '0', hasBeenClaimed: false},
        //   {releaseDate: fourHoursLater, releaseAmount: '0', hasBeenClaimed: false},
        //   {releaseDate: fourHoursLater, releaseAmount: '0', hasBeenClaimed: false}
        // ],        
        [0,0,0],
        {  
          value: ethers.utils.parseEther("0.00001") 
        });
    let txResult =   await createCampaignTx.wait();
    
    const campaignAddress = txResult.events.filter((f: any)=>f.event=='CampaignCreated')[0].args['createdCampaignAddress'];
    

    return  {
      campaign: CampaignArtifact.attach(campaignAddress),
      token: token
    };
  }

  async function createNewFairLaunchCampaign( start: any,end: any, purchaseTokenAddress="0x0000000000000000000000000000000000000000", _softCap?: number, _hardCap?: number,tokenAdress?: string, tokensOnSale?: number ){
    const [owner] = await ethers.getSigners();
    let token;
    if(tokenAdress){
      token= await TokenArtifact.attach(tokenAdress)
    }else{
      token = await TokenArtifact.deploy();
      await token.deployed();
    }

    let tokenDecimals = await token.decimals()

    let purchaseCoinDecimals = 18
    if(purchaseTokenAddress != '0x0000000000000000000000000000000000000000' ){
      purchaseCoinDecimals = await TokenArtifact.attach(purchaseTokenAddress).decimals();
      
    } 

    //Approve token
    await (await token.approve(campaignFactory.address, ethers.utils.parseUnits('1000000000', tokenDecimals))).wait();

    const createCampaignTx = await campaignFactory.createNewCampaign(token.address,
        purchaseTokenAddress,
        ethers.utils.parseUnits((tokensOnSale??10000).toString(), tokenDecimals),
        [
          ethers.utils.parseUnits('0', purchaseCoinDecimals) ,
          ethers.utils.parseUnits((_hardCap??hardCap).toString(), purchaseCoinDecimals) ,
          Math.floor(start/1000) ,//  Math.floor(new Date().getTime() / 1000) , // twoHoursTime, thirtySecondsTime
          Math.floor(end/1000) , 
          ethers.utils.parseUnits("0.1", purchaseCoinDecimals),//_minAllocationPerUser
          ethers.utils.parseUnits("1", purchaseCoinDecimals),////_maxAllocationPerUserTierOne         
        ],
        router,
        [6000,30, '1000','1000'],
        //founderinfo
        //[formData.logo,'',formData.website, formData.twitter, formData.telegram, formData.discord ]
        ['https://place-hold.it/110','dsec', 'https://testtoken.org','https://twitter.com/test','https://testtoken.org', 'http://discord.me'],
        [
          false,//useTeamTokenVesting
          false //UseRaisedFundsvesting
        ],
          //teamtokenvesting
          [0,0,0,0,0],
        //   [
        //     1000,
        //     50,
        //     30,
        //     10,
        //     30
        //   ],

        //   [
        //   {releaseDate: fourHoursLater, releaseAmount: ethers.utils.parseEther("0.05"), hasBeenClaimed: false},
        //   {releaseDate: fourHoursLater, releaseAmount: ethers.utils.parseEther("0.02"), hasBeenClaimed: false},
        //   {releaseDate: fourHoursLater, releaseAmount: ethers.utils.parseEther("0.05"), hasBeenClaimed: false},
        //   {releaseDate: fourHoursLater, releaseAmount: ethers.utils.parseEther("0.02"), hasBeenClaimed: false},
        //   {releaseDate: fourHoursLater, releaseAmount: '0', hasBeenClaimed: false},
        //   {releaseDate: fourHoursLater, releaseAmount: '0', hasBeenClaimed: false},
        //   {releaseDate: fourHoursLater, releaseAmount: '0', hasBeenClaimed: false},
        //   {releaseDate: fourHoursLater, releaseAmount: '0', hasBeenClaimed: false}
        // ],        
        [0,0,0],
        {  
          value: ethers.utils.parseEther("0.00001") 
        });
    let txResult =   await createCampaignTx.wait();
    
    const campaignAddress = txResult.events.filter((f: any)=>f.event=='CampaignCreated')[0].args['createdCampaignAddress'];
    


    return  {
      campaign: CampaignArtifact.attach(campaignAddress),
      token: token
    };
  }

  async function createNewFairLaunchCampaignWithRaisedFundsVesting( start: any,end: any, purchaseTokenAddress="0x0000000000000000000000000000000000000000",_softCap?: number, _hardCap?: number,tokenAdress=undefined, tokensOnSale?:number){
    const [owner] = await ethers.getSigners();
    let token;
    if(tokenAdress){
      token= await TokenArtifact.attach(tokenAdress)
    }else{
      token = await TokenArtifact.deploy();
      await token.deployed();
    }

    let tokenDecimals= await token.decimals();

    let purchaseCoinDecimals = 18
    if(purchaseTokenAddress != '0x0000000000000000000000000000000000000000' ){
      purchaseCoinDecimals = await TokenArtifact.attach(purchaseTokenAddress).decimals();
    } 

    //Approve token
    await (await token.approve(campaignFactory.address, ethers.utils.parseEther('1000000000'))).wait();

    const createCampaignTx = await campaignFactory.createNewCampaign(token.address,
        purchaseTokenAddress,
        ethers.utils.parseUnits((tokensOnSale??10000).toString(), tokenDecimals),
        [
          ethers.utils.parseUnits('0', purchaseCoinDecimals) ,
          ethers.utils.parseUnits((_hardCap??hardCap).toString(), purchaseCoinDecimals) ,
          Math.floor(start/1000) ,//  Math.floor(new Date().getTime() / 1000) , // twoHoursTime, thirtySecondsTime
          Math.floor(end/1000) , 
          ethers.utils.parseUnits("0.1", purchaseCoinDecimals),//_minAllocationPerUser
          ethers.utils.parseUnits("1", purchaseCoinDecimals),////_maxAllocationPerUserTierOne
        ],
        router,
        [6000,30, '1000','1000'],
        //founderinfo
        //[formData.logo,'',formData.website, formData.twitter, formData.telegram, formData.discord ]
        ['https://place-hold.it/110','dsec', 'https://testtoken.org','https://twitter.com/test','https://testtoken.org', 'http://discord.me'],
        [
          false,//useTeamTokenVesting
          true //UseRaisedFundsvesting
        ],
          //teamtokenvesting
          [0,0,0,0,0],
        //   [
        //     1000,
        //     50,
        //     30,
        //     10,
        //     30
        //   ],

        //   [
        //   {releaseDate: fourHoursLater, releaseAmount: ethers.utils.parseEther("0.05"), hasBeenClaimed: false},
        //   {releaseDate: fourHoursLater, releaseAmount: ethers.utils.parseEther("0.02"), hasBeenClaimed: false},
        //   {releaseDate: fourHoursLater, releaseAmount: ethers.utils.parseEther("0.05"), hasBeenClaimed: false},
        //   {releaseDate: fourHoursLater, releaseAmount: ethers.utils.parseEther("0.02"), hasBeenClaimed: false},
        //   {releaseDate: fourHoursLater, releaseAmount: '0', hasBeenClaimed: false},
        //   {releaseDate: fourHoursLater, releaseAmount: '0', hasBeenClaimed: false},
        //   {releaseDate: fourHoursLater, releaseAmount: '0', hasBeenClaimed: false},
        //   {releaseDate: fourHoursLater, releaseAmount: '0', hasBeenClaimed: false}
        // ],        
        [10000,30,20],
        {  
          value: ethers.utils.parseEther("0.00001") 
        });
    let txResult =   await createCampaignTx.wait();
    
    const campaignAddress = txResult.events.filter((f: any)=>f.event=='CampaignCreated')[0].args['createdCampaignAddress'];
    
    return  {
      campaign: CampaignArtifact.attach(campaignAddress),
      token: token
    };
  }



  it("Should create new campaign", async function () {
    const [owner] = await ethers.getSigners();
    const prevCount = await campaignFactory.campaignSize();
    const createCampaignResult = await createNewCampaign(thirtySecondsTime, thirtyDaysLater,'0x0000000000000000000000000000000000000000', 1, 2);

    campaignAddress = createCampaignResult.campaign.address;
    campaign = createCampaignResult.campaign;
    token = createCampaignResult.token;
    
    
    const newCount = await campaignFactory.campaignSize();
    expect(newCount-prevCount).to.equal(1);

  });

  
  

  it('updates  contract details successfully', async() => {

    
    let error;
    try{
      const [owner] = await ethers.getSigners();
      const now = new Date();      
      const timeLater = now.setSeconds(now.getSeconds() + (60*30));
        
      let { campaign:cmp, token} = await createNewCampaign(timeLater,thirtyDaysLater);            
      const updateCampaignTx = await cmp.updateCampaignFounderDetails('logourl', 'desc', 'websiteurl','twitter','telegram', 'discord');        
      let txResult =   await updateCampaignTx.wait();      
      expect(txResult.status).to.equal(1);      
      
    }catch(err){
      console.error(err);
      error=err;
    }
    expect(error).to.equal(undefined);
  });

  it('campaignlist should return correct campaign address for token address', async() => {
        const returnedAddress = await campaignFactory.tryGetCampaignByTokenAddress(token.address);
        expect(returnedAddress).to.equal(campaignAddress);
  });

  it('should calculate the right totals for 18 Digit token Capped campaigns - without token vesting or fund locking', async ( )=>{
    const start: any = thirtySecondsTime + 10000
    const end: any = thirtyDaysLater
    const purchaseTokenAddress="0x0000000000000000000000000000000000000000"
    const [owner] = await ethers.getSigners();
    const token = await TokenArtifact.deploy();
    await token.deployed();

    //Approve token
    await (await token.approve(campaignFactory.address, ethers.utils.parseEther('1000000000'))).wait();

    const softCapNumber = 25;
    const hardCapNumber = 100;
    const softCap = ethers.utils.formatUnits( ethers.utils.parseEther(softCapNumber.toFixed(0)), 'wei');
    const hardCap = ethers.utils.formatUnits( ethers.utils.parseEther(hardCapNumber.toFixed(0)), 'wei')

    const saleRate = 1000;
    const dexRate = 1000;
    const liqRatio = 6000; //60%
    const tokensOnSale=10000;
    const zsaleTokenFee=200;//2%
    // createNewCampaign(start,end, purchaseTokenAddress, softCapNumber,hardCapNumber)

    const createCampaignTx = await campaignFactory.createNewCampaign(token.address,
        purchaseTokenAddress,
        ethers.utils.parseEther(tokensOnSale.toString()),
        [
          softCap,
          hardCap, 
          Math.floor(start/1000) ,//  Math.floor(new Date().getTime() / 1000) , // twoHoursTime, thirtySecondsTime
          Math.floor(end/1000) , 
          ethers.utils.formatUnits( ethers.utils.parseEther("0.1"), 'wei'),//_minAllocationPerUser
          ethers.utils.formatUnits( ethers.utils.parseEther("1000"), 'wei'),////_maxAllocationPerUserTierOne
        ],
        router,
        [liqRatio,30, saleRate.toFixed(),dexRate.toFixed()], //liqRatio, liquidityReleaseTime, listRate,dexRate
        //founderinfo
        //[formData.logo,'',formData.website, formData.twitter, formData.telegram, formData.discord ]
        ['https://place-hold.it/110','dsec', 'https://testtoken.org','https://twitter.com/test','https://testtoken.org', 'http://discord.me'],
        [
          false,//useTeamTokenVesting
          false //UseRaisedFundsvesting
        ],
          //teamtokenvesting
          [0,0,0,0,0],
        //   [
        //     1000,
        //     50,
        //     30,
        //     10,
        //     30
        //   ],
        //Raisedfundsvesting     
        [0,0,0],
        {  
          value: ethers.utils.parseEther("0.00001") 
        });
    let txResult =   await createCampaignTx.wait();
    
    const campaignAddress = txResult.events.filter((f: any)=>f.event=='CampaignCreated')[0].args['createdCampaignAddress'];
    
        
    const totalTockenToLock =  await campaignFactory.campaignTokensLocked(campaignAddress)
    console.log('totalTockenToLock: ', totalTockenToLock, ethers.utils.formatEther(totalTockenToLock))
    
    expect( totalTockenToLock ).equal(ethers.utils.parseEther(( (saleRate * hardCapNumber) + (liqRatio * (dexRate * hardCapNumber) / 10000) + (zsaleTokenFee * (dexRate * hardCapNumber)/10000) ).toFixed()) )

  })

  it('should calculate the right totals for Non-18 digit token Capped campaigns - without token vesting or fund locking', async ( )=>{
    const start: any = thirtySecondsTime + 10000
    const end: any = thirtyDaysLater
    let purchaseTokenAddress="0x0000000000000000000000000000000000000000"
    const [owner] = await ethers.getSigners();
    const tokenDecimal = 6;
    const token = await DecimalTokenArtifact.deploy(tokenDecimal);
    await token.deployed();

    
    //Approve token
    await (await token.approve(campaignFactory.address, ethers.utils.parseUnits('1000000000', tokenDecimal))).wait();

    const softCapNumber = 30;
    const hardCapNumber = 100;
    const softCap = ethers.utils.parseUnits(softCapNumber.toFixed(softCapNumber), 18);
    const hardCap = ethers.utils.parseUnits(hardCapNumber.toFixed(hardCapNumber), 18)

    const saleRate = 1000;
    const dexRate = 1000;
    const liqRatio = 6000; //60%
    const tokensOnSale=10000;
    const zsaleTokenFee=200;//2%
    // createNewCampaign(start,end, purchaseTokenAddress, softCapNumber,hardCapNumber)

    const createCampaignTx = await campaignFactory.createNewCampaign(token.address,
        purchaseTokenAddress,
        0,
        [
          softCap,
          hardCap, 
          Math.floor(start/1000) ,//  Math.floor(new Date().getTime() / 1000) , // twoHoursTime, thirtySecondsTime
          Math.floor(end/1000) , 
          ethers.utils.parseUnits("0.1", 18),//_minAllocationPerUser
          ethers.utils.parseUnits("1000", 18),////_maxAllocationPerUserTierOne
        ],
        router,
        [liqRatio,30, saleRate.toFixed(),dexRate.toFixed()], //liqRatio, liquidityReleaseTime, listRate,dexRate
        //founderinfo
        //[formData.logo,'',formData.website, formData.twitter, formData.telegram, formData.discord ]
        ['https://place-hold.it/110','dsec', 'https://testtoken.org','https://twitter.com/test','https://testtoken.org', 'http://discord.me'],
        [
          false,//useTeamTokenVesting
          false //UseRaisedFundsvesting
        ],
          //teamtokenvesting
          [0,0,0,0,0],
        //   [
        //     1000,
        //     50,
        //     30,
        //     10,
        //     30
        //   ],
        //Raisedfundsvesting     
        [0,0,0],
        {  
          value: ethers.utils.parseEther("0.00001") 
        });
    let txResult =   await createCampaignTx.wait();
    
    const campaignAddress = txResult.events.filter((f: any)=>f.event=='CampaignCreated')[0].args['createdCampaignAddress'];
    
        
    const totalTockenToLock =  await campaignFactory.campaignTokensLocked(campaignAddress)
    // console.log('totalTockenToLock: ', totalTockenToLock, ethers.utils.formatUnits(totalTockenToLock, tokenDecimal))

    expect( totalTockenToLock ).equal(ethers.utils.parseUnits(( (saleRate * hardCapNumber) + (liqRatio * (dexRate * hardCapNumber) / 10000) + (zsaleTokenFee * (dexRate * hardCapNumber)/10000) ).toFixed() , tokenDecimal) )
    // expect( totalTockenToLock ).equal(ethers.utils.parseUnits(( tokensOnSale + (liqRatio * tokensOnSale / 10000) + (zsaleTokenFee * tokensOnSale/10000) ).toFixed(), tokenDecimal) )

  })

  it('should calculate the right totals for 18 Digit fairlaunch campaigns - without token vesting or fund locking', async ( )=>{
    const start: any = thirtySecondsTime + 10000
    const end: any = thirtyDaysLater
    const purchaseTokenAddress="0x0000000000000000000000000000000000000000"
    const [owner] = await ethers.getSigners();
    const token = await TokenArtifact.deploy();
    await token.deployed();

    //Approve token
    await (await token.approve(campaignFactory.address, ethers.utils.parseEther('1000000000'))).wait();

    const softCapNumber = 0;
    const hardCapNumber = 100;
    const softCap = ethers.utils.formatUnits( ethers.utils.parseEther(softCapNumber.toFixed(0)), 'wei');
    const hardCap = ethers.utils.formatUnits( ethers.utils.parseEther(hardCapNumber.toFixed(10)), 'wei')

    const saleRate = 1000;
    const dexRate = 1000;
    const liqRatio = 6000; //60%
    const tokensOnSale=10000;
    const zsaleTokenFee=200;//2%
    // createNewCampaign(start,end, purchaseTokenAddress, softCapNumber,hardCapNumber)

    const createCampaignTx = await campaignFactory.createNewCampaign(token.address,
        purchaseTokenAddress,
        ethers.utils.parseEther(tokensOnSale.toString()),
        [
          softCap,
          hardCap, 
          Math.floor(start/1000) ,//  Math.floor(new Date().getTime() / 1000) , // twoHoursTime, thirtySecondsTime
          Math.floor(end/1000) , 
          ethers.utils.formatUnits( ethers.utils.parseEther("0.1"), 'wei'),//_minAllocationPerUser
          ethers.utils.formatUnits( ethers.utils.parseEther("1000"), 'wei'),////_maxAllocationPerUserTierOne
        ],
        router,
        [liqRatio,30, saleRate.toFixed(),dexRate.toFixed()], //liqRatio, liquidityReleaseTime, listRate,dexRate
        //founderinfo
        //[formData.logo,'',formData.website, formData.twitter, formData.telegram, formData.discord ]
        ['https://place-hold.it/110','dsec', 'https://testtoken.org','https://twitter.com/test','https://testtoken.org', 'http://discord.me'],
        [
          false,//useTeamTokenVesting
          false //UseRaisedFundsvesting
        ],
          //teamtokenvesting
          [0,0,0,0,0],
        //   [
        //     1000,
        //     50,
        //     30,
        //     10,
        //     30
        //   ],
        //Raisedfundsvesting     
        [0,0,0],
        {  
          value: ethers.utils.parseEther("0.00001") 
        });
    let txResult =   await createCampaignTx.wait();
    
    const campaignAddress = txResult.events.filter((f: any)=>f.event=='CampaignCreated')[0].args['createdCampaignAddress'];
    
        
    const totalTockenToLock =  await campaignFactory.campaignTokensLocked(campaignAddress)
    //console.log('totalTockenToLock: ', totalTockenToLock, ethers.utils.formatEther(totalTockenToLock))
    
    expect( totalTockenToLock ).equal(ethers.utils.parseEther(( tokensOnSale + (liqRatio * tokensOnSale / 10000) + (zsaleTokenFee * tokensOnSale/10000) ).toFixed()) )

  })

  it('should calculate the right totals for Non-18 Digit fairlaunch campaigns - without token vesting or fund locking', async ( )=>{
    const start: any = thirtySecondsTime + 10000
    const end: any = thirtyDaysLater
    const purchaseTokenAddress="0x0000000000000000000000000000000000000000"
    const [owner] = await ethers.getSigners();
    const tokenDecimal = 6;
    const token = await DecimalTokenArtifact.deploy(tokenDecimal);
    await token.deployed();

    //Approve token
    await (await token.approve(campaignFactory.address, ethers.utils.parseUnits('1000000000', tokenDecimal))).wait();

    const softCapNumber = 0;
    const hardCapNumber = 100;
    const softCap = ethers.utils.parseUnits(softCapNumber.toFixed(0), 18);
    const hardCap = ethers.utils.parseUnits(hardCapNumber.toFixed(0), 18)

    const saleRate = 1000;
    const dexRate = 1000;
    const liqRatio = 6000; //60%
    const tokensOnSale=10000;
    const zsaleTokenFee=200;//2%
    // createNewCampaign(start,end, purchaseTokenAddress, softCapNumber,hardCapNumber)

    const createCampaignTx = await campaignFactory.createNewCampaign(token.address,
        purchaseTokenAddress,
        ethers.utils.parseUnits(tokensOnSale.toString(), tokenDecimal),
        [
          softCap,
          hardCap, 
          Math.floor(start/1000) ,//  Math.floor(new Date().getTime() / 1000) , // twoHoursTime, thirtySecondsTime
          Math.floor(end/1000) , 
          ethers.utils.parseUnits("0.1", 18),//_minAllocationPerUser
          ethers.utils.parseUnits("1000", 18),////_maxAllocationPerUserTierOne
        ],
        router,
        [liqRatio,30, saleRate.toFixed(),dexRate.toFixed()], //liqRatio, liquidityReleaseTime, listRate,dexRate
        //founderinfo
        //[formData.logo,'',formData.website, formData.twitter, formData.telegram, formData.discord ]
        ['https://place-hold.it/110','dsec', 'https://testtoken.org','https://twitter.com/test','https://testtoken.org', 'http://discord.me'],
        [
          false,//useTeamTokenVesting
          false //UseRaisedFundsvesting
        ],
          //teamtokenvesting
          [0,0,0,0,0],
        //   [
        //     1000,
        //     50,
        //     30,
        //     10,
        //     30
        //   ],
        //Raisedfundsvesting     
        [0,0,0],
        {  
          value: ethers.utils.parseEther("0.00001") 
        });
    let txResult =   await createCampaignTx.wait();
    
    const campaignAddress = txResult.events.filter((f: any)=>f.event=='CampaignCreated')[0].args['createdCampaignAddress'];
    
        
    const totalTockenToLock =  await campaignFactory.campaignTokensLocked(campaignAddress)
    console.log('totalTockenToLock: ', totalTockenToLock, ethers.utils.formatUnits(totalTockenToLock, tokenDecimal))
    
    expect( totalTockenToLock ).equal(ethers.utils.parseUnits(( tokensOnSale + (liqRatio * tokensOnSale / 10000) + (zsaleTokenFee * tokensOnSale/10000) ).toFixed(), tokenDecimal) )

  })

  it('should calculate the right totals for fairlaunch campaigns - with token vesting or fund locking', async ( )=>{
    const start: any = thirtySecondsTime + 10000
    const end: any = thirtyDaysLater
    const purchaseTokenAddress="0x0000000000000000000000000000000000000000"
    const tokenDecimal = 10
    const [owner] = await ethers.getSigners();
    const token = await DecimalTokenArtifact.deploy(tokenDecimal);
    await token.deployed();

    //Approve token
    await (await token.approve(campaignFactory.address, ethers.utils.parseEther('1000000000'))).wait();

    const softCapNumber = 0;
    const hardCapNumber = 100;
    const softCap =  ethers.utils.parseEther(softCapNumber.toString());
    const hardCap = ethers.utils.parseEther(hardCapNumber.toString());

    const saleRate = 1000;
    const dexRate = 1000;
    const liqRatio = 6000; //60%
    const tokensOnSale=10000
    
    

    const purchaseCoindecimal = 18;

    const vestedTokenNumber =  10000;
    const vestedTokens =   ethers.utils.parseUnits(vestedTokenNumber.toFixed(), tokenDecimal);


    await (await token.approve(campaignFactory.address, ethers.utils.parseEther('1000000000'))).wait();
    
    const createCampaignTx = await campaignFactory.createNewCampaign(token.address,
        purchaseTokenAddress,
        ethers.utils.parseUnits(tokensOnSale.toString(),tokenDecimal),
        [
          softCap,
          hardCap, 
          Math.floor(start/1000) ,//  Math.floor(new Date().getTime() / 1000) , // twoHoursTime, thirtySecondsTime
          Math.floor(end/1000) , 
          ethers.utils.parseUnits('0.1', 18),//_minAllocationPerUser
          ethers.utils.parseUnits('1000', 18),////_maxAllocationPerUserTierOne
        ],
        router,

        //liqRatio, liquidityReleaseTime, listRate,dexRate
        [
          liqRatio,
          30, 
          saleRate,
          dexRate
          // ethers.utils.parseUnits(saleRate.toFixed(), tokenDecimal),
          // ethers.utils.parseUnits(dexRate.toFixed(), tokenDecimal),
        ], 
        //founderinfo
        //[formData.logo,'',formData.website, formData.twitter, formData.telegram, formData.discord ]
        ['https://place-hold.it/110','dsec', 'https://testtoken.org','https://twitter.com/test','https://testtoken.org', 'http://discord.me'],
        [
          true,//useTeamTokenVesting
          false //UseRaisedFundsvesting
        ],
          //teamtokenvesting
          [vestedTokens,50,30,10,60],
        //   [
        //     1000,
        //     50,
        //     30,
        //     10,
        //     30
        //   ],
        //Raisedfundsvesting     
        [0,0,0],
        {  
          value: ethers.utils.parseEther("0.00001") 
        });
    let txResult =   await createCampaignTx.wait();
    
    const campaignAddress = txResult.events.filter((f: any)=>f.event=='CampaignCreated')[0].args['createdCampaignAddress'];
    

    const totalTockenToLock =  await campaignFactory.campaignTokensLocked(campaignAddress)
    

    // console.log('TOTAL with VEsted: TOT: ',ethers.utils.formatUnits(totalTockenToLock,tokenDecimal), ', vest: ',
    //   ethers.utils.parseUnits(vestedTokenNumber + ( tokensOnSale + (liqRatio * tokensOnSale / 10000) + (zsaleTokenFee * tokensOnSale/10000) ).toFixed() , tokenDecimal))
    
    expect( totalTockenToLock )
      .equal(vestedTokens.add(
        ethers.utils.parseUnits(( tokensOnSale + (liqRatio * tokensOnSale / 10000) + (zsaleTokenFee * tokensOnSale/10000) ).toFixed(), tokenDecimal) 
      ))
    
  })

  

  it('should send the right fees to Fees Account When Purchase coin is native coin', async ( )=>{
    const start: any = thirtySecondsTime + 10000
    const end: any = thirtyDaysLater

    

    const purchaseTokenAddress="0x0000000000000000000000000000000000000000"
    const purchaseCoindecimal =  18;//await purchaseToken.decimals();
    const [owner] = await ethers.getSigners();
    const token = await DecimalTokenArtifact.deploy(6);
    await token.deployed();
    await (await token.approve(campaignFactory.address, ethers.utils.parseEther('1000000000'))).wait();


    const softCapNumber = 0;
    const hardCapNumber = 10;
    const softCap =  ethers.utils.parseUnits(softCapNumber.toString(), purchaseCoindecimal);
    const hardCap = ethers.utils.parseUnits(hardCapNumber.toString(), purchaseCoindecimal)
    
    const saleRate = 1000;
    const dexRate = 1000;
    const liqRatio = 6000; //60%
    const tokenDecimal = await token.decimals()
    const tokensOnSale=100000;
    

    let snapshotId;

    try{
    
      const createCampaignTx = await campaignFactory.createNewCampaign(token.address,
          purchaseTokenAddress,
          ethers.utils.parseUnits(tokensOnSale.toString(), tokenDecimal),
          [
            softCap,
            hardCap, 
            Math.floor(start/1000) ,//  Math.floor(new Date().getTime() / 1000) , // twoHoursTime, thirtySecondsTime
            Math.floor(end/1000) ,             
            ethers.utils.parseUnits('0.1', purchaseCoindecimal),//_minAllocationPerUser
            ethers.utils.parseUnits('1000', purchaseCoindecimal),////_maxAllocationPerUserTierOne
          ],
          router,

          //liqRatio, liquidityReleaseTime, listRate,dexRate
          [
            liqRatio,
            30, 
            saleRate,
            dexRate
            // ethers.utils.parseUnits(saleRate.toFixed(), tokenDecimal),
            // ethers.utils.parseUnits(dexRate.toFixed(), tokenDecimal),
          ], 
          //founderinfo
          //[formData.logo,'',formData.website, formData.twitter, formData.telegram, formData.discord ]
          ['https://place-hold.it/110','dsec', 'https://testtoken.org','https://twitter.com/test','https://testtoken.org', 'http://discord.me'],
          [
            false,//useTeamTokenVesting
            false //UseRaisedFundsvesting
          ],
            //teamtokenvesting
            [0,50,30,10,60],
          //   [
          //     1000,
          //     50,
          //     30,
          //     10,
          //     30
          //   ],
          //Raisedfundsvesting     
          [0,0,0],
          {  
            value: ethers.utils.parseEther("0.00001") 
          });
      let txResult =   await createCampaignTx.wait();
      
      const campaignAddress = txResult.events.filter((f: any)=>f.event=='CampaignCreated')[0].args['createdCampaignAddress'];
      

      const campaign =  CampaignArtifact.attach(campaignAddress)
      // const totalTockenToLock = await campaign.totalTokensExpectedToBeLocked()
      
      // let txAppr = await token.approve(campaignFactory.address, ethers.utils.parseUnits((await token.totalSupply()).toString(), tokenDecimal));
      // await txAppr.wait();

      
      // let txTrsfr = await campaignFactory.transferTokens(campaignAddress)
      // await txTrsfr.wait();

      console.log('created Campaign successfully')

      const zsalesWalletAddress = await campaignFactory.zsalesWalletAddress();  
      
      snapshotId = await takeSnapshot();
      await advanceTimeTo(Math.floor(twoHoursTime/1000) );

      const [owner2, newSigner] = await ethers.getSigners();
      let campaignContractAsNewSigner = campaign.connect(newSigner);
      const bidPrice = ethers.utils.parseUnits('10', purchaseCoindecimal);

      let tx = await campaignContractAsNewSigner.submitBid([],0, {
        value: bidPrice
      } );
            
      let txRes = await tx.wait();
      
      const totalCoinReceived = await campaignContractAsNewSigner.totalCoinReceived()
      

      //Finalize
      let campaignContractAsOwner = campaign.connect(owner2);
      let txFinalize = await campaignContractAsOwner.finalizeAndSetupLiquidity();
      await txFinalize.wait();
      
      expect( +ethers.utils.formatUnits( await  owner2.provider.getBalance(zsalesWalletAddress) , purchaseCoindecimal))
      .equal (0.2)

      expect( +ethers.utils.formatUnits( await token.balanceOf(zsalesWalletAddress), tokenDecimal))
      .equal (zsaleTokenFee * tokensOnSale/10000)

    }catch(err){
      console.error('Error testing fees: ', err)
      throw err;
    }
    finally{
        if(snapshotId){
            await revertToSnapshot(snapshotId);
        }
        
    }
  })

  

  it('should send the right fees to Fees Account When PurchaseCoin is non 18 Decimal ERC20', async ( )=>{
    const start: any = thirtySecondsTime + 10000
    const end: any = thirtyDaysLater

    const purchaseToken = await DecimalTokenArtifact.deploy(6);
    await purchaseToken.deployed();

    const purchaseTokenAddress=purchaseToken.address;//"0x0000000000000000000000000000000000000000"
    const purchaseCoindecimal =  await purchaseToken.decimals();
    const [owner] = await ethers.getSigners();
    const token = await DecimalTokenArtifact.deploy(6);
    await token.deployed();
    await (await token.approve(campaignFactory.address, ethers.utils.parseEther('1000000000'))).wait();

    const softCapNumber = 0;
    const hardCapNumber = 10;
    const softCap =  ethers.utils.parseUnits(softCapNumber.toString(), purchaseCoindecimal);
    const hardCap = ethers.utils.parseUnits(hardCapNumber.toString(), purchaseCoindecimal)
    
    const saleRate = 1000;
    const dexRate = 1000;
    const liqRatio = 6000; //60%
    const tokenDecimal = await token.decimals()
    const tokensOnSale=50000
    

    let snapshotId;

    try{
    
      const createCampaignTx = await campaignFactory.createNewCampaign(token.address,
          purchaseTokenAddress,
          ethers.utils.parseUnits(tokensOnSale.toString(), tokenDecimal),
          [
            softCap,
            hardCap, 
            Math.floor(start/1000) ,//  Math.floor(new Date().getTime() / 1000) , // twoHoursTime, thirtySecondsTime
            Math.floor(end/1000) , 
            ethers.utils.parseUnits('0.1', purchaseCoindecimal),//_minAllocationPerUser
            ethers.utils.parseUnits('1000', purchaseCoindecimal),////_maxAllocationPerUserTierOne
          ],
          router,

          //liqRatio, liquidityReleaseTime, listRate,dexRate
          [
            liqRatio,
            30, 
            saleRate,
            dexRate
            // ethers.utils.parseUnits(saleRate.toFixed(), tokenDecimal),
            // ethers.utils.parseUnits(dexRate.toFixed(), tokenDecimal),
          ], 
          //founderinfo
          //[formData.logo,'',formData.website, formData.twitter, formData.telegram, formData.discord ]
          ['https://place-hold.it/110','dsec', 'https://testtoken.org','https://twitter.com/test','https://testtoken.org', 'http://discord.me'],
          [
            false,//useTeamTokenVesting
            false //UseRaisedFundsvesting
          ],
            //teamtokenvesting
            [0,50,30,10,60],
          //   [
          //     1000,
          //     50,
          //     30,
          //     10,
          //     30
          //   ],
          //Raisedfundsvesting     
          [0,0,0],
          {  
            value: ethers.utils.parseEther("0.00001") 
          });
      let txResult =   await createCampaignTx.wait();
      
      const campaignAddress = txResult.events.filter((f: any)=>f.event=='CampaignCreated')[0].args['createdCampaignAddress'];
      

      const campaign =  CampaignArtifact.attach(campaignAddress)
      // const totalTockenToLock = await campaign.totalTokensExpectedToBeLocked()
      
      // let txAppr = await token.approve(campaignFactory.address, ethers.utils.parseUnits((await token.totalSupply()).toString(), tokenDecimal));
      // await txAppr.wait();

      
      // let txTrsfr = await campaignFactory.transferTokens(campaignAddress)
      // await txTrsfr.wait();

      const zsalesWalletAddress = await campaignFactory.zsalesWalletAddress();  
      
      snapshotId = await takeSnapshot();
      await advanceTimeTo(Math.floor(twoHoursTime/1000) );

      const [owner2, newSigner] = await ethers.getSigners();
      let campaignContractAsNewSigner = campaign.connect(newSigner);
      const bidPrice = ethers.utils.parseUnits('10', purchaseCoindecimal);

      let tx;
      if(purchaseTokenAddress=="0x0000000000000000000000000000000000000000"){
        tx = await campaignContractAsNewSigner.submitBid([],0, {
          value: bidPrice
        } );
      }else{
        //Transfer funds to newSigner
        let txTrf = await purchaseToken.transfer(newSigner.address, ethers.utils.parseUnits('1000', purchaseCoindecimal));
        await txTrf.wait();

        let txApprBid = await purchaseToken.connect(newSigner).approve(campaignAddress, ethers.utils.parseUnits('10000', purchaseCoindecimal));
        await txApprBid.wait();

        tx = await campaignContractAsNewSigner.submitBid([],bidPrice, {
          // value: ethers.utils.formatUnits( ethers.utils.parseEther("10"), 'wei')
        } );
      }
      
      let txRes = await tx.wait();

      const totalCoinReceived = await campaignContractAsNewSigner.totalCoinReceived()
      
      //Finalize
      let campaignContractAsOwner = campaign.connect(owner2);
      let txFinalize = await campaignContractAsOwner.finalizeAndSetupLiquidity();
      await txFinalize.wait();
      expect( +ethers.utils.formatUnits( await purchaseToken.balanceOf(zsalesWalletAddress), purchaseCoindecimal))
      .equal (0.2)

      expect( +ethers.utils.formatUnits( await token.balanceOf(zsalesWalletAddress), tokenDecimal))
      .equal (zsaleTokenFee * tokensOnSale/10000)

    }catch(err){
      console.error('Error testing fees with non 18 decimals: ', err)
      throw err;
    }
    finally{
        if(snapshotId){
            await revertToSnapshot(snapshotId);
        }
        
    }
    
    //   .equal(
    //     +ethers.utils.formatUnits( vestedCoins
    //       .add(ethers.utils.parseUnits((  (hardCapNumber * saleRate) + (liqRatio * dexRate * hardCapNumber / 10000) ).toFixed(), tokenDecimal)), tokenDecimal) )

  })

 

  it('stops duplicates contract for the same token except when cancelled', async() => {

      
      let createError;
      let initialSize = await campaignFactory.campaignSize();
      try{

        const token = await DecimalTokenArtifact.deploy(6);
        await token.deployed();
        await (await token.approve(campaignFactory.address, ethers.utils.parseEther('1000000000'))).wait();

        const createCampaignTx = await createNewCampaign(twoHoursTime, fourHoursLater, undefined,undefined,undefined,token.address) ;
        assert(createCampaignTx && createCampaignTx.campaign!=undefined,'Create Campaign Failed')

        initialSize = await campaignFactory.campaignSize();

        const createCampaignTx2 = await createNewCampaign(twoHoursTime, fourHoursLater + 1, undefined,undefined,undefined,token.address) ;
        expect(createCampaignTx2).equal(undefined)

                 
      }catch(err){
        // console.error('Error duplicating: ', err);
        
        createError=err;
      }
      expect(createError).to.not.equal(undefined);
      expect(initialSize  - await campaignFactory.campaignSize()).to.equal(0);
      

  });

  

  it('submits initial token to contract successfully', async() => {
   
    let error;
    try{
      
      const [owner] = await ethers.getSigners();
           
      const start = new Date().setSeconds(new Date().getSeconds() + (60*30));
      const {campaign, token} = await createNewCampaign( start,thirtyDaysLater, ethers.constants.AddressZero)
      const campaignAddress= campaign.address;
      console.log('campaignAddress: ', campaignAddress)
      let cmp = campaign; //CampaignArtifact.attach(campaignAddress);

      let campaignStatus = await cmp.status();
      
      let totalTokenTobeTransferred = await campaignFactory.campaignTokensLocked(campaignAddress);
      // console.log('totl: ', totalTokenTobeTransferred)
      // let totalTokenTobeTransferred = ethers.utils.parseEther( 1.3 * parseFloat(ethers.utils.formatUnits(vestingTokens)) +'') //2%            
      // let txAllowance = await token.approve(campaignFactory.address, totalTokenTobeTransferred);
      // await txAllowance.wait();
      
      let afterBalance = await token.balanceOf(campaignAddress);
      // console.log('afterbalance:', afterBalance)

      campaignStatus = await cmp.status();
      expect(+ethers.utils.formatEther(afterBalance)).to.gte(+ethers.utils.formatEther(totalTokenTobeTransferred));
      expect(campaignStatus).to.equal(1);

    }catch(err){
      
      console.error(err)
      error=err;
    }
    expect(error).to.equal(undefined);
    
    

  });

  

  it('accepts Native Coin bids succesfully for non whitelisted sale', async() => {

    
    let error;
    let snapshotId;
    try{
      this.timeout(5000)
      const [owner2, newSigner] = await ethers.getSigners();
      const b4Balance = ethers.utils.formatUnits(await ethers.provider.getBalance(campaignAddress));
      
      snapshotId = await takeSnapshot();
      await advanceTimeTo(Math.floor(twoHoursTime/1000) );
      let cmp = CampaignArtifact.attach(campaignAddress);

      let campaignContractAsNewSigner = cmp.connect(newSigner);

      let tx = await campaignContractAsNewSigner.submitBid([],0, {
        value: ethers.utils.formatUnits( ethers.utils.parseEther("1"), 'wei')
      } );
      let txRes = await tx.wait(); 
          
      const afterBalance = ethers.utils.formatUnits(await ethers.provider.getBalance(campaignAddress));
      
      expect(parseFloat( afterBalance)).to.gt(parseFloat(b4Balance));
      expect(txRes.confirmations).to.gt(0);

    }catch(err){
      
      console.error(err)
      error=err;
    }finally{
      if(snapshotId){
          await revertToSnapshot(snapshotId);
      }
      
    }
    expect(error).to.equal(undefined);
    
    

  });

  it('accepts Erc20 Coin bids succesfully for non whitelisted sale', async() => {

    
    let error;
    let snapshotId;
    try{
      this.timeout(5000);
      const [owner2, newSigner, bidder] = await ethers.getSigners();
      let cmpResult = await createNewCampaign(thirtySecondsTime,thirtyDaysLater, usdcToken.address); //CampaignArtifact.attach(campaignAddress);
      
      let {campaign:cmp,token} = cmpResult;
      
      const campaignStartBalance = parseFloat(ethers.utils.formatUnits(await usdcToken.balanceOf(cmp.address))); 
      const bidderTokenTranserTx = await usdcToken.transfer(bidder.address,ethers.utils.parseEther('10'));
      await bidderTokenTranserTx.wait();
      const bidderStartBalance = parseFloat(ethers.utils.formatUnits(await usdcToken.balanceOf(bidder.address))); 
      

      let campaignStatus = await cmp.status();      
      
      snapshotId = await takeSnapshot();
      await advanceTimeTo(Math.floor(twoHoursTime/1000) );

      let campaignContractAsBidder = cmp.connect(bidder);

      await (await usdcToken.connect(bidder).approve(campaignContractAsBidder.address, ethers.utils.formatUnits( ethers.utils.parseEther("200"), 'wei'), {
        // from: bidder.address
      }) ).wait();
      

      let txSubmit = await campaignContractAsBidder.submitBid([],ethers.utils.formatUnits( ethers.utils.parseEther("0.15"), 'wei'), {
        //value: ethers.utils.parseEther('0.15')
      } );
      let txRes = await txSubmit.wait(); 
          
      const bidderAfterBalance = parseFloat(ethers.utils.formatUnits(await usdcToken.balanceOf(bidder.address))); 
      const camapignAfterBalance = parseFloat(ethers.utils.formatUnits(await usdcToken.balanceOf(cmp.address)));
      
      expect( camapignAfterBalance).to.gt(campaignStartBalance);
      expect(txRes.confirmations).to.gt(0);

    }catch(err){
      
      console.error(err)
      error=err;
    }finally{
      if(snapshotId){
          await revertToSnapshot(snapshotId);
      }
      
    }
    expect(error).to.equal(undefined);
    
    

  });

  it('accepts bids succesfully for whitelisted sale', async() => {

    
    let error;
    let snapshotId;
    try{
      this.timeout(5000)
      const [owner, owner2, newSigner,tSigner,fSigner] = await ethers.getSigners();

      
      const now = new Date();
      
      const timeLater = now.setSeconds(now.getSeconds() + (60*30));
        
      let {campaign:cmp,token} = await createNewCampaign(timeLater,thirtyDaysLater);
       //add eligible droppers
      const whitelist=[owner.address, owner2.address, newSigner.address,tSigner.address,fSigner.address];
            
      let vestingTokens = await campaignFactory.campaignTokensLocked(cmp.address);
      
      // Get elligble addresses - use address 0 - 10
      const leafNodes = whitelist.map((i,ix) => {        
        const packed = ethers.utils.solidityPack(["address"], [ i])
        // return keccak256(i, toWei(ix));
        return keccak256(packed);        
      })

      
      // Generate merkleTree from leafNodes
      const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true });
      // Get root hash from merkle tree
      const merkleRoot = merkleTree.getRoot();
      
      let tx2 = await cmp.submitTier2Whitelist( merkleRoot, {
      });
      await tx2.wait();
      
      const b4Balance = ethers.utils.formatUnits(await ethers.provider.getBalance(cmp.address));
      
      snapshotId = await takeSnapshot();
      await advanceTimeTo(Math.floor(timeLater/1000) );
      
      const packed = ethers.utils.solidityPack(["address"], [ newSigner.address])
      const proof = merkleTree.getHexProof(keccak256(packed))

      let campaignContractAsNewSigner = cmp.connect(newSigner);
      
      let tx = await campaignContractAsNewSigner.submitBid(proof,ethers.utils.parseEther('0.1'), {
        value: ethers.utils.parseEther('0.1')
      } );
      let txRes = await tx.wait();
      
      const afterBalance = ethers.utils.formatUnits(await ethers.provider.getBalance(cmp.address));
      
      expect(parseFloat( afterBalance)).to.gt(parseFloat(b4Balance));
      expect(txRes.confirmations).to.gt(0);

    }catch(err){
      
      console.error(err)
      error=err;
    }finally{
      if(snapshotId){
          await revertToSnapshot(snapshotId);
      }
      
    }
    expect(error).to.equal(undefined);
    
    

  });

  it('accepts Native Coin bids succesfully from tier0 participants within salestarttime - 3 hours', async() => {
    //Tier 0 are NFT Holders - and can trdae 1 hour before
    
    let error;
    let snapshotId;
    try{
      this.timeout(5000)
      const [owner2, newSigner] = await ethers.getSigners();

      await (await campaignFactory.setTierStatus(0, true)).wait();

      const now = new Date();
      
      const oneHoursTime = new Date().setHours(now.getHours()+1);
      const twoHoursTime = 120000 + new Date().setHours(now.getHours()+2);
      const threeHoursTime = new Date().setHours(now.getHours()+3);
      const fourHoursTime = new Date().setHours(now.getHours()+4);

      console.log(`Now ${now.toISOString()}, oneHoursTime ${new Date(oneHoursTime).toISOString()}, twoHoursTime ${new Date(twoHoursTime).toISOString()} `)
      console.log('To start:', threeHoursTime, ', 2hourstime:', twoHoursTime)
      let nftBalance  = await zsalesNftToken.balanceOf(owner2.address, 0)
      console.log('nft balance is ', nftBalance)
      expect(nftBalance).gte(1);

      let txNftTransfer = await zsalesNftToken.safeTransferFrom(owner2.address, newSigner.address, 0, 1, "0x00");
      await txNftTransfer.wait();

      nftBalance  = await zsalesNftToken.balanceOf(newSigner.address, 0)
      console.log('nft balance for new signer is ', nftBalance)

      let cmpResult = await createNewCampaign(fourHoursTime,thirtyDaysLater); //CampaignArtifact.attach(campaignAddress);
      
      let {campaign,token} = cmpResult;
      let campaignAddress = campaign.address;

      const b4Balance = ethers.utils.formatUnits(await ethers.provider.getBalance(campaignAddress));
      
      snapshotId = await takeSnapshot();
      await advanceTimeTo(Math.floor(twoHoursTime/1000)  );
      let cmp = CampaignArtifact.attach(campaignAddress);

      let campaignContractAsNewSigner = cmp.connect(newSigner);

      let tx = await campaignContractAsNewSigner.submitBid([],0, {
        value: ethers.utils.formatUnits( ethers.utils.parseEther("0.15"), 'wei')
      } );
      let txRes = await tx.wait(); 
          
      const afterBalance = ethers.utils.formatUnits(await ethers.provider.getBalance(campaignAddress));
      
      expect(parseFloat( afterBalance)).to.gt(parseFloat(b4Balance));
      expect(txRes.confirmations).to.gt(0);

    }catch(err){
      
      console.error(err)
      error=err;
    }finally{
      await (await campaignFactory.setTierStatus(0, false)).wait();
      if(snapshotId){
          await revertToSnapshot(snapshotId);
      }
      
    }
    expect(error).to.equal(undefined);
    
    

  });

  it('rejects Native Coin bids succesfully from tier0 participants if not within salestarttime - 3 hours', async() => {
    //Tier 0 are NFT Holders - and can trdae 3 hour before
    
    let error: Error|undefined;
    let snapshotId;
    try{
      this.timeout(5000)
      const [owner2, newSigner, thirdSigner] = await ethers.getSigners();

      await (await campaignFactory.setTierStatus(0, true)).wait();

      const now = new Date();
      
      const oneHoursTime = new Date().setHours(now.getHours()+1);
      const twoHoursTime = 120000 + new Date().setHours(now.getHours()+2);
      const threeHoursTime = new Date().setHours(now.getHours()+3);
      const fourHoursTime = new Date().setHours(now.getHours()+4);

      let nftBalance  = await zsalesNftToken.balanceOf(owner2.address, 0)
      
      expect(nftBalance).gte(1);

      let txNftTransfer = await zsalesNftToken.safeTransferFrom(owner2.address, newSigner.address, 0, 1, "0x00");
      await txNftTransfer.wait();

      nftBalance  = await zsalesNftToken.balanceOf(newSigner.address, 0)
      console.log('nft balance for new signer is ', nftBalance)

      let cmpResult = await createNewCampaign(fourHoursTime,thirtyDaysLater); 
      
      let {campaign,token} = cmpResult;
      let campaignAddress = campaign.address;

      const b4Balance = ethers.utils.formatUnits(await ethers.provider.getBalance(campaignAddress));
      
      snapshotId = await takeSnapshot();
      // await advanceTimeTo(Math.floor(twoHoursTime/1000)  );
      let cmp = CampaignArtifact.attach(campaignAddress);

      let campaignContractAsNewSigner = cmp.connect(newSigner);

      let tx = await campaignContractAsNewSigner.submitBid([],0, {
        value: ethers.utils.formatUnits( ethers.utils.parseEther("0.15"), 'wei')
      } );
      let txRes = await tx.wait(); 
          
      const afterBalance = ethers.utils.formatUnits(await ethers.provider.getBalance(campaignAddress));
      
      expect(parseFloat( afterBalance)).to.gt(parseFloat(b4Balance));
      expect(txRes.confirmations).to.gt(0);

    }catch(err: any){
      
      console.error(err)
      error=err;
    }finally{
      await (await campaignFactory.setTierStatus(0, false)).wait();
      if(snapshotId){
          await revertToSnapshot(snapshotId);
      }
      
    }
    expect(error).to.not.equal(undefined);
    expect(error?.message).contains('SaleNotStarted()');
    

  });

  it('rejects Native Coin bids from non-tier0 participants if not within salestarttime', async() => {
    //Tier 0 are NFT Holders - and can trdae 3 hour before
    
    let error: Error|undefined;
    let snapshotId;
    try{
      this.timeout(5000)
      const [owner2, newSigner, thirdSigner] = await ethers.getSigners();

      await (await campaignFactory.setTierStatus(0, true)).wait();

      const now = new Date();
      
      const oneHoursTime = new Date().setHours(now.getHours()+1);
      const twoHoursTime = 120000 + new Date().setHours(now.getHours()+2);
      const threeHoursTime = new Date().setHours(now.getHours()+3);
      const fourHoursTime = new Date().setHours(now.getHours()+4);

      let nftBalance  = await zsalesNftToken.balanceOf(thirdSigner.address, 0)
      expect(nftBalance).eq(0);

      let cmpResult = await createNewCampaign(fourHoursTime,thirtyDaysLater); 
      
      let {campaign,token} = cmpResult;
      let campaignAddress = campaign.address;

      const b4Balance = ethers.utils.formatUnits(await ethers.provider.getBalance(campaignAddress));
      
      snapshotId = await takeSnapshot();
      await advanceTimeTo(Math.floor(twoHoursTime/1000)  );
      let cmp = CampaignArtifact.attach(campaignAddress);

      let campaignContractAsNewSigner = cmp.connect(thirdSigner);

      let tx = await campaignContractAsNewSigner.submitBid([],0, {
        value: ethers.utils.formatUnits( ethers.utils.parseEther("0.15"), 'wei')
      } );
      let txRes = await tx.wait(); 
          
      const afterBalance = ethers.utils.formatUnits(await ethers.provider.getBalance(campaignAddress));
      
      expect(parseFloat( afterBalance)).to.gt(parseFloat(b4Balance));
      expect(txRes.confirmations).to.gt(0);

    }catch(err: any){
      
      console.error(err)
      error=err;
    }finally{
      await (await campaignFactory.setTierStatus(0, false)).wait();
      if(snapshotId){
          await revertToSnapshot(snapshotId);
      }
      
    }
    expect(error).to.not.equal(undefined);
    expect(error?.message).contains('NotInTier0()');
    

  });

  it('allows to finalize succesfully when at least softcap is hit - native coin', async() => {//softcap already transferred in previoud step

    
    let error, snapshotId;
    try{
      this.timeout(5000)
      const [owner, newSigner] = await ethers.getSigners();

      const now = new Date();
      
      const timeEarlier = now.setSeconds(now.getSeconds() - (60*30));

      const tierStatus = await campaignFactory.getTierStatus(1)
      console.log('tierstatus:', tierStatus)
        
      let {campaign,token} = await createNewFairLaunchCampaign(timeEarlier,thirtyDaysLater);
      const campaignAddress=campaign.address;
      
      const b4Balance = ethers.utils.formatUnits(await ethers.provider.getBalance(campaignAddress));      
      snapshotId = await takeSnapshot();
      const currentTime = await getCurrentBlockTimeStamp()
      await advanceTimeTo(Math.floor((currentTime + 30000 )) );

      let cmp = CampaignArtifact.attach(campaignAddress);
      const tokenForSaleAddress = await cmp.tokenAddress();

      const saleInfo = await cmp.saleInfo()

      const tokenForSale = TokenArtifact.attach(tokenForSaleAddress);

      const zsalesWalletAddress = await campaignFactory.zsalesWalletAddress()

      const zsalesWalletStartBalance = parseFloat(ethers.utils.formatUnits(await tokenForSale.balanceOf(zsalesWalletAddress))); 

      let campaignContractAsNewSigner = cmp.connect(newSigner);
      
      let txTransfer = await campaignContractAsNewSigner.submitBid([],ethers.utils.parseEther('0.1'), {
        value: ethers.utils.parseEther('0.1'),
        gasLimit: 3000000
      } );
      let txResTransfer = await txTransfer.wait(); 

      
      const balance = ethers.utils.formatUnits(await ethers.provider.getBalance(campaignAddress));      
      expect(parseFloat( balance)).to.gte(parseFloat('0.1'));
  
      const endTime = await campaign.getEndDate();
      advanceTimeTo( parseInt( ethers.utils.formatUnits(endTime.add( 1), '0')) );

  
      const gasFeeData = await ethers.provider.getFeeData();
      console.log('Fair launch rate:', await campaign.calcFairLaunchRate());

      const tx = await campaign.finalizeAndSetupLiquidity({
        
        maxFeePerGas: gasFeeData.maxFeePerGas,// should use gasprice for bsc, since it doesnt support eip 1559 yet
        maxPriorityFeePerGas: gasFeeData.maxPriorityFeePerGas
      });

      const txRes = await tx.wait();          
      
      expect(txRes.confirmations).to.gt(0);
      expect(txRes.status).to.equal(1);

      const campaignStatus = await campaign.status();      
      expect(campaignStatus).to.equal(4);

      console.log('LP Token Address:', await cmp.liquidityPairAddress())
      console.log('LP Token Locker Address:', await cmp.liquidityPairLockerAddress())

      let lpToken = TokenArtifact.attach(await cmp.liquidityPairAddress());
      const lpLockedBalance = parseFloat(ethers.utils.formatUnits(await lpToken.balanceOf(await cmp.liquidityPairLockerAddress()))); 

      console.log('LP Token Locker Balance:', lpLockedBalance)
      expect(lpLockedBalance).to.greaterThan(0);

      const zsalesWalletFinishBalance = parseFloat(ethers.utils.formatUnits(await tokenForSale.balanceOf(zsalesWalletAddress))); 

  
      expect(zsalesWalletFinishBalance).to.gt(zsalesWalletStartBalance)

    }catch(err){
      
      console.error(err)
      error=err;
    }finally{
      if(snapshotId){
          await revertToSnapshot(snapshotId);
      }
      
    }
    expect(error).to.equal(undefined);
    
    

  });

  return;

  it('allows to finalize succesfully when at least softcap is hit - Purchasecoin is non native coin with 18 decimal', async() => {//softcap already transferred in previoud step

    
    let error, snapshotId;
    try{
      this.timeout(5000)
      const [owner, newSigner] = await ethers.getSigners();

      const now = new Date();
      
      const timeEarlier = now.setSeconds(now.getSeconds() - (60*30));

      const tierStatus = await campaignFactory.getTierStatus(1)
      

      const purchaseCoindecimal=18
      const purchaseToken = await DecimalTokenArtifact.deploy(purchaseCoindecimal);
      await purchaseToken.deployed();

      const purchaseTokenAddress=purchaseToken.address;
        
      let {campaign,token} = await createNewCampaign(timeEarlier,thirtyDaysLater, purchaseTokenAddress);
      const campaignAddress=campaign.address;

      //Transfer funds to newSigner
      let txTrf = await purchaseToken.transfer(newSigner.address, ethers.utils.parseUnits('1000', purchaseCoindecimal));
      await txTrf.wait();

      let txApprBid = await purchaseToken.connect(newSigner).approve(campaignAddress, ethers.utils.parseUnits('10000', purchaseCoindecimal));
      await txApprBid.wait();

      
      const b4Balance = ethers.utils.formatUnits(await purchaseToken.balanceOf(campaignAddress));      
      snapshotId = await takeSnapshot();
      const currentTime = await getCurrentBlockTimeStamp()
      await advanceTimeTo(Math.floor((currentTime + 30000 )) );

      let cmp = CampaignArtifact.attach(campaignAddress);
      const tokenForSaleAddress = await cmp.tokenAddress();

      const saleInfo = await cmp.saleInfo()

      const tokenForSale = TokenArtifact.attach(tokenForSaleAddress);

      const zsalesWalletAddress = await campaignFactory.zsalesWalletAddress()

      const zsalesWalletStartBalance = parseFloat(ethers.utils.formatUnits(await tokenForSale.balanceOf(zsalesWalletAddress))); 

      let campaignContractAsNewSigner = cmp.connect(newSigner);
      
      let txTransfer = await campaignContractAsNewSigner.submitBid([],ethers.utils.parseEther('0.1'), {
        //value: ethers.utils.parseEther('0.0'),
        gasLimit: 5000000
      } );
      let txResTransfer = await txTransfer.wait(); 

      
      const balance = ethers.utils.formatUnits(await purchaseToken.balanceOf(campaignAddress));      
      expect(parseFloat( balance)).to.gte(parseFloat('0.1'));
  
      const endTime = await campaign.getEndDate();
      advanceTimeTo( parseInt( ethers.utils.formatUnits(endTime.add( 1), '0')) );

  
      const gasFeeData = await ethers.provider.getFeeData();
      const tx = await campaign.finalizeAndSetupLiquidity({
        
        maxFeePerGas: gasFeeData.maxFeePerGas,// should use gasprice for bsc, since it doesnt support eip 1559 yet
        maxPriorityFeePerGas: gasFeeData.maxPriorityFeePerGas
      });

      const txRes = await tx.wait();          
      
      expect(txRes.confirmations).to.gt(0);
      expect(txRes.status).to.equal(1);

      const campaignStatus = await campaign.status();      
      expect(campaignStatus).to.equal(4);

      let lpToken = TokenArtifact.attach(await cmp.liquidityPairAddress());
      const lpLockedBalance = parseFloat(ethers.utils.formatUnits(await lpToken.balanceOf(await cmp.liquidityPairLockerAddress()))); 

      expect(lpLockedBalance).to.greaterThan(0);

      const zsalesWalletFinishBalance = parseFloat(ethers.utils.formatUnits(await tokenForSale.balanceOf(zsalesWalletAddress))); 

  
      expect(zsalesWalletFinishBalance).to.gt(zsalesWalletStartBalance)

    }catch(err){
      
      console.error(err)
      error=err;
    }finally{
      if(snapshotId){
          await revertToSnapshot(snapshotId);
      }
      
    }
    expect(error).to.equal(undefined);
    
    

  });

  it('allows to finalize succesfully when at least softcap is hit - Purchasecoin is non native coin with non-18 decimal', async() => {//softcap already transferred in previoud step

    
    let error, snapshotId;
    try{
      this.timeout(5000)
      const [owner, newSigner] = await ethers.getSigners();

      const now = new Date();
      
      const timeEarlier = now.setSeconds(now.getSeconds() - (60*30));

      const tierStatus = await campaignFactory.getTierStatus(1)
      

      const purchaseCoindecimal= Math.floor(17 * Math.random())
      
      const purchaseToken = await DecimalTokenArtifact.deploy(purchaseCoindecimal);
      await purchaseToken.deployed();

      const purchaseTokenAddress=purchaseToken.address;
        
      let {campaign,token} = await createNewCampaign(timeEarlier,thirtyDaysLater, purchaseTokenAddress);
      const campaignAddress=campaign.address;

      //Transfer funds to newSigner
      let txTrf = await purchaseToken.transfer(newSigner.address, ethers.utils.parseUnits('1000', purchaseCoindecimal));
      await txTrf.wait();

      let txApprBid = await purchaseToken.connect(newSigner).approve(campaignAddress, ethers.utils.parseUnits('10000', purchaseCoindecimal));
      await txApprBid.wait();

      
      const b4Balance = ethers.utils.formatUnits(await purchaseToken.balanceOf(campaignAddress), purchaseCoindecimal);      
      snapshotId = await takeSnapshot();
      const currentTime = await getCurrentBlockTimeStamp()
      await advanceTimeTo(Math.floor((currentTime + 30000 )) );

      let cmp = CampaignArtifact.attach(campaignAddress);
      const tokenForSaleAddress = await cmp.tokenAddress();

      const saleInfo = await cmp.saleInfo()
      

      const tokenForSale = TokenArtifact.attach(tokenForSaleAddress);

      const zsalesWalletAddress = await campaignFactory.zsalesWalletAddress()

      const zsalesWalletStartBalance = parseFloat(ethers.utils.formatUnits(await tokenForSale.balanceOf(zsalesWalletAddress))); 

      let campaignContractAsNewSigner = cmp.connect(newSigner);
      let txTransfer = await campaignContractAsNewSigner.submitBid([],ethers.utils.parseUnits('0.1',purchaseCoindecimal), {
        //value: ethers.utils.parseEther('0.0'),
        gasLimit: 5000000
      } );
      let txResTransfer = await txTransfer.wait(); 

      
      const balance = ethers.utils.formatUnits(await purchaseToken.balanceOf(campaignAddress), purchaseCoindecimal);      
      expect(parseFloat( balance)).to.gte(parseFloat('0.1'));
  
      const endTime = await campaign.getEndDate();
      advanceTimeTo( parseInt( ethers.utils.formatUnits(endTime.add( 1), '0')) );

  
      const gasFeeData = await ethers.provider.getFeeData();
      const tx = await campaign.finalizeAndSetupLiquidity({
        
        maxFeePerGas: gasFeeData.maxFeePerGas,// should use gasprice for bsc, since it doesnt support eip 1559 yet
        maxPriorityFeePerGas: gasFeeData.maxPriorityFeePerGas
      });

      const txRes = await tx.wait();          
      
      expect(txRes.confirmations).to.gt(0);
      expect(txRes.status).to.equal(1);

      const campaignStatus = await campaign.status();      
      expect(campaignStatus).to.equal(4);


      let lpToken = TokenArtifact.attach(await cmp.liquidityPairAddress());
      const lpLockedBalance = parseFloat(ethers.utils.formatUnits(await lpToken.balanceOf(await cmp.liquidityPairLockerAddress()))); 

      expect(lpLockedBalance).to.greaterThan(0);

      const zsalesWalletFinishBalance = parseFloat(ethers.utils.formatUnits(await tokenForSale.balanceOf(zsalesWalletAddress))); 

  
      expect(zsalesWalletFinishBalance).to.gt(zsalesWalletStartBalance)

    }catch(err){
      
      console.error(err)
      error=err;
    }finally{
      if(snapshotId){
          await revertToSnapshot(snapshotId);
      }
      
    }
    expect(error).to.equal(undefined);
    
    

  });

  it('allows finalize succesfully(with raisedFundsVesting) when at least softcap is hit - native coin', async() => {//softcap already transferred in previoud step

    
    let error, snapshotId;
    try{
      this.timeout(5000)
      const [owner, newSigner] = await ethers.getSigners();

      const now = new Date();
      
      const timeEarlier = now.setSeconds(now.getSeconds() - (60*30));

      const tierStatus = await campaignFactory.getTierStatus(1)
        
      let {campaign,token} = await createNewFairLaunchCampaignWithRaisedFundsVesting(timeEarlier,thirtyDaysLater);
      const campaignAddress=campaign.address;
      
      const b4Balance = ethers.utils.formatUnits(await ethers.provider.getBalance(campaignAddress));      
      snapshotId = await takeSnapshot();
      const currentTime = await getCurrentBlockTimeStamp()
      await advanceTimeTo(Math.floor((currentTime + 30000 )) );

      let cmp = CampaignArtifact.attach(campaignAddress);
      const tokenForSaleAddress = await cmp.tokenAddress();

      const saleInfo = await cmp.saleInfo()

      const tokenForSale = TokenArtifact.attach(tokenForSaleAddress);

      const zsalesWalletAddress = await campaignFactory.zsalesWalletAddress()

      const zsalesWalletStartBalance = parseFloat(ethers.utils.formatUnits(await tokenForSale.balanceOf(zsalesWalletAddress))); 

      let campaignContractAsNewSigner = cmp.connect(newSigner);
      
      let txTransfer = await campaignContractAsNewSigner.submitBid([],ethers.utils.parseEther('0.1'), {
        value: ethers.utils.parseEther('0.1'),
        gasLimit: 3000000
      } );
      let txResTransfer = await txTransfer.wait(); 

      
      const balance = ethers.utils.formatUnits(await ethers.provider.getBalance(campaignAddress));      
      expect(parseFloat( balance)).to.gte(parseFloat('0.1'));
  
      const endTime = await campaign.getEndDate();
      advanceTimeTo( parseInt( ethers.utils.formatUnits(endTime.add( 1), '0')) );

  
      const gasFeeData = await ethers.provider.getFeeData();
      const tx = await campaign.finalizeAndSetupLiquidity({
        
        maxFeePerGas: gasFeeData.maxFeePerGas,// should use gasprice for bsc, since it doesnt support eip 1559 yet
        maxPriorityFeePerGas: gasFeeData.maxPriorityFeePerGas
      });

      const txRes = await tx.wait();          
      
      expect(txRes.confirmations).to.gt(0);
      expect(txRes.status).to.equal(1);

      const campaignStatus = await campaign.status();      
      expect(campaignStatus).to.equal(4);

      let lpToken = TokenArtifact.attach(await cmp.liquidityPairAddress());
      const lpLockedBalance = parseFloat(ethers.utils.formatUnits(await lpToken.balanceOf(await cmp.liquidityPairLockerAddress()))); 

      
      expect(lpLockedBalance).to.greaterThan(0);

      const zsalesWalletFinishBalance = parseFloat(ethers.utils.formatUnits(await tokenForSale.balanceOf(zsalesWalletAddress))); 

  
      expect(zsalesWalletFinishBalance).to.gt(zsalesWalletStartBalance)
      
      const dexLocker = DexLockerArtifact.attach(await cmp._dexLocker())
      
      const raisedFundsVaultAddress = await dexLocker.raisedFundsVaultAddress()
      
      const raiseFundsBalance = ethers.utils.formatUnits(await ethers.provider.getBalance(raisedFundsVaultAddress)); 
      const PurchasedCoinVestingVault = PurchasedCoinVestingVault__factory.connect(raisedFundsVaultAddress);
      
    }catch(err){
      
      console.error(err)
      error=err;
    }finally{
      if(snapshotId){
          await revertToSnapshot(snapshotId);
      }
      
    }
    expect(error).to.equal(undefined);
    
    

  }); 

  it('allows finalize succesfully(with raisedFundsVesting) when at least softcap is hit - ERC20 coin', async() => {//softcap already transferred in previoud step

    
    let error, snapshotId;
    try{
      this.timeout(5000)
      const [owner, newSigner] = await ethers.getSigners();

      const now = new Date();
      
      const timeEarlier = now.setSeconds(now.getSeconds() - (60*30));

      const tierStatus = await campaignFactory.getTierStatus(1)
      

      const purchaseCoindecimal= Math.floor(12 * Math.random())      
      const purchaseToken = await DecimalTokenArtifact.deploy(purchaseCoindecimal);
      await purchaseToken.deployed();

      const purchaseTokenAddress=purchaseToken.address;
        
      let {campaign,token} = await createNewFairLaunchCampaignWithRaisedFundsVesting(timeEarlier,thirtyDaysLater, purchaseTokenAddress);
      const campaignAddress=campaign.address;

      //Transfer funds to newSigner
      let txTrf = await purchaseToken.transfer(newSigner.address, ethers.utils.parseUnits('1000', purchaseCoindecimal));
      await txTrf.wait();

      let txApprBid = await purchaseToken.connect(newSigner).approve(campaignAddress, ethers.utils.parseUnits('10000', purchaseCoindecimal));
      await txApprBid.wait();
           
      snapshotId = await takeSnapshot();
      const currentTime = await getCurrentBlockTimeStamp()
      await advanceTimeTo(Math.floor((currentTime + 30000 )) );

      let cmp = CampaignArtifact.attach(campaignAddress);
      const tokenForSaleAddress = await cmp.tokenAddress();

      const saleInfo = await cmp.saleInfo()

      const tokenForSale = TokenArtifact.attach(tokenForSaleAddress);

      let campaignContractAsNewSigner = cmp.connect(newSigner);
      
      let txTransfer = await campaignContractAsNewSigner.submitBid([],ethers.utils.parseUnits('0.1',purchaseCoindecimal), {
        // value: ethers.utils.parseEther('0.1'),
        gasLimit: 3000000
      } );
      let txResTransfer = await txTransfer.wait(); 

        
      const endTime = await campaign.getEndDate();
      advanceTimeTo( parseInt( ethers.utils.formatUnits(endTime.add( 1), '0')) );

  
      const gasFeeData = await ethers.provider.getFeeData();
      const tx = await campaign.finalizeAndSetupLiquidity({
        
        maxFeePerGas: gasFeeData.maxFeePerGas,// should use gasprice for bsc, since it doesnt support eip 1559 yet
        maxPriorityFeePerGas: gasFeeData.maxPriorityFeePerGas
      });

      const txRes = await tx.wait();          
      
      expect(txRes.confirmations).to.gt(0);
      expect(txRes.status).to.equal(1);

      const campaignStatus = await campaign.status();      
      expect(campaignStatus).to.equal(4);

      let lpToken = TokenArtifact.attach(await cmp.liquidityPairAddress());
      const lpLockedBalance = parseFloat(ethers.utils.formatUnits(await lpToken.balanceOf(await cmp.liquidityPairLockerAddress()))); 

      
      expect(lpLockedBalance).to.greaterThan(0);
      
      const dexLocker = DexLockerArtifact.attach(await cmp._dexLocker())      
      const raisedFundsVaultAddress = await dexLocker.raisedFundsVaultAddress()      
      const raiseFundsBalance = ethers.utils.formatUnits(await purchaseToken.balanceOf(raisedFundsVaultAddress) , purchaseCoindecimal); 
      
      expect(+raiseFundsBalance).gt(0)


    }catch(err){
      
      console.error(err)
      error=err;
    }finally{
      if(snapshotId){
          await revertToSnapshot(snapshotId);
      }
      
    }
    expect(error).to.equal(undefined);
    
    

  }); 

  it('owner cannot withdraw tokens in ongoing sale', async ()=>{
    throw(new Error('UnImplemented'))
  })

  it('owner cannot withdraw tokens in successful sale', async ()=>{
    throw(new Error('UnImplemented'))
  })

  it('owner can only withdraw remaining tokens in successful sale', async ()=>{
    throw(new Error('UnImplemented'))
  })

  // it('accepts whitelist succesfully', async() => {

    
  //   let error;
    
  //   try{
  //     this.timeout(5000)
  //     const [owner, owner2, newSigner,tSigner,fSigner] = await ethers.getSigners();
     
  //     const now = new Date();      
  //     const timeLater = now.setSeconds(now.getSeconds() + (60*30));
        
  //     let {campaign:cmp,token} = await createNewCampaign(Math.floor(timeLater/1000),Math.floor(thirtyDaysLater/1000.0));
  //      //add eligible droppers
  //     const whitelist=[owner.address, owner2.address, newSigner.address,tSigner.address,fSigner.address];
       
  //     const leafNodes = whitelist.map((i,ix) => {        
  //       const packed = ethers.utils.solidityPack(["address"], [ i])
  //       // return keccak256(i, toWei(ix));
  //       return keccak256(packed);        
  //     })

  //     // Generate merkleTree from leafNodes
  //     const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true });
  //     // Get root hash from merkle tree
  //     const merkleRoot = merkleTree.getRoot();
      
  //     let tx2 = await cmp.submitTier2Whitelist( merkleRoot, {
  //     });
  //     const txRes = await tx2.wait();

  //     expect(txRes.confirmations).to.gt(0);

  //   }catch(err){
      
  //     console.error(err)
  //     error=err;
  //   }
  //   expect(error).to.equal(undefined);
    
    

  // });




});



// describe("ConfirmAddress", async function () {
  
  

 
//   let ConfirmAddressArtifact ;
  

//   const router = '0xeD37AEDD777B44d34621Fe5cb1CF594dc39C8192';
//   let userAccount :any ;
//   let confirmAddContract :any;
  

//   before('Initialize and Deploy SmartContracts', async () => {
      
//     ConfirmAddressArtifact = await ethers.getContractFactory("ConfirmAddress");
//     userAccount = (await ethers.getSigners())[0];

    
//     confirmAddContract = await ConfirmAddressArtifact.deploy();
//     await confirmAddContract.deployed();
//     console.log('Confirm Address Deployed at  ', confirmAddContract.address );
      
//   });


//   it("Should return true when a contract address is sent to it", async function () {
//     const TokenArtifact = await ethers.getContractFactory("Token");
//     const token = await TokenArtifact.deploy();
//     await token.deployed();
    
//     let addToCheck = token.address;
//     let isContractCheck = await confirmAddContract.isContract(addToCheck);
//     expect(isContractCheck).to.equal(true);
//   });

  
  

//   it('Should return false when a non-contract address is sent to it', async() => {
//     let addToCheck = userAccount.address;
//     let isContractCheck = await confirmAddContract.isContract(addToCheck);
//     expect(isContractCheck).to.equal(false);
    

//   });



// });


