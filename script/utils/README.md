# Script to generate proposal

## How to use

1. the script should be run from the local fork of aave-proposal repository
2. in create_proposal_v3.py:
   a. Set the config JSON with the needed changes:
   example:

```
config = {
    CHAIN: Chain.OPTIMISM,
    BLOCK_NUMBER_TO_TEST: 84619167,
    Action.RISK_PARAMS: [{
        ASSET: "WBTC_UNDERLYING",
        DATA: {Field.LIQ_THRESHOLD: {VALUE: 7800, IS_CHANGED: True},
               Field.LTV: {VALUE: 7300, IS_CHANGED: True},
               Field.LIQ_BONUS: {VALUE: 10850, IS_CHANGED: True},
               }
    },
        {
        ASSET: "DAI_UNDERLYING",
        DATA: {Field.LIQ_THRESHOLD: {VALUE: 8300, IS_CHANGED: True},
               Field.LTV: {VALUE: 7800, IS_CHANGED: True},
               Field.LIQ_BONUS: {VALUE: 10500, IS_CHANGED: False},
               }
    },]

}
```

- CHAIN: the chain (support Optimism, Polygon, Mainnet, Arbitrum)
- BLOCK_NUMBER_TO_TEST: block number to test the code (from last days)
- Action.PARAMS: genral parameters to change - supported parameters: supply caps, borrow caps, borrowable isolation
- Action.RISK_PARAMS: risk parameters to change (LTV, LT LB)
- ASSET: the name of the asset as define in chain address book
- DATA: JSON with 2 keys - value and is changed (if value was not change pass False)
