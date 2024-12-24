import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {deployments, getNamedAccounts} = hre;
  const {deploy} = deployments;

  const {deployer, tokenOwner} = await getNamedAccounts();

  // await deploy('Token', { //Spare token for tests
  //   from: deployer,
  //   args: [],
  //   log: true,
  // });

  const zSalesToken = await deploy('zSales', {
    contract: 'Token2',
    from: deployer,
    args: ['ZSales','ZSX'],
    log: true,
  });

  console.log('zSales token deployed to : ', zSalesToken.address)

  const zSalesNFT = await deploy('zSalesNFT', {
    contract: 'NFTERC1155',
    from: deployer,
    args: [],
    log: true,
  });
};
export default func;
func.tags = ['tokens']; // This sets up a tag so you can execute the script on its own (and its dependencies).