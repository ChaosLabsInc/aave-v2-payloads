from enum import Enum

# from github import Github
GIT_REPO_PATH = "https://github.com/Maltmark/aave-proposals"
ASSET = "ASSET"
DATA = "DATA"
ENV = "ENV"
CHAIN = "CHAIN"

VALUE = "VALUE"
IS_CHANGED = "IS_CHANGED"

UINT = "uint256 public constant"
BOOL = "bool public constant"

BLOCK_NUMBER_TO_TEST = "BLOCK_NUMBER_TO_TEST"


class Field(Enum):
    BORROW_CAP = "BORROW_CAP"
    SUPPLY_CAP = "SUPPLY_CAP"
    LIQ_THRESHOLD = "LIQ_THRESHOLD"
    LTV = "LTV"
    LIQ_BONUS = "LIQ_BONUS"
    BORROWABLE_IN_ISOLATION = "BORROWABLE_IN_ISOLATION"


class Chain(Enum):
    ARBITRUM = "arbitrum"
    POLYGON = "polygon"
    MAINNET = "mainnet"
    OPTIMISM = "optimism"


class Action(Enum):
    PARAMS = "PARAMS"
    RISK_PARAMS = "RISK_PARAMS"


FIELD_TO_CHANGE_NAME_MAP = {
    Field.BORROW_CAP: "setBorrowCap",
    Field.SUPPLY_CAP: "setSupplyCap",
    Field.BORROWABLE_IN_ISOLATION: "setBorrowableInIsolation",
}

FIELD_TO_ASSERT_NAME_MAP = {
    Field.BORROW_CAP: "borrowCap",
    Field.SUPPLY_CAP: "supplyCap",
    Field.LIQ_THRESHOLD: "liquidationThreshold",
    Field.LIQ_BONUS: "liquidationBonus",
    Field.LTV: "ltv",
    Field.BORROWABLE_IN_ISOLATION: "isBorrowableInIsolation",

}

CHAIN_CONFIG = {
    Chain.ARBITRUM: {
        "name": "arbitrum",
        "address_book": "AaveV3Arbitrum",
        "executor": "AaveGovernanceV2.ARBITRUM_BRIDGE_EXECUTOR",
    },
    Chain.POLYGON: {
        "name": "polygon",
        "address_book": "AaveV3Polygon",
        "executor": "AaveGovernanceV2.POLYGON_BRIDGE_EXECUTOR",

    },
    Chain.MAINNET: {
        "name": "mainnet",
        'address_book': "AaveV3Ethereum",
        "executor": "AaveGovernanceV2.SHORT_EXECUTOR",
    },
    Chain.OPTIMISM: {
        "name": "optimism",
        'address_book': "AaveV3Optimism",
        "executor": "AaveGovernanceV2.OPTIMISM_BRIDGE_EXECUTOR"
    }
}
