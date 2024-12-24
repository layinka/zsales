# Zarpay Contracts

## Crypto Powered Payment Gateway

## INSTALL

```bash
npm install
```

## TEST

### hardhat
```shell
npx hardhat test
npx hardhat test ./test/index.ts   // Specific file
REPORT_GAS=true npx hardhat test
```



## Deploy with Hardhat-Deploy

### Deploy

`npx hardhat deploy <network> [args...]`





## Deploy with Hardhat Ignition

### Deploy

`npx hardhat ignition deploy ./ignition/modules/Lock.ts <network> [args...]`

### Deploy with Create2
`npx hardhat ignition deploy ignition/modules/[module].ts --network [network] --strategy create2`

`npx hardhat ignition deploy ignition/modules/[module].ts --network [network] --strategy create2 --deployment-id second-deploy`

`npx hardhat ignition deploy ignition/modules/Lock.ts --network localhost --strategy create2`




```shell
npx hardhat accounts --network meter_testnet
npx hardhat compile
npx hardhat help
npx hardhat test
npx hardhat test --network localhost

npx hardhat node
npx hardhat coverage
npx hardhat run scripts/deploy.ts --network localhost
npx hardhat run scripts/deploy.ts --network meter_testnet
npx hardhat run scripts/deploy-token-minter.ts --network localhost
npx hardhat run scripts/deploy-router.ts --network localhost

GAS_REPORT=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```



# Static Analysis 
```
slither .
```

# Deploy

You can deploy in the localhost network following these steps:

    Start a local node

    `npx hardhat node`

    Open a new terminal and deploy the smart contract in the localhost network

    `npx hardhat deploy --network localhost --tags [..]`

As general rule, you can target any network configured in the hardhat.config.js

npx hardhat deploy --network <your-network> 

# Etherscan verification

To try out Etherscan verification, you first need to deploy a contract to an Ethereum network that's supported by Etherscan, such as Ropsten.

In this project, copy the .env.example file to a file named .env, and then edit it to fill in the details. Enter your Etherscan API key, your Ropsten node URL (eg from Alchemy), and the private key of the account which will send the deployment transaction. With a valid .env file in place, first deploy your contract:

```shell
hardhat run --network ropsten scripts/sample-script.ts
```

Then, copy the deployment address and paste it in to replace `DEPLOYED_CONTRACT_ADDRESS` in this command:

```shell
npx hardhat verify --network ropsten DEPLOYED_CONTRACT_ADDRESS "Hello, Hardhat!"
```


or 

## Use Hardhat-deploy etherscan-verify
npx hardhat  etherscan-verify --network scroll_sepolia --solc-input --api-url https://api-sepolia.scrollscan.com --api-key X....

# Performance optimizations

For faster runs of your tests and scripts, consider skipping ts-node's type checking by setting the environment variable `TS_NODE_TRANSPILE_ONLY` to `1` in hardhat's environment. For more details see [the documentation](https://hardhat.org/guides/typescript.html#performance-optimizations).
