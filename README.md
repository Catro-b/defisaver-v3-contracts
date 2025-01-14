o# defisaver-v3-contracts
All the contracts related to the Defi Saver ecosystem.

Detailed overview about the code can be found at https://docs.defisaver.com

## To install
Run `yarn` in the repo folder.
You will also need to create a `.env` file as in the `.env.example` and fill it in with appropriate api keys.
For a quick start, you can copy `.env.example` with default values and rename it to `.env`.

## How to run tests

All of the tests are ran from the forked state of the mainnet. In the hardhat config you can change the 
block number the fork starts from. If it starts from an old state some tests might not work.

Before running tests compile all contracts at start: `npx hardhat compile`

#### Run tests with default hardhat network

In `hardhat.config.js` hardhat network will fork mainnet by default. For example, you can run tests as:

`npx hardhat test ./test/aaveV3/full-test.js --network hardhat`

#### Run tests with separate hardhat node running
First You need to start a hardhat node from the forked mainnet with the following command:

`npx hardhat node --max-memory 8192  --fork ETHEREUM_NODE_URL`

After that you can run the tests, for example:

`npm run test local ./aaveV3/full-test.js`

### Running core tests
`npx hardhat test ./test/run-core-tests.js --network hardhat`

### Running foundry tests

In `test-sol` folder you can find foundry setup.

Before running tests make sure you have foundry installed (check it with `forge --version`)

To run tests execute:

`forge test --fork-url <INSERT_MAINNET_FORK>`

<b>Notice:</b> 
Currently, foundry tests are used just as an example. Although, we plan to add them more in the future, all protocols and core tests
should be run in hardhat environment

## How to deploy on a tenderly fork

1. In the .env file add the tenderly fork id where you want to deploy

2. In the `scripts/deploy-on-fork.js` add contracts you want to deploy using the `redeploy()` function and make sure to specify `reg.address` as second parameter. 

3. To deploy on fork run the following command: `npm run deploy fork deploy-on-fork`

## Common commands

`npm run compile` -  will compile all the contracts

`npm run deploy [network] [deploy-script]` - will deploy to the specified network by calling the script from the `/scripts` folder

`npm run test [network] [test-file]` - will run a test to the specified network by calling the script from the `/test` folder

`npm run verify [network] [contract-name]` - will verify contract based on address and arguments from `/deployments` folder

## Custom hardhat tasks

`npx hardhat changeRepoNetwork [current-network-name] [new-network-name]` -  will change which contract the helper contracts import and extend

`npx hardhat customFlatten [contract-name]` -  will flatten contract that is ready for deployment and put it in contracts/flattened folder

`npx hardhat customVerify [contract-address] [contract-name] --network [hardhat-settings-network-name]`  - will verify on etherscan if a contract was deployed using a single file from customFlatten task 

`npx hardhat fladepver [contract-name] [gas-in-gwei] [nonce (optional)] --network [hardhat-settings-network-name]` - will flatten to a single file (save it in contracts/flattened), deploy from it and then verify it on etherscan

`npx hardhat encryptPrivateKey` - will encrypt the key with the secretWord. Put the output in .env as ENCRYPTED_KEY. Later on during deployment process it will ask you for secret word to decrypt the key for deployment use.
