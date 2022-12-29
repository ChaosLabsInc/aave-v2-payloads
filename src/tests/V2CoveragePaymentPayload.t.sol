// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

// testing libraries
import "@forge-std/Test.sol";

// contract dependencies
import {GovHelpers} from "@aave-helpers/GovHelpers.sol";
import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";
import {ProposalPayload} from "../payloads/V2CoveragePaymentPayload.sol";
import {DeployMainnetProposal} from "../../script/DeployMainnetProposal.s.sol";
import {IStreamable} from "../external/aave/IStreamable.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract ProposalPaymentPayloadTest is Test {
    address public constant AAVE_WHALE = 0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8;

    uint256 public proposalId;

    IERC20 public constant AUSDC = IERC20(0xBcca60bB61934080951369a648Fb03DF4F96263C);
    IERC20 public constant AAVE = IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);

    address public immutable AAVE_COLLECTOR = AaveV2Ethereum.COLLECTOR;
    address public constant AAVE_ECOSYSTEM_RESERVE = 0x25F2226B597E8F9514B3F68F00f494cF4f286491;
    address public constant CHAOS_RECIPIENT = 0xbC540e0729B732fb14afA240aA5A047aE9ba7dF0;

    IStreamable public immutable STREAMABLE_AAVE_COLLECTOR = IStreamable(AaveV2Ethereum.COLLECTOR);
    IStreamable public constant STREAMABLE_AAVE_ECOSYSTEM_RESERVE = IStreamable(AAVE_ECOSYSTEM_RESERVE);

    uint256 public constant AUSDC_STREAM_AMOUNT = 175000e6 + 11840000;
    //TODO: whats the remainder here?
    uint256 public constant AAVE_STREAM_AMOUNT = 1242e18 + 8640000;

    // 5 months of 30 days
    uint256 public constant STREAMS_DURATION = 150 days; // 5*30 days duration

    uint256 public constant ENGAGEMENT_RANGE = 5; // 5 months duration

    function setUp() public {
        // To fork at a specific block: vm.createSelectFork(vm.rpcUrl("mainnet", BLOCK_NUMBER));
        vm.createSelectFork(vm.rpcUrl("mainnet"), 16283051);

        // Deploy Payload
        ProposalPayload proposalPayload = new ProposalPayload();

        // Create Proposal
        vm.prank(AAVE_WHALE);
        proposalId = DeployMainnetProposal._deployMainnetProposal(
            address(proposalPayload),
            bytes32(0x5d0543d0e66abc240eceeae5ada6240d4d6402c2ccfe5ad521824dc36be71c45) // TODO: replace with actual ipfshash
        );
    }

    // Full Payment Term Test. Stream 5 months.
    function testExecute() public {
        uint256 initialChaosAUSDCBalance = AUSDC.balanceOf(CHAOS_RECIPIENT);
        uint256 initialChaosAAVEBalance = AAVE.balanceOf(CHAOS_RECIPIENT);
        uint256 initialMainnetReserveFactorAusdcBalance = AUSDC.balanceOf(AAVE_COLLECTOR);
        uint256 initialEcosystemReserveAaveBalance = AAVE.balanceOf(AAVE_ECOSYSTEM_RESERVE);

        // Capturing next Stream IDs before proposal is executed
        uint256 nextMainnetReserveFactorStreamID = STREAMABLE_AAVE_COLLECTOR.getNextStreamId();
        uint256 nextEcosystemReserveStreamID = STREAMABLE_AAVE_ECOSYSTEM_RESERVE.getNextStreamId();

        // Pass vote and execute proposal
        GovHelpers.passVoteAndExecute(vm, proposalId);

        // Checking if the streams have been created properly
        // aUSDC stream
        (
            address senderAusdc,
            address recipientAusdc,
            uint256 depositAusdc,
            address tokenAddressAusdc,
            uint256 startTimeAusdc,
            uint256 stopTimeAusdc,
            uint256 remainingBalanceAusdc,
            uint256 ratePerSecondAusdc
        ) = STREAMABLE_AAVE_COLLECTOR.getStream(nextMainnetReserveFactorStreamID);

        assertEq(senderAusdc, AAVE_COLLECTOR);
        assertEq(recipientAusdc, CHAOS_RECIPIENT);
        assertEq(depositAusdc, AUSDC_STREAM_AMOUNT);
        assertEq(tokenAddressAusdc, address(AUSDC));
        assertEq(stopTimeAusdc - startTimeAusdc, STREAMS_DURATION);
        assertEq(remainingBalanceAusdc, AUSDC_STREAM_AMOUNT);

        // AAVE stream
        (
            address senderAave,
            address recipientAave,
            uint256 depositAave,
            address tokenAddressAave,
            uint256 startTimeAave,
            uint256 stopTimeAave,
            uint256 remainingBalanceAave,
            uint256 ratePerSecondAave
        ) = STREAMABLE_AAVE_ECOSYSTEM_RESERVE.getStream(nextEcosystemReserveStreamID);

        assertEq(senderAave, AAVE_ECOSYSTEM_RESERVE);
        assertEq(recipientAave, CHAOS_RECIPIENT);
        assertEq(depositAave, AAVE_STREAM_AMOUNT);
        assertEq(tokenAddressAave, address(AAVE));
        assertEq(stopTimeAave - startTimeAave, STREAMS_DURATION);
        assertEq(remainingBalanceAave, AAVE_STREAM_AMOUNT);

        // Checking if Chaos can withdraw from streams
        vm.startPrank(CHAOS_RECIPIENT);
        // Checking Chaos withdrawal every 30 days over 12 month period
        for (uint256 i = 0; i < ENGAGEMENT_RANGE; i++) {
            vm.warp(block.timestamp + 30 days);
            uint256 currentAusdcChaosBalance = AUSDC.balanceOf(CHAOS_RECIPIENT);
            uint256 currentAaveChaosBalance = AAVE.balanceOf(CHAOS_RECIPIENT);
            uint256 currentAusdcChaosStreamBalance = STREAMABLE_AAVE_COLLECTOR.balanceOf(
                nextMainnetReserveFactorStreamID,
                CHAOS_RECIPIENT
            );
            uint256 currentAaveChaosStreamBalance = STREAMABLE_AAVE_ECOSYSTEM_RESERVE.balanceOf(
                nextEcosystemReserveStreamID,
                CHAOS_RECIPIENT
            );

            STREAMABLE_AAVE_COLLECTOR.withdrawFromStream(
                nextMainnetReserveFactorStreamID,
                currentAusdcChaosStreamBalance
            );

            STREAMABLE_AAVE_ECOSYSTEM_RESERVE.withdrawFromStream(
                nextEcosystemReserveStreamID,
                currentAaveChaosStreamBalance
            );

            // Compensating for +1/-1 precision issues when rounding, mainly on aTokens
            // Checking aUSDC stream amount
            assertApproxEqAbs(
                AUSDC.balanceOf(CHAOS_RECIPIENT),
                currentAusdcChaosBalance + currentAusdcChaosStreamBalance,
                1
            );
            assertApproxEqAbs(
                AUSDC.balanceOf(CHAOS_RECIPIENT),
                currentAusdcChaosBalance + (ratePerSecondAusdc * 30 days),
                1
            );

            // Checking AAVE stream amount
            assertEq(AAVE.balanceOf(CHAOS_RECIPIENT), currentAaveChaosBalance + currentAaveChaosStreamBalance);
            assertEq(AAVE.balanceOf(CHAOS_RECIPIENT), currentAaveChaosBalance + (ratePerSecondAave * 30 days));
        }

        //check final numbers:
        assertEq(AUSDC.balanceOf(CHAOS_RECIPIENT) >= initialChaosAUSDCBalance + AUSDC_STREAM_AMOUNT, true);
        assertEq(AAVE.balanceOf(CHAOS_RECIPIENT) >= initialChaosAAVEBalance + AAVE_STREAM_AMOUNT, true);
        vm.stopPrank();
    }
}
