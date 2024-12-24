import { ethers } from "hardhat";

export async function advanceTimeTo(newTimeStampInSecond: number){
    await ethers.provider.send("evm_mine", [newTimeStampInSecond]);

    // await ethers.provider.send('evm_setNextBlockTimestamp', [newTimeStampInSecond]); 
    // await ethers.provider.send('evm_mine');
}

export async function takeSnapshot(){
    const snapShotId = await ethers.provider.send("evm_snapshot", []);
    return snapShotId;
}

export async function revertToSnapshot(snapShotId: any){
    await ethers.provider.send("evm_revert", [snapShotId]);
    
}

export async function getCurrentBlock() {
    const currentBlock = await ethers.provider.getBlock(await ethers.provider.getBlockNumber());
    return currentBlock;
}

export async function getCurrentBlockTimeStamp() {
    const currentBlock = await ethers.provider.getBlock(await ethers.provider.getBlockNumber());
    let stamp: number = currentBlock.timestamp;
    return stamp;
}


export const monthNames = ["January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
];

export function formatEtherDateToJs(bn){
  const val = ethers.utils.formatUnits(  bn.toString(),0);
  const s = +val ;

  // Create a new JavaScript Date object based on the timestamp
  // multiplied by 1000 so that the argument is in milliseconds, not seconds.
  let date = new Date(s * 1000);
  // Hours part from the timestamp
  const hours = date.getHours();
  // Minutes part from the timestamp
  const minutes = "0" + date.getMinutes();
  // Seconds part from the timestamp
  const seconds = "0" + date.getSeconds();

  const formattedTime = `${monthNames[date.getMonth()].substr(0,3)} ${date.getDate()}, ${date.getFullYear()} ` + hours + ':' + minutes.substr(-2) + ':' + seconds.substr(-2);

  return formattedTime;
}


export function getDateFromEther(bn){
    const val = ethers.utils.formatUnits(  bn.toString(),0);
    const s = +val ;
    // Create a new JavaScript Date object based on the timestamp
    // multiplied by 1000 so that the argument is in milliseconds, not seconds.
    return new Date(s * 1000);
  }