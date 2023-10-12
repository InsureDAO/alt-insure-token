# Alt Insure Token

This is the implementation of the Alt Insure Token which represents an cross-chain-bridged INSURE token.

# Contracts

## AltInsureToken

AltInsureToken is an ERC20 token which is bridged to other chains from Ethereum mainnet. The token is minted when the user locks the INSURE token on the mainnet and is burned when the user unlocks the INSURE token on the mainnet.
This contract is upgradeable because it will need extra logic to support more bridges.

## AltInsureTokenBase

AltInsureTokenBase is the base contract for AltInsureToken. It contains the logic for minting and burning the token in the manners of various bridges.

# Deploy

## Tools

- [hardhat](https://hardhat.org/)
- [mustache](https://mustache.github.io/)

## 1. Locate an config file for a chain

config files are located in `scripts/config` folder. The file name is in the format of `<networkName>.json` .For example, `optimismGoerli.json` is the config file for the OP-Goerli network.

The config file should contain the following fields:

```json
{
  "chainId": 420,
  "l1Token": "0x09f0Ad07E7363557D077CF3e3BbaB9365DA533F6",
  "arbL2Gateway": "0x0000000000000000000000000000000000000000",
  "childChainManagerProxy": "0x0000000000000000000000000000000000000000"
}
```

- `chainId` is the chain id of the network.
- `l1Token` is the address of the INSURE token on the mainnet.
- `arbL2Gateway` is the address of the L2 gateway on the arbitrum network. This field is only required when support arbitrum canonical bridge otherwise it can be set to zero address. the address can be found [here](https://docs.arbitrum.io/for-devs/useful-addresses).
- `childChainManagerProxy` is the address of the child chain manager proxy on the polygon network. This field is only required when support polygon canonical bridge otherwise it can be set to zero address.

## 2. Run the deploy script

The deploy script is located in `scripts/01.initial-deploy.sh`. You can run the script with the following command:

```shell
NETWORK=optimism scripts/01.initial-deploy.sh
```

or you can define node script as shorthand in `package.json`:

```json
{
  ...
  "scripts": {
    ...
    "deploy:optimismGoerli": "NETWORK=optimismGoerli TESTNET=true scripts/01.initial-deploy.sh",
  }
}
```

then run the script with the following command:

```shell
npm run deploy:optimismGoerli
```
