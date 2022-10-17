# Chaso <> AAVE Proposal

Payload and tests for the Chaos <> AAVE Proposal

## Specification

This repository contains the [Payload](https://github.com/ChaosLabsInc/aave-chaos-v3-risk-proposal/blob/main/src/ProposalPayload.sol) and [Tests](https://github.com/ChaosLabsInc/aave-chaos-v3-risk-proposal/blob/main/src/test/ProposalPayload.t.sol) for the [Chaos <> Aave Proposal](https://governance.aave.com/t/updated-proposal-chaos-labs-risk-simulation-platform/10025)

The Proposal Payload does the following:

1. Creates a 6-month stream of 500,000 aUSDC ($0.5 Million) to the Chaos-controlled address.

## Installation

It requires [Foundry](https://github.com/gakonst/foundry) installed to run. You can find instructions here [Foundry installation](https://github.com/gakonst/foundry#installation).

In order to install, run the following commands:

```sh
$ git clone https://github.com/ChaosLabsInc/aave-chaos-v3-risk-proposal
$ cd aave-chaos-proposal/
$ npm install
$ forge install
```

## Setup

Duplicate `.env.example` and rename to `.env`:

- Add a valid mainnet URL for an Ethereum JSON-RPC client for the `RPC_MAINNET_URL` variable.
- Add a valid Private Key for the `PRIVATE_KEY` variable.
- Add a valid Etherscan API Key for the `ETHERSCAN_API_KEY` variable.

### Commands

- `make build` - build the project
- `make test [optional](V={1,2,3,4,5})` - run tests (with different debug levels if provided)
- `make match MATCH=<TEST_FUNCTION_NAME> [optional](V=<{1,2,3,4,5}>)` - run matched tests (with different debug levels if provided)

### Deploy and Verify

- `make deploy-payload` - deploy and verify payload on mainnet
- `make deploy-proposal`- deploy proposal on mainnet

To confirm the deploy was successful, re-run your test suite but use the newly created contract address.
