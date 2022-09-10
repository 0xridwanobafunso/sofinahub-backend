const HDWalletProvider = require('@truffle/hdwallet-provider')
const dotenv = require('dotenv')

// load env variables
dotenv.config()

const { INFURA_API_URL, MNEMONIC, ETHERSCAN_API_KEY } = process.env

module.exports = {
  networks: {
    development: {
      host: '127.0.0.1',
      port: 7545,
      network_id: '*',
    },
    ropsten: {
      provider: () => new HDWalletProvider(MNEMONIC, INFURA_API_URL),
      network_id: 3,
      gas: 5500000,
      networkCheckTimeoutnetworkCheckTimeout: 10000,
      timeoutBlocks: 200,
    },
  },
  // Configure your compilers
  compilers: {
    solc: {
      version: '0.8.15',
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
      },
    },
  },
  plugins: ['truffle-plugin-verify', 'truffle-contract-size'],
  api_keys: {
    etherscan: ETHERSCAN_API_KEY,
  },
}
