# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
update   :; forge update
install  :; forge install

# Build & test
build    :; forge clean && forge build
test     :; forge test --etherscan-api-key ${ETHERSCAN_API_KEY} -vv
match    :; forge clean && forge test --etherscan-api-key ${ETHERSCAN_API_KEY} -m ${MATCH} -vvv
report   :; forge clean && forge test --gas-report | sed -e/╭/\{ -e:1 -en\;b1 -e\} -ed | cat > .gas-report

test-only :;  forge clean && forge test -vvv --match-contract ProposalMKRPayloadTest

# Deploy and Verify Payload
deploy-payload :; forge script script/DeployProposalPayload.s.sol:DeployProposalPayload --rpc-url ${RPC_ETHEREUM} --broadcast --private-key ${PRIVATE_KEY} --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv
verify-payload :; forge script script/DeployProposalPayload.s.sol:DeployProposalPayload --rpc-url ${RPC_ETHEREUM} --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv

# Deploy Proposal
deploy-proposal :; forge script script/DeployMainnetProposal.s.sol:DeployProposal --rpc-url ${RPC_ETHEREUM} --broadcast --private-key ${PRIVATE_KEY} -vvvv
emit-proposal :; forge script script/specific/DeployLongTailLTProposal.s.sol:EmitOp --rpc-url ${RPC_ETHEREUM} --broadcast --private-key ${PRIVATE_KEY} -vvvv
emit-multi-proposal :; forge script script/DeployMultiMainnetProposal.s.sol:EmitOp --rpc-url ${RPC_ETHEREUM} --broadcast --private-key ${PRIVATE_KEY} -vvvv


#specific:
deploy-stable-lt-proposal :; forge script script/specific/DeployDaiAndUsdcLTsProposal.s.sol:DeployProposal --rpc-url ${RPC_ETHEREUM} --broadcast --private-key ${PRIVATE_KEY} -vvvv
deploy-tail-lt-proposal :; forge script script/specific/DeployLongTailLTProposal.s.sol:DeployProposal --rpc-url ${RPC_ETHEREUM} --broadcast --private-key ${PRIVATE_KEY} -vvvv


# Clean & lint
clean    :; forge clean
lint     :; npx prettier --write src/**/*.sol

deploy2-payload :; forge script  script/specific/DeployV2CoverageProposalPayload.s.sol:DeployProposalPayload --rpc-url ${RPC_ETHEREUM} --broadcast --private-key ${PRIVATE_KEY} --verify --etherscan-api-key ${AVALACNHE_API_KEY} -vvvv

# verify contract example:
verify-contract :; forge verify-contract 0x8922235734ec69e956977e2ea9774de8f614053a src/payloads/V2CoveragePaymentPayload.sol:ProposalPayload #--etherscan-api-key ${AVALACNHE_API_KEY}