import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import * as dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.17",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
      {
        version: "0.8.10",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
    ],
  },
  networks: {
    hardhat: {},
    goerli: {
      chainId: 5,
      url: process.env.GOERLI_RPC,
      accounts: [process.env.DEPLOY_KEY ?? ""],
    },
    mumbai: {
      chainId: 80001,
      url: process.env.MUMBAI_RPC,
      accounts: [process.env.DEPLOY_KEY ?? ""],
    },
    optimismGoerli: {
      chainId: 420,
      url: process.env.OPT_GOERLI_RPC,
      accounts: [process.env.DEPLOY_KEY ?? ""],
    },
    arbitrumGoerli: {
      chainId: 421613,
      url: process.env.ARB_GOERLI_RPC,
      accounts: [process.env.DEPLOY_KEY ?? ""],
    },
  },
  etherscan: {
    apiKey: {
      polygonMumbai: process.env.POLYGONSCAN_API_KEY ?? "",
      goerli: process.env.ETHERSCAN_API_KEY ?? "",
      optimisticGoerli: process.env.OPT_ETHERSCAN_API_KEY ?? "",
      arbitrumGoerli: process.env.ARB_ETHERSCAN_API_KEY ?? "",
    },
    customChains: [
      {
        network: "optimisticGoerli",
        chainId: 420,
        urls: {
          apiURL: "https://api-goerli-optimism.etherscan.io/api",
          browserURL: "https://goerli-optimism.etherscan.io/",
        },
      },
      {
        network: "arbitrumGoerli",
        chainId: 421613,
        urls: {
          apiURL: "https://api-goerli.arbiscan.io/api",
          browserURL: "https://goerli.arbiscan.io/",
        },
      },
    ],
  },
};

export default config;
