import { ethers, upgrades } from "hardhat";

describe("AltInsureTokenV1", () => {
  it("should be deployed", async () => {
    const [account] = await ethers.getSigners();
    console.log("account: ", account.address);
    const childChainManagerProxy = "0xb5505a6d998549090530911180f38aC5130101c6";
    const l1token = "0x0C4a63D472120d7859E2842b7C2Bafbd8eDe8f44";
    const AltInsureToken = await ethers.getContractFactory("AltInsureTokenV1");
    const altInsureToken = await upgrades.deployProxy(
      AltInsureToken,
      [childChainManagerProxy, l1token],
      {
        unsafeAllow: ["delegatecall"],
      }
    );
    await altInsureToken.deployed();

    const owner = await altInsureToken.owner();
    const depositorRole = ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("DEPOSITOR_ROLE")
    );
    console.log("depositorRole", depositorRole);
    const hasRole = await altInsureToken.hasRole(
      depositorRole,
      "0xb5505a6d998549090530911180f38aC5130101c6"
    );

    console.log("owner: ", owner);
    console.log(
      "check role for 0xb5505a6d998549090530911180f38aC5130101c6: ",
      hasRole
    );
  });
});
