// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

// testing libraries
import "@forge-std/Test.sol";

// contract dependencies
import {GovHelpers, TestWithExecutor} from "@aave-helpers/GovHelpers.sol";
import {AaveV2Ethereum, AaveV2EthereumAssets} from "@aave-address-book/AaveV2Ethereum.sol";
import {ProposalPayload} from "../payloads/LTTailDecemberPayload.sol";
import {ProtocolV2TestBase, ReserveConfig} from '@aave-helpers/ProtocolV2TestBase.sol';
import {AaveGovernanceV2} from '@aave-address-book/AaveAddressBook.sol';


contract ProposalTailAssetsLTPayloadTest is ProtocolV2TestBase, TestWithExecutor {
    uint256 public constant ENS_LTV = 4700; /// 50 -> 47
    uint256 public constant ENS_LIQUIDATION_THRESHOLD = 5700; // 60 -> 57

    uint256 public constant MKR_LTV = 6200; /// 65 -> 62
    uint256 public constant MKR_LIQUIDATION_THRESHOLD = 6700; // 70 -> 67

    uint256 public constant SNX_LTV = 4600; /// 49 -> 46
    uint256 public constant SNX_LIQUIDATION_THRESHOLD = 6200; // 65 -> 62

    uint256 public constant CRV_LTV = 5200; /// 55 -> 52
    uint256 public constant CRV_LIQUIDATION_THRESHOLD = 5800; // 61 -> 58

    uint256 public proposalId;
    ProposalPayload public proposalPayload;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 16182710);
        _selectPayloadExecutor(AaveGovernanceV2.SHORT_EXECUTOR);

        // Deploy Payload
        proposalPayload = new ProposalPayload();
    }

    function testDAILTProposal() public {
        ReserveConfig[] memory allConfigsBefore = _getReservesConfigs(
            AaveV2Ethereum.POOL
        );

        _executePayload(address(proposalPayload));

        ReserveConfig[] memory allConfigsAfter = _getReservesConfigs(
            AaveV2Ethereum.POOL
        );

        _validateCountOfListings(0, allConfigsBefore, allConfigsAfter);

        //ENS
        ReserveConfig memory ENSconfig = _findReserveConfig(allConfigsBefore, AaveV2EthereumAssets.ENS_UNDERLYING);
        ENSconfig.ltv = ENS_LTV;
        ENSconfig.liquidationThreshold = ENS_LIQUIDATION_THRESHOLD;

        _validateReserveConfig(ENSconfig, allConfigsAfter);

        //MKR
        ReserveConfig memory MKRconfig = _findReserveConfig(allConfigsBefore, AaveV2EthereumAssets.MKR_UNDERLYING);
        MKRconfig.ltv = MKR_LTV;
        MKRconfig.liquidationThreshold = MKR_LIQUIDATION_THRESHOLD;

        _validateReserveConfig(MKRconfig, allConfigsAfter);

        //SNX
        ReserveConfig memory SNXconfig = _findReserveConfig(allConfigsBefore, AaveV2EthereumAssets.SNX_UNDERLYING);
        SNXconfig.ltv = SNX_LTV;
        SNXconfig.liquidationThreshold = SNX_LIQUIDATION_THRESHOLD;

        _validateReserveConfig(SNXconfig, allConfigsAfter);

        //CRV
        ReserveConfig memory CRVconfig = _findReserveConfig(allConfigsBefore, AaveV2EthereumAssets.CRV_UNDERLYING);
        CRVconfig.ltv = CRV_LTV;
        CRVconfig.liquidationThreshold = CRV_LIQUIDATION_THRESHOLD;

        _validateReserveConfig(CRVconfig, allConfigsAfter);
    }
}
