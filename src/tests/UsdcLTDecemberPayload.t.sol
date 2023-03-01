// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

// testing libraries
import "@forge-std/Test.sol";

// contract dependencies
import {GovHelpers} from "@aave-helpers/GovHelpers.sol";
import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";
import {ProposalPayload} from "../payloads/UsdcLTDecemberPayload.sol";
import {DeployMainnetProposal} from "../../script/DeployMainnetProposal.s.sol";
import {AaveV2Helpers, ReserveConfig, ReserveTokens, InterestStrategyValues, Market} from "./utils/AaveV2Helpers.sol";

contract ProposalUsdcLTPayloadTest is Test {
    address public constant AAVE_WHALE = 0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8;
    string public constant USDCSymbol = "USDC";

    uint256 public constant LTV = 8000; /// 87 -> 80
    uint256 public constant LIQUIDATION_THRESHOLD = 8750; // 89 -> 87.5

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
        ReserveConfig memory config = AaveV2Helpers.findReserveConfig(allConfigsBefore, USDCSymbol, false);

        GovHelpers.passVoteAndExecute(vm, proposalId);

        ReserveConfig[] memory allConfigsAfter = AaveV2Helpers.getReservesConfigs(
            false,
            market
        );

        AaveV2Helpers._validateCountOfListings(0, allConfigsBefore, allConfigsAfter);

        // ReserveConfig memory configAfter = AaveV2Helpers.findReserveConfig(allConfigsAfter, USDCSymbol, false);
        // console.log("ltv before", config.ltv);
        // console.log("lq before", config.liquidationThreshold);
        // console.log("lt before", config.liquidationBonus);
        // console.log("ltv after", configAfter.ltv);
        // console.log("lq after", configAfter.liquidationThreshold);
        // console.log("lt after", configAfter.liquidationBonus);

        config.ltv = LTV;
        config.liquidationThreshold = LIQUIDATION_THRESHOLD;
        AaveV2Helpers._validateReserveConfig(config, allConfigsAfter);
    }
}
