import { ethers, upgrades } from "hardhat";
import { expect } from "chai";

import {
  loadFixture,
  setBalance,
} from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { AltInsureTokenV1 } from "../typechain-types";
import { constants } from "ethers";

const L1_TOKEN = "0x0C4a63D472120d7859E2842b7C2Bafbd8eDe8f44";
const CHILD_CHAIN_MANAGER_PROXY = "0xb5505a6d998549090530911180f38aC5130101c6";
const ARBITRUM_L2_GATEWAY = "0x09e9222E96E7B4AE2a407B98d48e330053351EEe";

describe("AltInsureTokenV1 edge cases", () => {
  const deployFixture = async (): Promise<{
    altInsureToken: AltInsureTokenV1;
    deployer: SignerWithAddress;
    alice: SignerWithAddress;
    bob: SignerWithAddress;
    bridger: SignerWithAddress;
    childChainManagerProxy: SignerWithAddress;
    arbitrumL2Gateway: SignerWithAddress;
  }> => {
    const [deployer, alice, bob, bridger] = await ethers.getSigners();
    const childChainManagerProxy = await ethers.getImpersonatedSigner(
      CHILD_CHAIN_MANAGER_PROXY
    );
    const arbitrumL2Gateway = await ethers.getImpersonatedSigner(
      ARBITRUM_L2_GATEWAY
    );
    const AltInsureToken = await ethers.getContractFactory("AltInsureTokenV1");
    const altInsureToken = (await upgrades.deployProxy(
      AltInsureToken,
      [L1_TOKEN, CHILD_CHAIN_MANAGER_PROXY, ARBITRUM_L2_GATEWAY],
      {
        unsafeAllow: ["delegatecall"],
      }
    )) as AltInsureTokenV1;

    await altInsureToken.updateBridgeSupply(
      deployer.address,
      ethers.constants.MaxUint256,
      false,
      constants.AddressZero
    );

    await altInsureToken.mint(alice.address, 10_000);
    await altInsureToken.mint(bob.address, 10_000);

    await setBalance(childChainManagerProxy.address, 100n ** 18n);
    await setBalance(arbitrumL2Gateway.address, 100n ** 18n);

    return {
      altInsureToken,
      deployer,
      alice,
      bob,
      bridger,
      childChainManagerProxy,
      arbitrumL2Gateway,
    };
  };

  describe("cBridge", () => {
    // describe("initialize", () => {});
    describe("mint()", () => {
      it("rejects not allowed bridger", async () => {
        const { altInsureToken, alice } = await loadFixture(deployFixture);
        await expect(
          altInsureToken.connect(alice).mint(alice.address, 1_000)
        ).to.be.revertedWithCustomError(altInsureToken, "NotAllowedBridger");
      });

      it("rejects insufficient capacity bridger", async () => {
        const { altInsureToken, deployer, alice, bridger } = await loadFixture(
          deployFixture
        );
        await altInsureToken
          .connect(deployer)
          .updateBridgeSupply(
            bridger.address,
            999,
            false,
            constants.AddressZero
          );
        await expect(
          altInsureToken.connect(bridger).mint(alice.address, 1_000)
        ).to.be.revertedWithCustomError(altInsureToken, "ExceedSupplyCap");
      });
    });

    describe("burn(address,uint256)", () => {
      it("rejects burning by not approved address", async () => {
        const { altInsureToken, alice, bridger } = await loadFixture(
          deployFixture
        );
        await expect(
          altInsureToken
            .connect(bridger)
            ["burn(address,uint256)"](alice.address, 10_000)
        ).to.be.revertedWith("ERC20: insufficient allowance");
      });

      it("rejects burn which exceeds supply", async () => {
        const { altInsureToken, alice, bridger } = await loadFixture(
          deployFixture
        );
        await altInsureToken.updateBridgeSupply(
          bridger.address,
          10_000,
          false,
          constants.AddressZero
        );
        await altInsureToken.connect(alice).approve(bridger.address, 10_000);
        await expect(
          altInsureToken
            .connect(bridger)
            ["burn(address,uint256)"](alice.address, 10_000)
        ).to.be.revertedWithCustomError(altInsureToken, "BurnAmountExceeded");
      });
    });

    describe("burnFrom()", () => {
      it("rejects burning by not approved address", async () => {
        const { altInsureToken, alice, bridger } = await loadFixture(
          deployFixture
        );
        await expect(
          altInsureToken.connect(bridger).burnFrom(alice.address, 10_000)
        ).to.be.revertedWith("ERC20: insufficient allowance");
      });

      it("rejects burn which exceeds supply", async () => {
        const { altInsureToken, alice, bridger } = await loadFixture(
          deployFixture
        );
        await altInsureToken.updateBridgeSupply(
          bridger.address,
          10_000,
          false,
          constants.AddressZero
        );
        await altInsureToken.connect(alice).approve(bridger.address, 10_000);
        await expect(
          altInsureToken.connect(bridger).burnFrom(alice.address, 10_000)
        ).to.be.revertedWithCustomError(altInsureToken, "BurnAmountExceeded");
      });
    });
  });

  describe("Polygon canonical bridge implementation", () => {
    describe("deposit()", () => {
      it("rejects to deposit by non childChainManagerProxy", async () => {
        const { altInsureToken, alice } = await loadFixture(deployFixture);

        const depositAmount = ethers.utils.hexlify(10_000);
        const depositorRole = await altInsureToken.DEPOSITOR_ROLE();

        await expect(
          altInsureToken.connect(alice).deposit(alice.address, depositAmount)
        ).to.be.revertedWith(
          `AccessControl: account ${alice.address.toLowerCase()} is missing role ${depositorRole}`
        );
      });
    });

    describe("withdraw()", () => {
      it("rejects to withdraw larger amount than balance", async () => {
        const { altInsureToken, alice } = await loadFixture(deployFixture);

        await expect(
          altInsureToken.connect(alice).withdraw(10_001)
        ).to.be.revertedWith("ERC20: burn amount exceeds balance");
      });
    });
  });

  describe("Optimism canonical bridge implementation", () => {
    describe("initialize", () => {
      it("rejects to set l1 token to address zero", async () => {
        const AltInsureTokenV1 = await ethers.getContractFactory(
          "AltInsureTokenV1"
        );
        await expect(
          upgrades.deployProxy(AltInsureTokenV1, [
            ethers.constants.AddressZero,
            CHILD_CHAIN_MANAGER_PROXY,
            ARBITRUM_L2_GATEWAY,
          ])
        ).to.be.revertedWithCustomError(AltInsureTokenV1, "AddressZero");
      });
    });
  });

  describe("Arbitrum canonical bridge implementation", () => {
    describe("initialize", () => {
      it("rejects to set l1 token to address zero", async () => {
        const AltInsureTokenV1 = await ethers.getContractFactory(
          "AltInsureTokenV1"
        );
        await expect(
          upgrades.deployProxy(AltInsureTokenV1, [
            ethers.constants.AddressZero,
            CHILD_CHAIN_MANAGER_PROXY,
            ARBITRUM_L2_GATEWAY,
          ])
        ).to.be.revertedWithCustomError(AltInsureTokenV1, "AddressZero");
      });
    });

    describe("bridgeMint()", () => {
      it("rejects to call bridgeMint except gateway", async () => {
        const { altInsureToken, alice } = await loadFixture(deployFixture);
        await expect(
          altInsureToken.bridgeMint(alice.address, 10_000n * 18n)
        ).revertedWithCustomError(altInsureToken, "OnlyArbGateway");
      });
    });

    describe("bridgeBurn()", () => {
      it("rejects to call bridgeBurn except gateway", async () => {
        const { altInsureToken, alice } = await loadFixture(deployFixture);
        await expect(
          altInsureToken.bridgeBurn(alice.address, 10_000)
        ).revertedWithCustomError(altInsureToken, "OnlyArbGateway");
      });
    });
  });
});
