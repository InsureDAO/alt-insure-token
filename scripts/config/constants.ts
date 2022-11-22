import { ethers } from "ethers";

interface AddressMap {
  [key: number]: string | undefined;
}

const L1_TOKEN = {
  mainnet: "",
  goerli: "0x78D4979D12955e21dBb6e589D11F4865CeBf8b89",
};

const ARBITRUM_L2_GATEWAY: AddressMap = {
  // arbitrum one
  42161: "0x096760F208390250649E3e8763348E783AEF5562",
  // arbitrum goerli
  421613: "0x8b6990830cF135318f75182487A4D7698549C717",
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
