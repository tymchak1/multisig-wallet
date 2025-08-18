-include .env

RPC_LOCAL=http://127.0.0.1:8545/
ANVIL_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
NETWORK ?= anvil

.PHONY: all reset test clean deploy fund help install snapshot format anvil coverage-html

help:
	@echo "Usage:"
	@echo "  make all            - clean, reinstall, update and build"
	@echo "  make clean          - clean the repo"
	@echo "  make remove         - remove modules"
	@echo "  make install        - install dependencies"
	@echo "  make update         - update dependencies"
	@echo "  make build          - build contracts"
	@echo "  make test           - run tests"
	@echo "  make coverage       - run coverage (text)"
	@echo "  make coverage-html  - run coverage and generate HTML report"
	@echo "  make snapshot       - take gas snapshot"
	@echo "  make format         - format contracts"
	@echo "  make anvil          - run local anvil node"
	@echo "  make deploy-anvil   - deploy to anvil"
	@echo "  make deploy-sepolia - deploy to sepolia"
	@echo "  make fund-anvil     - fund wallet on anvil"
	@echo "  make fund-sepolia   - fund wallet on sepolia"
	@echo "  make submit-sepolia - submit tx on sepolia"
	@echo "  make approve-sepolia1/2 - approve tx on sepolia"
	@echo "  make execute-sepolia - execute tx on sepolia"

all: clean remove install update build

reset: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install cyfrin/foundry-devops@0.1.0 --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

coverage :; forge coverage --report debug > coverage-report.txt

coverage-html :; forge coverage --report lcov && genhtml lcov.info --output-dir coverage-html

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1



deploy-anvil:
	forge script script/DeployMultiSigWallet.s.sol:DeployMultiSigWallet --rpc-url $(RPC_LOCAL) --private-key $(ANVIL_KEY) --broadcast

fund-anvil:
	forge script script/Interactions.s.sol:DepositOnWallet_MultiSigWallet --rpc-url $(RPC_LOCAL) --private-key $(ANVIL_KEY) --broadcast


deploy-sepolia:
	forge script script/DeployMultiSigWallet.s.sol:DeployMultiSigWallet --rpc-url $RPC_URL --private-key $PRIVATE_KEY1 --broadcast --verify --etherscan-api-key $API_KEY -vvvv

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
