import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';
import { getChainId } from 'hardhat';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {deployments, getNamedAccounts} = hre;
  const {deploy} = deployments;

  const {deployer, tokenOwner} = await getNamedAccounts();
  const chainId = +await getChainId();
  const skipChains = [
    44787,//celo testnet
    1115, // core testnet
    2713017997578000, //dchain test
    2522,//fraxtal test
  ]

  if(!(chainId in skipChains)){

  
    const factory = await deploy('PancakeFactory', {
      from: deployer,
      args: [deployer],
      log: true,
      deterministicDeployment: true
    });

    const weth = await deploy('WBNB', {
      from: deployer,
      args: [],
      log: true,
      deterministicDeployment: true
    });

    const router = await deploy('PancakeRouter', {
      from: deployer,
      args: [factory.address, weth.address],
      log: true,
      deterministicDeployment: true
    });
  }
};
export default func;
func.tags = ['router']; // This sets up a tag so you can execute the script on its own (and its dependencies).