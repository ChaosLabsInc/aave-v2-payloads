// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import {AaveV2Ethereum, AaveV2EthereumAssets} from "@aave-address-book/AaveV2Ethereum.sol";

/**
 * @title Chaos <> AAVE Proposal
 * @author Chaos
 * @notice Tail assets LT changes
 * Governance Forum Post: https://governance.aave.com/t/arc-risk-parameter-updates-for-aave-v2-ethereum-lts-and-ltvs-for-long-tail-assets-2022-12-04/10926
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0xd706dfcb631076d5e835e0640d120b8de333d31ef30f66e3dbb529a380608ea1
 */
contract ProposalPayload {
    uint256 public constant ENS_LTV = 4700; /// 50 -> 47
    uint256 public constant ENS_LIQUIDATION_THRESHOLD = 5700; // 60 -> 57
    uint256 public constant ENS_LIQUIDATION_BONUS = 10800; //unchanged

    uint256 public constant MKR_LTV = 6200; /// 65 -> 62
    uint256 public constant MKR_LIQUIDATION_THRESHOLD = 6700; // 70 -> 67
    uint256 public constant MKR_LIQUIDATION_BONUS = 10750; //unchanged

    uint256 public constant SNX_LTV = 4600; /// 49 -> 46
    uint256 public constant SNX_LIQUIDATION_THRESHOLD = 6200; // 65 -> 62
    uint256 public constant SNX_LIQUIDATION_BONUS = 10750; //unchanged

    uint256 public constant CRV_LTV = 5200; /// 55 -> 52
    uint256 public constant CRV_LIQUIDATION_THRESHOLD = 5800; // 61 -> 58
    uint256 public constant CRV_LIQUIDATION_BONUS = 10800; //unchanged

    function execute() external {
        AaveV2Ethereum.POOL_CONFIGURATOR.configureReserveAsCollateral(
            AaveV2EthereumAssets.ENS_UNDERLYING,
            ENS_LTV,
            ENS_LIQUIDATION_THRESHOLD,
            ENS_LIQUIDATION_BONUS
        );

        AaveV2Ethereum.POOL_CONFIGURATOR.configureReserveAsCollateral(
            AaveV2EthereumAssets.MKR_UNDERLYING,
            MKR_LTV,
            MKR_LIQUIDATION_THRESHOLD,
            MKR_LIQUIDATION_BONUS
        );

        AaveV2Ethereum.POOL_CONFIGURATOR.configureReserveAsCollateral(
            AaveV2EthereumAssets.SNX_UNDERLYING,
            SNX_LTV,
            SNX_LIQUIDATION_THRESHOLD,
            SNX_LIQUIDATION_BONUS
        );

        AaveV2Ethereum.POOL_CONFIGURATOR.configureReserveAsCollateral(
            AaveV2EthereumAssets.CRV_UNDERLYING,
            CRV_LTV,
            CRV_LIQUIDATION_THRESHOLD,
            CRV_LIQUIDATION_BONUS
        );
    }
}
