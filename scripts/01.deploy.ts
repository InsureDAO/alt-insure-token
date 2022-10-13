import hre, { ethers, upgrades } from "hardhat";
import {
  getL1TokenAddress,
  getArbL2Gateway,
  getChildChainManagerProxy,
} from "./config/constants";

async function main(): Promise<void> {
  const [deployer] = await ethers.getSigners();
  const chainId = hre.network.config.chainId;
  const l1Token = getL1TokenAddress(chainId);
  const arbL2Gateway = getArbL2Gateway(chainId);
  const childChainManagerProxy = getChildChainManagerProxy(chainId);
  const AltInsureTokenV1 = await ethers.getContractFactory(
    "AltInsureTokenV1",
    deployer
  );
  const altInsureToken = await upgrades.deployProxy(
    AltInsureTokenV1,
    [l1Token, childChainManagerProxy, arbL2Gateway],
    {
      unsafeAllow: ["delegatecall"],
    }
  );
  await altInsureToken.deployed();

  console.log(
    "AltInsureToken deployed to the address:",
    altInsureToken.address
  );

  await hre.run("verify:verify", {
    address: altInsureToken.address,
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
