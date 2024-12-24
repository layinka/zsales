import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';

export const monthNames = ["January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
];

function formatDateToJsString(date: Date){
  
  // Hours part from the timestamp
  const hours = date.getHours();
  // Minutes part from the timestamp
  const minutes = "0" + date.getMinutes();
  // Seconds part from the timestamp
  const seconds = "0" + date.getSeconds();

  const formattedTime = `${monthNames[date.getMonth()].substr(0,3)}-${date.getDate()}-${date.getFullYear()} ${hours}:${minutes.substr(-2)}:${seconds.substr(-2)}`;

  return formattedTime;
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {deployments, getNamedAccounts} = hre;
  const {deploy} = deployments;

  const {deployer, tokenOwner} = await getNamedAccounts();

  const dat = formatDateToJsString(new Date())

  const randomToken = await deploy('Token2', {
    from: deployer,
    args: ['TEST-'+ dat,'TEST-'+dat],
    log: true,
  });
};
export default func;
func.tags = ['random-token']; // This sets up a tag so you can execute the script on its own (and its dependencies).