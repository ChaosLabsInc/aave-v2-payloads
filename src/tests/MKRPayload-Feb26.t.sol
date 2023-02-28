// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

// testing libraries
import "@forge-std/Test.sol";

// contract dependencies
import {GovHelpers} from "@aave-helpers/GovHelpers.sol";
import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";
import {AaveAddressBookV2} from "@aave-address-book/AaveAddressBook.sol";
import {ProposalPayload} from "../payloads/MKRPayload-Feb26.sol";
import {DeployMainnetProposal} from "../../script/DeployMainnetProposal.s.sol";
import {AaveV2Helpers, ReserveConfig, ReserveTokens, InterestStrategyValues} from "./utils/AaveV2Helpers.sol";

contract ProposalMKRPayloadTest is Test {
    string public constant MKRSymbol = "MKR";

    uint256 public constant MKR_LTV = 5900; ///  59%
    uint256 public constant MKR_LIQUIDATION_THRESHOLD = 6400; // 64%


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

    function testProposal() public {
        require(proposalId != 0, "proposal deployed");
        ReserveConfig[] memory allConfigsBefore = AaveV2Helpers._getReservesConfigs(
            false,
            AaveAddressBookV2.AaveV2Ethereum
        );
        ReserveConfig memory config = AaveV2Helpers._findReserveConfig(allConfigsBefore, DAISymbol, false);

        GovHelpers.passVoteAndExecute(vm, proposalId);

        ReserveConfig[] memory allConfigsAfter = AaveV2Helpers._getReservesConfigs(
            false,
            AaveAddressBookV2.AaveV2Ethereum
        );

        AaveV2Helpers._validateCountOfListings(0, allConfigsBefore, allConfigsAfter);

        config.ltv = MKR_LTV;
        config.liquidationThreshold = MKR_LIQUIDATION_THRESHOLD;
        AaveV2Helpers._validateReserveConfig(config, allConfigsAfter);
    }
}
