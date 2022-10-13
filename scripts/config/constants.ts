import { ethers } from "ethers";

interface AddressMap {
  [key: number]: string | undefined;
}

const L1_TOKEN = {
  mainnet: "",
  goerli: "0x0C4a63D472120d7859E2842b7C2Bafbd8eDe8f44",
};

const ARBITRUM_L2_GATEWAY: AddressMap = {
  // arbitrum one
  42161: "0x09e9222E96E7B4AE2a407B98d48e330053351EEe",
  // arbitrum goerli
  421613: "0x2eC7Bc552CE8E51f098325D2FcF0d3b9d3d2A9a2",
};

const CHILD_CHAIN_MANAGER_PROXY: AddressMap = {
  // mainnet
  137: "0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa",
  // mumbai
  80001: "0xb5505a6d998549090530911180f38aC5130101c6",
};

export function getL1TokenAddress(chainId: number | undefined): string {
  const testnetIds = [421613, 80001, 420];
  const mainnetIds = [42161, 137, 10];

  if (chainId === undefined || testnetIds.includes(chainId))
    return L1_TOKEN.goerli;

  if (mainnetIds.includes(chainId)) return L1_TOKEN.mainnet;

  throw new Error("Unsupported network for bridge");
}

export function getChildChainManagerProxy(chainId: number | undefined): string {
  return getAddress(CHILD_CHAIN_MANAGER_PROXY, chainId);
}

export function getArbL2Gateway(chainId: number | undefined): string {
  return getAddress(ARBITRUM_L2_GATEWAY, chainId);
}

function getAddress(map: AddressMap, chainId: number | undefined): string {
  const zero = ethers.constants.AddressZero;
  if (chainId === undefined) return zero;

  const address = map[chainId];
  return address ?? zero;
}
