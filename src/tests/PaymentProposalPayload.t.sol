// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

// testing libraries
import "@forge-std/Test.sol";

// contract dependencies
import {GovHelpers} from "@aave-helpers/GovHelpers.sol";
import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";
import {ProposalPayload} from "../payloads/PaymentProposalPayload.sol";
import {DeployMainnetProposal} from "../../script/DeployMainnetProposal.s.sol";
import {IStreamable} from "../external/aave/IStreamable.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract ProposalPayloadTest is Test {
    address public constant AAVE_WHALE = 0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8;

    uint256 public proposalId;

    IERC20 public constant AUSDC = IERC20(0xBcca60bB61934080951369a648Fb03DF4F96263C);

    address public immutable AAVE_COLLECTOR = AaveV2Ethereum.COLLECTOR;
    address public constant CHAOS_RECIPIENT = 0xbC540e0729B732fb14afA240aA5A047aE9ba7dF0;

    IStreamable public immutable STREAMABLE_AAVE_COLLECTOR = IStreamable(AaveV2Ethereum.COLLECTOR);

    uint256 public constant AUSDC_STREAM_AMOUNT = 500000e6 + 12352000;
    // 12 months of 30 days
    uint256 public constant STREAMS_END = 360 days; // 6 months duration from start
    uint256 public constant STREAMS_START = 180 days; // in 6 months
    uint256 public constant NO_PAYMENT_RANGE = 6;
    uint256 public constant ENGAGEMENT_RANGE = 12;

    function setUp() public {
        // To fork at a specific block: vm.createSelectFork(vm.rpcUrl("mainnet", BLOCK_NUMBER));
        vm.createSelectFork(vm.rpcUrl("mainnet"), 16181693);

        // Deploy Payload
        ProposalPayload proposalPayload = new ProposalPayload();

        // Create Proposal
        vm.prank(AAVE_WHALE);
        proposalId = DeployMainnetProposal._deployMainnetProposal(
            address(proposalPayload),
            bytes32(0x5d0543d0e66abc240eceeae5ada6240d4d6402c2ccfe5ad521824dc36be71c45) // TODO: replace with actual ipfshash
        );
    }

    // First 6 months, stream transfers 0 funds.
    function testNoPaymentInitial6Months() public {
        // Capturing next Stream IDs before proposal is executed
        uint256 nextMainnetReserveFactorStreamID = STREAMABLE_AAVE_COLLECTOR.getNextStreamId();

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
            uint256 _ratePerSecondAusdc
        ) = STREAMABLE_AAVE_COLLECTOR.getStream(nextMainnetReserveFactorStreamID);

        assertEq(senderAusdc, AAVE_COLLECTOR);
        assertEq(recipientAusdc, CHAOS_RECIPIENT);
        assertEq(depositAusdc, AUSDC_STREAM_AMOUNT);
        assertEq(tokenAddressAusdc, address(AUSDC));
        assertEq(stopTimeAusdc - startTimeAusdc, STREAMS_END - STREAMS_START);
        assertEq(remainingBalanceAusdc, AUSDC_STREAM_AMOUNT);

        // Checking if Chaos can withdraw from streams
        vm.startPrank(CHAOS_RECIPIENT);
        // Checking Chaos withdrawal every 30 days over 12 month period
        for (uint256 i = 0; i < NO_PAYMENT_RANGE; i++) {
            vm.warp(block.timestamp + 30 days);
            // First 6 months 0 payment
            // Compensating for +1/-1 precision issues when rounding, mainly on aTokens
            // Checking aUSDC stream amount
            assertApproxEqAbs(AUSDC.balanceOf(CHAOS_RECIPIENT), 0, 1);
            // Withdrawl with 0 amount throws exception:
            // https://github.com/bgd-labs/aave-ecosystem-reserve-v2/blob/release/final-proposal/src/AaveEcosystemReserveV2.sol#L282
        }
        assertApproxEqAbs(AUSDC.balanceOf(CHAOS_RECIPIENT), 0, 1);
        vm.stopPrank();
    }

    // Full Payment Term Test. Stream only works months 6-12.
    function testExecute() public {
        uint256 initialChaosAUSDCBalance = AUSDC.balanceOf(CHAOS_RECIPIENT);
        // Capturing next Stream IDs before proposal is executed
        uint256 nextMainnetReserveFactorStreamID = STREAMABLE_AAVE_COLLECTOR.getNextStreamId();

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
        assertEq(stopTimeAusdc - startTimeAusdc, STREAMS_END - STREAMS_START);
        assertEq(remainingBalanceAusdc, AUSDC_STREAM_AMOUNT);

        // Checking if Chaos can withdraw from streams
        vm.startPrank(CHAOS_RECIPIENT);
        // Checking Chaos withdrawal every 30 days over 12 month period
        for (uint256 i = 0; i < ENGAGEMENT_RANGE; i++) {
            vm.warp(block.timestamp + 30 days);
            if (i < NO_PAYMENT_RANGE) {
                // First 6 months 0 payment
                // Compensating for +1/-1 precision issues when rounding, mainly on aTokens
                // Checking aUSDC stream amount
                assertApproxEqAbs(AUSDC.balanceOf(CHAOS_RECIPIENT), 0, 1);
                // Withdrawl with 0 amount throws exception:
                // https://github.com/bgd-labs/aave-ecosystem-reserve-v2/blob/release/final-proposal/src/AaveEcosystemReserveV2.sol#L282
                continue;
            }
            uint256 currentAusdcChaosBalance = AUSDC.balanceOf(CHAOS_RECIPIENT);
            uint256 currentAusdcChaosStreamBalance = STREAMABLE_AAVE_COLLECTOR.balanceOf(
                nextMainnetReserveFactorStreamID,
                CHAOS_RECIPIENT
            );

            STREAMABLE_AAVE_COLLECTOR.withdrawFromStream(
                nextMainnetReserveFactorStreamID,
                currentAusdcChaosStreamBalance
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
        }

        //check final numbers:
        assertEq(AUSDC.balanceOf(CHAOS_RECIPIENT) >= initialChaosAUSDCBalance + AUSDC_STREAM_AMOUNT, true);
        vm.stopPrank();
    }
}
