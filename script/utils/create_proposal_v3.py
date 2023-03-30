from re import T
from create_class import *

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


pr_name = "Chaos Labs change WBTC and DAI risk params Optimism"
proposal_name = "AaveV3OptiRiskParmas"
payload_info = "This proposal change WBTC and DAI risk params"
snapshot_link = None
discussion_link = "https://governance.aave.com/t/arfc-chaos-labs-risk-parameter-updates-aave-v3-optimism-2023-03-22/12421"


create_proposal_pr(pr_name, proposal_name, payload_info,
                   snapshot_link, discussion_link, config, True)
