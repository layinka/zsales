// import { expect } from "chai";
// import { ContractFactory } from "ethers";
// import { ethers } from "hardhat";
// import {advanceTimeTo, takeSnapshot, revertToSnapshot, formatEtherDateToJs} from './utils';

// describe("LiquidityLockerTest", function () {
//   this.timeout(100000);

//   let now = new Date();
//   let TokenArtifact: ContractFactory;
//   let LiquidityLockerArtifact: ContractFactory;

//   let tokenLockerFactory: ContractFactory;
//   let tokenLocker: any;
//   let token: any;
  

//   const tokenPrice = 2;
//   const minRaisedFunds = 10;
//   const maxRaisedFunds = 40;
//   const liqPercent = 60;


//   async function deployNewLiquidityLocker(totalTokens=1000, firstReleasePercent=50, firstReleaseDays=30, subsequentReleasePercent=25, subsequentReleaseDays=30){
//     const tokenLockerFactory = await ethers.getContractFactory(
//       "TokenLockerV2"
//     );
//     const [owner, secondAcct, thirdAcct] = await ethers.getSigners();
//     const now = new Date();
    
//     const tokenArtifact = await ethers.getContractFactory("Token");

//     const t = await tokenArtifact.deploy();
//     await t.deployed();

//     const tokenAddress = t.address;




//     const tokenLocker = await tokenLockerFactory.deploy(
//       tokenAddress,
//       owner.address,
//       ethers.utils.formatUnits(ethers.utils.parseEther(totalTokens.toString()), 'wei'),
//       firstReleasePercent,
//       firstReleaseDays,
//       subsequentReleasePercent,
//       subsequentReleaseDays
//     );
//     await tokenLocker.deployed();
    
    

    

//     return {tokenContract:t, tokenAddress, tokenLocker};
//   }

//   before("Initialize and Deploy SmartContracts", async () => {
    
//     // TokenArtifact = await ethers.getContractFactory("Token");
//     // token = await TokenArtifact.deploy();
//     // await token.deployed();

//     // LiquidityLockerArtifact = await ethers.getContractFactory(
//     //   "LiquidityLocker"
//     // );
//   });

//   it("Can Deploy TokenLocker", async function () {
//     let error;
//     try {
      
//         const {tokenAddress, tokenLocker } = await deployNewLiquidityLocker();
//         let schdule = await tokenLocker.getVestingCycle();
        

//         for(let i =0; i< schdule.length; i++){
//             console.log('schedule is ', ethers.utils.formatUnits( schdule[i].releaseAmount, 18), ', releaseDate: ', ethers.utils.formatUnits( schdule[i].releaseDate, 0),  '. date: ',  formatEtherDateToJs( schdule[i].releaseDate),  ', hasBeenClaimed:',  schdule[i].hasBeenClaimed)
//         }
//         console.log('-------')
//         const {tokenAddress: tokenAddress2, tokenLocker: tokenLocker2 } = await deployNewLiquidityLocker(1000,30,60,20,30);
//         schdule = await tokenLocker2.getVestingCycle();
        

//         for(let i =0; i< schdule.length; i++){
//             console.log('schedule 2 is ', ethers.utils.formatUnits( schdule[i].releaseAmount, 18), ', releaseDate: ', ethers.utils.formatUnits( schdule[i].releaseDate, 0),  '. date: ',  formatEtherDateToJs( schdule[i].releaseDate),  ', hasBeenClaimed:',  schdule[i].hasBeenClaimed)
//         }
        
        
//         console.log('Released: ', await tokenLocker2.released())

//         console.log('Releasable: ', await tokenLocker2.releasable())

//         expect(schdule).not.undefined;

//     } catch (err) {
//       console.error(err);
//       error = err;
//     }

//     expect(error).to.equal(undefined);
//   });


//   it("Does not release LP tokens if AddLiquidity is not called", async () => {
//     let error;
//     try {
      
//     //   const locker = await deployNewLiquidityLocker();
//     //   const tx = await locker.releaseLPTokens();
//     //   const txRes = await tx.wait();
            
//     } catch (err) {
//       // console.error('Error duplicating: ', err);
//       error = err;
//     }
//     expect(error).to.equal(undefined);
//   });

//   it("Does not release LP tokens before Release time", async () => {
//     let error;
//     try {
//     //   const locker = await deployNewLiquidityLocker();
//     //   const tx = await locker.releaseLPTokens();
//     //   const txRes = await tx.wait();
            
//     } catch (err) {
//       // console.error('Error duplicating: ', err);
//       error = err;
//     }
//     expect(error).to.equal(undefined);
//   });

//   it("Releases LP tokens after Release time", async () => {
//     let error;
//     let snapshotId;
//     try {
//         const {tokenContract,tokenLocker } = await deployNewLiquidityLocker(1000,50,30,20,30);
//         const releaseTime = Date.now() + (24*60*60 * 1000 *  61);

//         //transfer tokens
//         const tokenTranserTx = await tokenContract.transfer(tokenLocker.address,ethers.utils.parseEther('1000'));
//         await tokenTranserTx.wait();

//         let schdule = await tokenLocker.getVestingCycle();     
        
//         snapshotId = await takeSnapshot();
//         await advanceTimeTo( Math.floor( releaseTime/1000) );
//         const tx = await tokenLocker.release();
//         const txRes = await tx.wait();
//         expect(txRes.confirmations).to.gt(0);

//         schdule = await tokenLocker.getVestingCycle();  
//         expect(schdule.length).to.eq(4);
//         expect(+ethers.utils.formatUnits(await tokenLocker.released()) ).to.eq(700);
//         expect(schdule[0].hasBeenClaimed).to.eq(true);
//         expect(schdule[1].hasBeenClaimed).to.eq(true);
//         expect(schdule[2].hasBeenClaimed).to.eq(false);
      
//     } catch (err) {
//       console.error('Error : ', err);
//       error = err;
//     }finally{
//         if(snapshotId){
//             await revertToSnapshot(snapshotId);
//         }
        
//     }
//     expect(error).to.equal(undefined);
//   });


// });
