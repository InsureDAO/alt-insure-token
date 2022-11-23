import hre, { ethers } from "hardhat";
async function main(): Promise<void> {
  const [deployer] = await ethers.getSigners();
  const InsureToken = await ethers.getContractFactory("InsureToken", deployer);
  const Ownership = await ethers.getContractFactory("Ownership", deployer);

  const ownership = await Ownership.deploy();
  await ownership.deployed();
  console.log("Ownership deployed to:", ownership.address);

  const insureToken = await InsureToken.deploy(
    "InsureToken",
    "INSURE",
    ownership.address
  );
  await insureToken.deployed();
  console.log("InsureToken deployed to:", insureToken.address);

  try {
    await hre.run("verify:verify", {
      address: ownership.address,
      constructorArguments: [],
    });
  } catch (error) {
    console.error(error);
  }
  try {
    await hre.run("verify:verify", {
      address: insureToken.address,
      constructorArguments: ["InsureToken", "INSURE", ownership.address],
    });
  } catch (error) {
    console.error(error);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
