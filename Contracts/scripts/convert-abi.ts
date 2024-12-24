import fs from 'fs';
import { ethers } from 'hardhat';

async function main() {

    const jsonAbi = require("../artifacts/contracts/Campaign.sol/Campaign.json").abi;
    console.log('jsonAbi: ', jsonAbi);
    const iface = new ethers.utils.Interface(jsonAbi);
    console.log(iface.format(ethers.utils.FormatTypes.full));
  
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
    