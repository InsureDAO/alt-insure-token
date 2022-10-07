import { ethers, upgrades } from "hardhat";

const CHILD_CHAIN_MANAGER_PROXY = 0x00;

async function main(): Promise<void> {
  const AltInsureTokenV1 = await ethers.getContractFactory("AltInsureTokenV1");
  const altInsureToken = await upgrades.deployProxy(AltInsureTokenV1, [
    CHILD_CHAIN_MANAGER_PROXY,
  ]);
  await altInsureToken.deployed();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
