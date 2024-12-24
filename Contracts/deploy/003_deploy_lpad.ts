import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';
import { getChainId } from 'hardhat';
import { unsupportedDeterministicChains } from '../utils/unsupported-deterministic-deploy-chains';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {deployments, getNamedAccounts, ethers} = hre;
  const {deploy} = deployments;

  const {deployer, tokenOwner} = await getNamedAccounts();

  const chainId = await getChainId();
  console.log('chainId is ', chainId)

  //@ts-ignore
  const dexLockerFactory = await ethers.getContract("DexLockerFactory") 
  //@ts-ignore
  const zsalesNftToken = await ethers.getContract("zSalesNFT")
  //@ts-ignore
  const zsalesToken = await ethers.getContract("zSales")

  

  let campaignImplementation = await deploy('Campaign', {
    from: deployer,
    args: [],
    log: true,
    deterministicDeployment: unsupportedDeterministicChains.includes(+chainId) ? undefined: '0x4762543777FFF89912f7'
  });

  let CampaignList = await deploy('CampaignList', {
    from: deployer,
    args: [dexLockerFactory.address,zsalesToken.address,zsalesNftToken.address, campaignImplementation.address],
    log: true,
    deterministicDeployment: unsupportedDeterministicChains.includes(+chainId) ? undefined: '0xabbbeFFF23498888991427'
  });

  if(chainId=='7701'){
    const cContract = await ethers.getContractAt("CampaignList", CampaignList.address);

    let tx = await cContract.updateTurnstileAddress('0xEcf044C5B4b867CFda001101c617eCd347095B44');
    await tx.wait();
    console.log('Campaign List registered for Canto CSR')
  }


};
export default func;
func.tags = ['l-pad']; // This sets up a tag so you can execute the script on its own (and its dependencies).
func.dependencies=['tokens','dexlocker']
