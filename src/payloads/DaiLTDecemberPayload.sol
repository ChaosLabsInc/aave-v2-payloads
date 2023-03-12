// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {AaveV2Ethereum, AaveV2EthereumAssets} from "@aave-address-book/AaveV2Ethereum.sol";

/**
 * @title Chaos <> AAVE Proposal
 * @author Chaos
 * @notice DAI LT changes
 * Governance Forum Post: https://governance.aave.com/t/arc-risk-parameter-updates-for-aave-v2-ethereum-lt-and-ltv-2022-12-01/10897
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0xb81e12285c6de6f9fec9906c6d0149b33809c2ba6cf79a05cdab26ea70caadff
 */
contract ProposalPayload {
    uint256 public constant LTV = 7500; // 77 -> 75
    uint256 public constant LIQUIDATION_THRESHOLD = 8700; // 90 -> 87
    uint256 public constant LIQUIDATION_BONUS = 10400; //unchanged - 10400

    function execute() external {
        AaveV2Ethereum.POOL_CONFIGURATOR.configureReserveAsCollateral(
            AaveV2EthereumAssets.DAI_UNDERLYING,
            LTV,
            LIQUIDATION_THRESHOLD,
            LIQUIDATION_BONUS
        );
    }
}
