// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

// testing libraries
import "@forge-std/Test.sol";

// contract dependencies
import {GovHelpers} from "@aave-helpers/GovHelpers.sol";
import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";
import {ProposalPayload} from "../payloads/LTTailDecemberPayload.sol";
import {DeployMainnetProposal} from "../../script/DeployMainnetProposal.s.sol";
import {AaveV2Helpers, ReserveConfig, ReserveTokens, InterestStrategyValues, Market} from "./utils/AaveV2Helpers.sol";

contract ProposalTailAssetsLTPayloadTest is Test {
    address public constant AAVE_WHALE = 0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8;
    string public constant ENS = "ENS";
    string public constant SNX = "SNX";
    string public constant MKR = "MKR";
    string public constant CRV = "CRV";

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

        // Deploy Payload
        proposalPayload = new ProposalPayload();

        // Create Proposal
        vm.prank(AAVE_WHALE);
        proposalId = DeployMainnetProposal._deployMainnetProposal(
            address(proposalPayload),
            bytes32(0x5d0543d0e66abc240eceeae5ada6240d4d6402c2ccfe5ad521824dc36be71c45)
        );
        vm.stopPrank();
    }

    function testDAILTProposal() public {
        require(proposalId != 0, "proposal deployed");
        Market memory market = Market(
            AaveV2Ethereum.POOL_ADDRESSES_PROVIDER,
            AaveV2Ethereum.POOL,
            AaveV2Ethereum.POOL_CONFIGURATOR,
            AaveV2Ethereum.ORACLE,
            AaveV2Ethereum.AAVE_PROTOCOL_DATA_PROVIDER
                );
        ReserveConfig[] memory allConfigsBefore = AaveV2Helpers.getReservesConfigs(
            false,
            market
        );

        GovHelpers.passVoteAndExecute(vm, proposalId);

        ReserveConfig[] memory allConfigsAfter = AaveV2Helpers.getReservesConfigs(
            false,
            market
        );

        AaveV2Helpers._validateCountOfListings(0, allConfigsBefore, allConfigsAfter);

        //ENS
        ReserveConfig memory ENSconfig = AaveV2Helpers.findReserveConfig(allConfigsBefore, ENS, false);
        ENSconfig.ltv = ENS_LTV;
        ENSconfig.liquidationThreshold = ENS_LIQUIDATION_THRESHOLD;

        AaveV2Helpers._validateReserveConfig(ENSconfig, allConfigsAfter);

        //MKR
        ReserveConfig memory MKRconfig = AaveV2Helpers.findReserveConfig(allConfigsBefore, MKR, false);
        MKRconfig.ltv = MKR_LTV;
        MKRconfig.liquidationThreshold = MKR_LIQUIDATION_THRESHOLD;

        AaveV2Helpers._validateReserveConfig(MKRconfig, allConfigsAfter);

        //SNX
        ReserveConfig memory SNXconfig = AaveV2Helpers.findReserveConfig(allConfigsBefore, SNX, false);
        SNXconfig.ltv = SNX_LTV;
        SNXconfig.liquidationThreshold = SNX_LIQUIDATION_THRESHOLD;

        AaveV2Helpers._validateReserveConfig(SNXconfig, allConfigsAfter);

        //CRV
        ReserveConfig memory CRVconfig = AaveV2Helpers.findReserveConfig(allConfigsBefore, CRV, false);
        CRVconfig.ltv = CRV_LTV;
        CRVconfig.liquidationThreshold = CRV_LIQUIDATION_THRESHOLD;

        AaveV2Helpers._validateReserveConfig(CRVconfig, allConfigsAfter);
    }
}
