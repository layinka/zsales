import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';
import { unsupportedDeterministicChains } from '../utils/unsupported-deterministic-deploy-chains';
import { getChainId } from 'hardhat';



const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {deployments, getNamedAccounts} = hre;
  const {deploy} = deployments;

  const {deployer, tokenOwner} = await getNamedAccounts();

  const chainId = +await getChainId();
  console.log('chainId is ', chainId)

  const randomToken = await deploy('Multicall3', {
    from: deployer,
    args: [],
    log: true,
    deterministicDeployment: unsupportedDeterministicChains.includes(chainId) ? undefined: true
  });
};
export default func;
func.tags = ['multicall']; // This sets up a tag so you can execute the script on its own (and its dependencies).