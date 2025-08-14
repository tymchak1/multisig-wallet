-include .env

deploy-sepolia:
	forge script script/DeployMultiSigWallet.s.sol:DeployMultiSigWallet --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $API_KEY -vvvv