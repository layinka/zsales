import { HardhatUserConfig, vars } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import 'hardhat-deploy';
import '@nomiclabs/hardhat-ethers';
import 'hardhat-deploy-ethers';
import 'hardhat-contract-sizer';
import {node_url, accounts, addForkConfiguration} from './utils/network';
import "hardhat-gas-reporter"

if(!process.env.MNEMONIC){
	throw new Error('No Mnemonic set')
}
const liveDeploymentAccount = {
	mnemonic: process.env.MNEMONIC //  || "test test test test test test test test test test test junk",
// accountsBalance: "990000000000000000000",
}

// const INFURA_API_KEY = vars.get("INFURA_API_KEY");

const config: HardhatUserConfig = {
  solidity: {
		compilers: [
			{
				version: "0.5.16",
				settings: {
						
						optimizer: {
							enabled: true,
							runs: 200,
							
						}
					}
			},
			{
				version: "0.6.6",
				settings: {
					
					optimizer: {
						enabled: true,
						runs: 200,
						
					}
				}
			},
			{
				version: "0.6.12",
				settings: {
					
					optimizer: {
						enabled: true,
						runs: 200,
						
					}
				}
			},
			{
				version: "0.8.12",
				  settings: {
					  viaIR : true,
					  optimizer: {
						  enabled: true,
						  runs: 200,
						  details: {
							yul: true
						  }
					  }
				  }
			},
			{
				version: '0.8.18',
				settings: {
					optimizer: {
						enabled: true,
						runs: 200,
						details: {
							yul: true,
						},
					},
					viaIR: true,
				},
			},
			{
				version: '0.8.26',
				settings: {
					optimizer: {
						enabled: true,
						runs: 2000,
						details: {
							yul: true,
						},
					},
					viaIR: true,
				},
			},
			{
				version: '0.8.28',
				settings: {
					optimizer: {
						enabled: true,
						runs: 2000,
						details: {
							yul: true,
						},
					},
					viaIR: true,
				},
			},
		],
	},

  namedAccounts: {
		deployer: 0,
		simpleERC20Beneficiary: 1,
		nextBeneficiary: 2,
	},
  ignition: {
    strategyConfig: {
      create2: {
        // To learn more about salts, see the CreateX documentation
        salt: "0x0005600da00af000fb0000000000024360000000000000000000000000000000",
      },
    },
  },

	networks: addForkConfiguration({
		hardhat: {
			initialBaseFeePerGas: 0, // to fix : https://github.com/sc-forks/solidity-coverage/issues/652, see https://github.com/sc-forks/solidity-coverage/issues/652#issuecomment-896330136
			forking: {
				url: `https://celo-alfajores.infura.io/v3/${process.env.INFURA_API_KEY}`,// "https://alfajores-forno.celo-testnet.org", // Celo testnet
				// url: "(link unavailable)", // Celo mainnet
				blockNumber: 25867847, // Optional: specify a block number to fork from
				enabled: true
			},
			accounts: [
				{
				  privateKey: vars.get('PRIVATE_KEY'), // Your private key
				  balance: "1000000000000000000000", // Optional: specify a balance
				},
				{
				  privateKey: vars.get('PRIVATE_KEY_2'), // Another private key
				  balance: "1000000000000000000000", // Optional: specify a balance
				},
			],
		
		
		},
		// localhost: {
		// 	url: node_url('localhost'),
		// 	accounts: accounts(),
		// },
		ganache: {
			url: 'http://127.0.0.1:7545',
			accounts: [
				'7c764ca90dab0468b163bb8272e247eb06abd756072b7c80e9e2f88e24b3b518',
				'dac5005f97f0be8bb23879f38a9ca93c60410d20796806d23f03aac88a1964a3',
				'767b05471aa3713700998846d7be6038db16d5e29e7460c604bb382fcf4100a3',
				'67d7a67d19c2d63df22f4078f5e7732f500fe37bc42660510e09da038814fa5e',
			],
		},
		staging: {
			url: node_url('rinkeby'),
			accounts: accounts('rinkeby'),
		},
		production: {
			url: node_url('mainnet'),
			accounts: accounts('mainnet'),
		},
		mainnet: {
			url: node_url('mainnet'),
			accounts: accounts('mainnet'),
		},
		theta_t: {
			url: 'https://eth-rpc-api-testnet.thetatoken.org/rpc',
			accounts:
				vars.has('PRIVATE_KEY') ? [vars.get('PRIVATE_KEY'), vars.get('PRIVATE_KEY_2')] : [],
			chainId: 365,
		},
		okb_test: {
			url: 'https://okbtestrpc.okbchain.org',
			accounts:
				vars.has('PRIVATE_KEY') ? [vars.get('PRIVATE_KEY'), vars.get('PRIVATE_KEY_2')] : [],
			chainId: 195,
		},
		evmos_t: {
			url: 'https://eth.bd.evmos.dev:8545',
			accounts:
				vars.has('PRIVATE_KEY') ? [vars.get('PRIVATE_KEY'), vars.get('PRIVATE_KEY_2')] : [],
			chainId: 9000,
		},
		fantom_t: {
			url: "https://rpc.ankr.com/fantom_testnet/",
			accounts: vars.has('PRIVATE_KEY') ? [vars.get('PRIVATE_KEY'), vars.get('PRIVATE_KEY_2')] : [],
			chainId: 4002,
		  }, 
		fantom: {
			url: 'https://rpc.fantom.network',
			accounts: liveDeploymentAccount,
			chainId: 250,
		},
		aurora: {
			url: "https://mainnet.aurora.dev",
			accounts: liveDeploymentAccount,
			chainId: 1313161554 ,
		},
		aurora_t: {
			url: "https://testnet.aurora.dev/",
			accounts: vars.has('PRIVATE_KEY') ? [vars.get('PRIVATE_KEY'), vars.get('PRIVATE_KEY_2')] : [],
			chainId: 1313161555,
		},
		celo: {
			url: "https://forno.celo.org",
			accounts: liveDeploymentAccount,
			chainId: 42220,
			
			
		},
		"celo_t": {// alfajores
			url: "https://alfajores-forno.celo-testnet.org",
			accounts: vars.has('PRIVATE_KEY') ? [vars.get('PRIVATE_KEY'), vars.get('PRIVATE_KEY_2')] : [],
			chainId: 44787,
			
			
		},
		meter_testnet: {
			url: "https://rpctest.meter.io",
			accounts: vars.has('PRIVATE_KEY') ? [vars.get('PRIVATE_KEY'), vars.get('PRIVATE_KEY_2')] : [],
			chainId: 83,
		},
		meter: {
			url: "https://rpc.meter.io",
			accounts: liveDeploymentAccount,
			chainId: 82,
		},

		"mumbai": { //polygon test
			url: "https://rpc-mumbai.maticvigil.com",
			accounts: vars.has('PRIVATE_KEY') ? [vars.get('PRIVATE_KEY'), vars.get('PRIVATE_KEY_2')] : [],
			chainId: 80001 ,
			
			
		},

		"base_t": { //Base test
			url: "https://sepolia.base.org",
			accounts: vars.has('PRIVATE_KEY') ? [vars.get('PRIVATE_KEY'), vars.get('PRIVATE_KEY_2')] : [],
			chainId: 84532 ,
			// gasPrice: 350000000,
			
			
		},

		findora: {
			url: "https://rpc-mainnet.findora.org",
			accounts: liveDeploymentAccount,
			chainId: 2152,
		},
		findora_testnet: {
			url: "https://prod-testnet.prod.findora.org:8545",
			accounts: vars.has('PRIVATE_KEY') ? [vars.get('PRIVATE_KEY'), vars.get('PRIVATE_KEY_2')] : [],
			chainId: 2153,
		},
		bsctestnet: {
		   url: "https://data-seed-prebsc-1-s1.binance.org:8545",
		   chainId: 97,
		   gasPrice: 20000000000,
		   accounts: {mnemonic: ''}
		},
		bsc: {
		   url: "https://bsc-dataseed.binance.org/",
		   chainId: 56,
		   gasPrice: 20000000000,
		   accounts: liveDeploymentAccount,
		 },
		bttc_testnet: {
		   url: "https://pre-rpc.bt.io/",
		   accounts: vars.has('PRIVATE_KEY') ? [vars.get('PRIVATE_KEY'), vars.get('PRIVATE_KEY_2')] : [],
		   chainId: 1029,
		 },
		bttc: {
		   url: "https://rpc.bt.io",
		   accounts: vars.has('PRIVATE_KEY') ? [vars.get('PRIVATE_KEY'), vars.get('PRIVATE_KEY_2')] : [],
		   chainId: 199,
		 },

		core_testnet: {
			url: "https://rpc.test.btcs.network/",
			accounts: vars.has('PRIVATE_KEY') ? [vars.get('PRIVATE_KEY'), vars.get('PRIVATE_KEY_2')] : [],
			chainId: 1115,
		  },
		core: {
			url: "https://rpc.coredao.org/",
			accounts: liveDeploymentAccount,
			chainId: 1116,
		  },

		scroll_sepolia: {
			url: "https://sepolia-rpc.scroll.io/",
			accounts: vars.has('PRIVATE_KEY') ? [vars.get('PRIVATE_KEY'), vars.get('PRIVATE_KEY_2')] : [],
			chainId: 534351,
		},  

		canto_t: {
			url: "https://canto-testnet.plexnode.wtf",
			accounts: vars.has('PRIVATE_KEY') ? [vars.get('PRIVATE_KEY'), vars.get('PRIVATE_KEY_2')] : [],
			chainId: 7701,
		},

		

		"fraxtal": { //fraxtal
			url: "https://rpc.frax.com",
			accounts: liveDeploymentAccount,
			chainId: 252 ,
			// gasPrice: 350000000,
			
			
		},

		"fraxtal_t": { //fraxtal test
			url: "https://rpc.testnet.frax.com",
			accounts: vars.has('PRIVATE_KEY') ? [vars.get('PRIVATE_KEY'), vars.get('PRIVATE_KEY_2')] : [],
			chainId: 2522 ,
			// gasPrice: 350000000,
		},
		"dchain_t":{
			url: "https://dchaintestnet-2713017997578000-1.jsonrpc.testnet.sagarpc.io",
			accounts: vars.has('PRIVATE_KEY') ? [vars.get('PRIVATE_KEY'), vars.get('PRIVATE_KEY_2')] : [],
			
			chainId: 2713017997578000
		},

		opencampus: {//Educhain Test
			url: `https://rpc.open-campus-codex.gelato.digital`,
			accounts: vars.has('PRIVATE_KEY') ? [vars.get('PRIVATE_KEY'), vars.get('PRIVATE_KEY_2')] : [],
			chainId: 656476 
		},
	}),
	
	gasReporter: {
		currency: 'USD',
		gasPrice: 100,
		enabled: process.env.REPORT_GAS ? true : false,
		coinmarketcap: process.env.COINMARKETCAP_API_KEY,
		maxMethodDiff: 10,
	},
	
	mocha: {
		timeout: 0,
	},
	
	contractSizer: {
		alphaSort: true,
		disambiguatePaths: false,
		runOnCompile: true,
		strict: true,
		only: [':Campaign*', 'Locker*',  ':Vault$',  'Vault$', ':Fair*', 'Uniswap*'],
	}

};

export default config;
