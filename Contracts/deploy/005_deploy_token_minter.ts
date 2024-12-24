import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';
import { getChainId } from 'hardhat';
import { parseEther } from 'ethers/lib/utils';
import { unsupportedDeterministicChains } from '../utils/unsupported-deterministic-deploy-chains';

const defaultFees = [
  parseEther('0.001'),
  parseEther('0.0015'),
  parseEther('0.003'),
]

const defaultTokenPercentFees = [
  0.5,
  0.6,
  0.65,
]

const chainFees:  {[index: number]: any[]} = {
  2522: [
    parseEther('0.001'),
    parseEther('0.0015'),
    parseEther('0.003'),
  ],
  84532: [
    parseEther('0.001'),
    parseEther('0.016'),
    parseEther('0.003'),
  ],
  42220: [//celo
    parseEther('0.75'),
    parseEther('1'),
    parseEther('1.25'),
  ],
  44787: [//celo testnet
    parseEther('0.001'),
    parseEther('0.016'),
    parseEther('0.003'),
  ],
  1115: [//Core testnet
    parseEther('0.001'),
    parseEther('0.016'),
    parseEther('0.003'),
  ],
  1116: [//Core 
    parseEther('1'),
    parseEther('1.5'),
    parseEther('2'),
  ]
}



const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {deployments, getNamedAccounts,ethers} = hre;
  const {deploy} = deployments;

  const {deployer, tokenOwner} = await getNamedAccounts();

  const chainId = +await getChainId();
  console.log('chainId is ', chainId)

  let fees = defaultFees;
  const chainFee = chainFees[+chainId];
  if(chainFee && chainFee.length==3){
    fees=chainFee
  }

  let tokenMinter = await deploy('TokenMinterFactory', {
    from: deployer,
    args: [fees, defaultTokenPercentFees.map(m=>m*100)],
    log: true,
    deterministicDeployment: unsupportedDeterministicChains.includes(chainId) ? undefined: '0xabbbeFFF899127'
  });

  const tknMinterContract = await ethers.getContractAt("TokenMinterFactory", tokenMinter.address);
  if(chainId==7701){
    

    let tx = await tknMinterContract.updateTurnstileAddress('0xEcf044C5B4b867CFda001101c617eCd347095B44');
    await tx.wait();
    console.log('token minter registered for Canto CSR')
  }
  // let fees2 = await tknMinterContract.nativeFees(0);
  // console.log(fees2)

};
export default func;
func.tags = ['token-minter']; // This sets up a tag so you can execute the script on its own (and its dependencies).