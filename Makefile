-include .env

deploy-sepolia:
	forge script script/DeployMultiSigWallet.s.sol:DeployMultiSigWallet --rpc-url $RPC_URL --private-key $PRIVATE_KEY1 --broadcast --verify --etherscan-api-key $API_KEY -vvvv

deploy-anvil:
	forge script script/DeployMultiSigWallet.s.sol:DeployMultiSigWallet --rpc-url http:/127.0.0.1:8545/ --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast

fund-avil:
	forge script script/Interactions.s.sol:DepositOnWallet_MultiSigWallet --rpc-url http:/127.0.0.1:8545/ --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast

fund-sepolia:
	forge script script/Interactions.s.sol:DepositOnWallet_MultiSigWallet --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

submit-sepolia:
	forge script script/Interactions.s.sol:Submit_MultiSigWallet --rpc-url $RPC_URL --private-key $PRIVATE_KEY1 --broadcast

approve-sepolia1:
	forge script script/Interactions.s.sol:ApproveTransaction_MultiSigWallet --rpc-url $RPC_URL --private-key $PRIVATE_KEY1 --broadcast

approve-sepolia2:
	forge script script/Interactions.s.sol:ApproveTransaction_MultiSigWallet --rpc-url $RPC_URL --private-key $PRIVATE_KEY2 --broadcast

execute-sepolia:
	forge script script/Interactions.s.sol:ExecuteTransaction_MultiSigWallet --rpc-url $RPC_URL --private-key $PRIVATE_KEY1 --broadcast

