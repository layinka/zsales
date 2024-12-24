import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';



const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {deployments, getNamedAccounts} = hre;
  const {deploy} = deployments;

  const {deployer, tokenOwner} = await getNamedAccounts();

  

//   const fair = await deploy('FairLaunchFactory', {
//     from: deployer,
//     args: [],
//     log: true,
//   });
};
export default func;
func.tags = ['fair']; // This sets up a tag so you can execute the script on its own (and its dependencies).