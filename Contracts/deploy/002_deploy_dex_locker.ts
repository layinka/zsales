import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {deployments, getNamedAccounts} = hre;
  const {deploy} = deployments;

  const {deployer, tokenOwner} = await getNamedAccounts();
//

  const dexLocker = await deploy('DexLocker', {
    from: deployer,
    args: [],
    log: true,
  });

  const coinVault = await deploy('PurchasedCoinVestingVault', {
    from: deployer,
    args: [],
    log: true,
  });

  await deploy('DexLockerFactory', {
    from: deployer,
    args: [dexLocker.address, coinVault.address],
    log: true,
  });
};
export default func;
func.tags = ['dexlocker']; // This sets up a tag so you can execute the script on its own (and its dependencies).
func.dependencies=['tokens']