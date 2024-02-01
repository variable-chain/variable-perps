require("@nomiclabs/hardhat-ethers");
require('@nomiclabs/hardhat-etherscan');
require('dotenv').config()

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.20",
  networks: {
    hardhat: {
      allowUnlimitedContractSize: false,
    },
    localhost: {
      url: "http://127.0.0.1:8545", // same address and port for both Buidler and Ganache node
      accounts: [/* will be provided by ganache */],
      gas: 8000000,
      gasPrice: 1,
    },
    goerli: {
      url: `https://eth-goerli.alchemyapi.io/v2/${process.env.GOERLI_ALCHEMY_API_KEY}`,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      throwOnTransactionFailures: true,
      loggingEnabled: true,
      timeout: 10800000
    },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};
