import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  // solidity: "0.8.17",
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
        version: "0.6.6",
      },
    ],
    // overrides: {
    //   "contracts/AltInsureToken.sol": {
    //     version: "0.6.6",
    //   }
    // },
  },
};

export default config;
