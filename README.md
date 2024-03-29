# Chaso <> AAVE Proposals & payloads

Payload and tests for the Chaos <> AAVE Proposals

## Installation

It requires [Foundry](https://github.com/gakonst/foundry) installed to run. You can find instructions here [Foundry installation](https://github.com/gakonst/foundry#installation).

In order to install, run the following commands:

```sh
$ npm install
$ forge install
```

## Setup

Duplicate `.env.example` and rename to `.env`:

- Add a valid mainnet URL for an Ethereum JSON-RPC client for the `RPC_ETHEREUM` variable.
- Add a valid Private Key for the `PRIVATE_KEY` variable.
- Add a valid Etherscan API Key for the `ETHERSCAN_API_KEY` variable.

### Commands

- `make build` - build the project
- `make test` - run tests
- `make match MATCH=<TEST_FUNCTION_NAME>` - run matched tests

### Deploy and Verify

- `make deploy-payload` - deploy and verify payload on mainnet
- `make deploy-proposal`- deploy proposal on mainnet

To confirm the deploy was successful, re-run your test suite but use the newly created contract address.

### Update dependencies

1. `forge remove <LIB_PATH>`
   if you get error "recursively without -r" run: `git rm -r --cached <LIB_PATH>`
2. `forge install <LIB_URL> -no-commit`

- `git submodule status` - check dependencies status
