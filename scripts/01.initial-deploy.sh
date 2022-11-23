npx hardhat clean

if [ -z "$NETWORK" ]; then
  echo "ERROR: NETWORK environment variable required"
  exit 1
fi

if "${TESTNET}"; then
  ROOT_DIR="scripts/config/testnets"
  echo "testnet"
else
  ROOT_DIR="scripts/config/mainnets"
  echo "mainnet"
fi

npx mustache $ROOT_DIR/$NETWORK.json scripts/templates/01.initial-deploy.mst > scripts/artifacts/01.initial-deploy.ts

echo 'generated 01.initial-deploy.ts'

npx hardhat run scripts/artifacts/01.initial-deploy.ts --network $NETWORK