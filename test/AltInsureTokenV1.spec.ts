import { ethers, upgrades } from "hardhat";
import { assert, expect } from "chai";

import {
  loadFixture,
  setBalance,
} from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { AltInsureTokenV1 } from "../typechain-types";
import { BigNumber } from "ethers";

const L1_TOKEN = "0x0C4a63D472120d7859E2842b7C2Bafbd8eDe8f44";
const CHILD_CHAIN_MANAGER_PROXY = "0xb5505a6d998549090530911180f38aC5130101c6";
const ARBITRUM_L2_GATEWAY = "0x09e9222E96E7B4AE2a407B98d48e330053351EEe";

describe("AltInsureTokenV1", () => {
  const deployFixture = async (): Promise<{
    altInsureToken: AltInsureTokenV1;
    deployer: SignerWithAddress;
    alice: SignerWithAddress;
    bob: SignerWithAddress;
    childChainManagerProxy: SignerWithAddress;
    arbitrumL2Gateway: SignerWithAddress;
  }> => {
    const [deployer, alice, bob] = await ethers.getSigners();
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

    await altInsureToken.updateBridgeSupplyCap(
      deployer.address,
      ethers.constants.MaxUint256
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
      childChainManagerProxy,
      arbitrumL2Gateway,
    };
  };

  describe("cBridge", () => {
    it("initialize", async () => {
      const { altInsureToken, deployer } = await loadFixture(deployFixture);

      await assert.eventually.equal(altInsureToken.name(), "AltInsureToken");
      await assert.eventually.equal(altInsureToken.symbol(), "INSURE");
      await assert.eventually.equal(altInsureToken.owner(), deployer.address);
    });

    it("mint()", async () => {
      const { altInsureToken, deployer, alice } = await loadFixture(
        deployFixture
      );

      const mint = altInsureToken.connect(deployer).mint(alice.address, 1_000);

      await expect(mint)
        .to.emit(altInsureToken, "Transfer")
        .withArgs(ethers.constants.AddressZero, alice.address, 1_000)
        .changeTokenBalance(altInsureToken, alice, 1_000);
    });

    it("burn(uint256", async () => {
      const { altInsureToken, alice } = await loadFixture(deployFixture);
      const burn = altInsureToken.connect(alice)["burn(uint256)"](1_000);
      await expect(burn)
        .to.emit(altInsureToken, "Transfer")
        .withArgs(alice.address, ethers.constants.AddressZero, 1_000)
        .changeTokenBalance(altInsureToken, alice, -1_000);
    });

    it("burn(address,uint256)", async () => {
      const { altInsureToken, deployer, alice } = await loadFixture(
        deployFixture
      );

      await altInsureToken.connect(alice).approve(deployer.address, 1_000);
      const burn = altInsureToken
        .connect(deployer)
        ["burn(address,uint256)"](alice.address, 1_000);

      await expect(burn)
        .to.emit(altInsureToken, "Transfer")
        .withArgs(alice.address, ethers.constants.AddressZero, 1_000)
        .changeTokenBalance(altInsureToken, alice, -1_000);
    });

    it("burnFrom()", async () => {
      const { altInsureToken, deployer, alice } = await loadFixture(
        deployFixture
      );

      await altInsureToken.connect(alice).approve(deployer.address, 1_000);
      const burnFrom = altInsureToken
        .connect(deployer)
        .burnFrom(alice.address, 1_000);

      await expect(burnFrom)
        .to.emit(altInsureToken, "Transfer")
        .withArgs(alice.address, ethers.constants.AddressZero, 1_000)
        .changeTokenBalance(altInsureToken, alice, -1_000);
    });

    it("updateBridgeSupplyCap()", async () => {
      const { altInsureToken, alice } = await loadFixture(deployFixture);

      const initialSupply = await altInsureToken.bridges(alice.address);

      assert.deepEqual(initialSupply.cap, ethers.constants.Zero);
      assert.deepEqual(initialSupply.total, ethers.constants.Zero);

      await expect(
        altInsureToken.updateBridgeSupplyCap(alice.address, 10_000)
      ).to.emit(altInsureToken, "SupplyCapChanged");

      const updatedSupply = await altInsureToken.bridges(alice.address);

      assert.deepEqual(updatedSupply.cap, BigNumber.from("10000"));
      assert.deepEqual(updatedSupply.total, ethers.constants.Zero);
    });

    it("getOwner()", async () => {
      const { altInsureToken, deployer } = await loadFixture(deployFixture);

      await assert.eventually.equal(
        altInsureToken.getOwner(),
        deployer.address
      );
    });
  });

  describe("Polygon canonical bridge implementation", () => {
    it("initialize", async () => {
      const { altInsureToken } = await loadFixture(deployFixture);
      await assert.eventually.equal(
        altInsureToken.DEPOSITOR_ROLE(),
        ethers.utils.keccak256(ethers.utils.toUtf8Bytes("DEPOSITOR_ROLE"))
      );
    });

    it("deposit()", async () => {
      const { altInsureToken, alice, childChainManagerProxy } =
        await loadFixture(deployFixture);
      const deposit = altInsureToken
        .connect(childChainManagerProxy)
        .deposit(
          alice.address,
          ethers.utils.hexZeroPad(ethers.utils.hexlify(1_000), 32)
        );

      await expect(deposit)
        .to.emit(altInsureToken, "Transfer")
        .withArgs(ethers.constants.AddressZero, alice.address, 1_000)
        .changeTokenBalance(altInsureToken, alice.address, 1_000);
    });

    it("withdraw()", async () => {
      const { altInsureToken, alice } = await loadFixture(deployFixture);
      const withdraw = altInsureToken.connect(alice).withdraw(100);
      await expect(withdraw)
        .to.emit(altInsureToken, "Transfer")
        .withArgs(alice.address, ethers.constants.AddressZero, 100)
        .changeTokenBalance(altInsureToken, alice, -100);
    });
  });

  describe("Optimism canonical bridge implementation", () => {
    it("initialize", async () => {
      const { altInsureToken } = await loadFixture(deployFixture);
      await assert.eventually.equal(altInsureToken.l1Token(), L1_TOKEN);
    });
    it("supportsInterface()", async () => {
      const { altInsureToken } = await loadFixture(deployFixture);
      const l1TokenHash = altInsureToken.interface.getSighash("l1Token()");
      const mintHash = altInsureToken.interface.getSighash(
        "mint(address,uint256)"
      );
      const burnHash = altInsureToken.interface.getSighash(
        "burn(address,uint256)"
      );
      const bridgeMintHash = altInsureToken.interface.getSighash(
        "bridgeMint(address,uint256)"
      );
      const bridgeBurnHash = altInsureToken.interface.getSighash(
        "bridgeBurn(address,uint256)"
      );
      const l1AddressHash = altInsureToken.interface.getSighash("l1Address()");
      const depositHash = altInsureToken.interface.getSighash(
        "deposit(address,bytes)"
      );
      const withdrawHash =
        altInsureToken.interface.getSighash("withdraw(uint256)");
      const burnFromHash = altInsureToken.interface.getSighash(
        "burnFrom(address,uint256)"
      );

      const minimumIfaceId = altInsureToken.interface.getSighash(
        "supportsInterface(bytes4)"
      );

      const optIfaceId = BigNumber.from(l1TokenHash)
        .xor(mintHash)
        .xor(burnHash)
        .toHexString();

      const arbIfaceId = BigNumber.from(l1AddressHash)
        .xor(bridgeMintHash)
        .xor(bridgeBurnHash)
        .toHexString();

      const polygonIfaceId = BigNumber.from(depositHash)
        .xor(withdrawHash)
        .toHexString();

      const cBridgeV1IfaceId = BigNumber.from(mintHash)
        .xor(burnHash)
        .toHexString();

      const cBridgeV2IfaceId = BigNumber.from(mintHash)
        .xor(burnHash)
        .xor(burnFromHash)
        .toHexString();

      const notSupportedId = ethers.utils.hexDataSlice(
        ethers.utils.keccak256(ethers.utils.toUtf8Bytes("helloWorld()")),
        0,
        4
      );

      await assert.eventually.equal(
        altInsureToken.supportsInterface(minimumIfaceId),
        true
      );

      await assert.eventually.equal(
        altInsureToken.supportsInterface(optIfaceId),
        true
      );

      await assert.eventually.equal(
        altInsureToken.supportsInterface(arbIfaceId),
        true
      );

      await assert.eventually.equal(
        altInsureToken.supportsInterface(polygonIfaceId),
        true
      );

      await assert.eventually.equal(
        altInsureToken.supportsInterface(cBridgeV1IfaceId),
        true
      );

      await assert.eventually.equal(
        altInsureToken.supportsInterface(cBridgeV2IfaceId),
        true
      );

      await assert.eventually.equal(
        altInsureToken.supportsInterface(notSupportedId),
        false
      );
    });
  });

  describe("Arbitrum canonical bridge implementation", () => {
    it("initialize", async () => {
      const { altInsureToken } = await loadFixture(deployFixture);
      await assert.eventually.equal(altInsureToken.l1Address(), L1_TOKEN);
    });

    it("bridgeMint()", async () => {
      const { altInsureToken, alice, arbitrumL2Gateway } = await loadFixture(
        deployFixture
      );
      const bridgeMint = altInsureToken
        .connect(arbitrumL2Gateway)
        .bridgeMint(alice.address, 1_000);

      await expect(bridgeMint)
        .to.emit(altInsureToken, "Transfer")
        .withArgs(ethers.constants.AddressZero, alice.address, 1_000)
        .changeTokenBalance(altInsureToken, alice, 1_000);
    });

    it("bridgeBurn()", async () => {
      const { altInsureToken, alice, arbitrumL2Gateway } = await loadFixture(
        deployFixture
      );
      const bridgeBurn = altInsureToken
        .connect(arbitrumL2Gateway)
        .bridgeBurn(alice.address, 1_000);

      await expect(bridgeBurn)
        .to.emit(altInsureToken, "Transfer")
        .withArgs(alice.address, ethers.constants.AddressZero, 1_000)
        .changeTokenBalance(altInsureToken, alice, -1_000);
    });
  });
});
