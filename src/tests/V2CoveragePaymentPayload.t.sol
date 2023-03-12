// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

// testing libraries
import "@forge-std/Test.sol";

// contract dependencies
import {GovHelpers, TestWithExecutor} from "@aave-helpers/GovHelpers.sol";
import {AaveV2Ethereum, AaveV2EthereumAssets} from "@aave-address-book/AaveV2Ethereum.sol";
import {ProposalPayload} from "../payloads/V2CoveragePaymentPayload.sol";
import {IStreamable} from "../external/aave/IStreamable.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {AaveMisc} from '@aave-address-book/AaveMisc.sol';
import {ProtocolV2TestBase, ReserveConfig} from '@aave-helpers/ProtocolV2TestBase.sol';
import {AaveGovernanceV2} from '@aave-address-book/AaveAddressBook.sol';


contract ProposalPaymentPayloadV2Test is ProtocolV2TestBase, TestWithExecutor {
    uint256 public proposalId;

    IERC20 public constant AUSDC = IERC20(AaveV2EthereumAssets.USDC_A_TOKEN);
    IERC20 public constant AAVE = IERC20(AaveV2EthereumAssets.AAVE_UNDERLYING);

    address public immutable AAVE_COLLECTOR = AaveV2Ethereum.COLLECTOR;
    address public constant AAVE_ECOSYSTEM_RESERVE = AaveMisc.ECOSYSTEM_RESERVE;
    address public constant CHAOS_RECIPIENT = 0xbC540e0729B732fb14afA240aA5A047aE9ba7dF0;

    IStreamable public immutable STREAMABLE_AAVE_COLLECTOR = IStreamable(AaveV2Ethereum.COLLECTOR);
    IStreamable public constant STREAMABLE_AAVE_ECOSYSTEM_RESERVE = IStreamable(AAVE_ECOSYSTEM_RESERVE);

    uint256 public constant AUSDC_STREAM_AMOUNT = 175000e6;
    //TODO: whats the remainder here?
    uint256 public constant AAVE_STREAM_AMOUNT = 1242e18;

    // 5 months of 30 days
    uint256 public constant STREAMS_DURATION = 150 days; // 5*30 days duration

    uint256 public constant ENGAGEMENT_RANGE = 5; // 5 months duration

    function setUp() public {
        // To fork at a specific block: vm.createSelectFork(vm.rpcUrl("mainnet", BLOCK_NUMBER));
        vm.createSelectFork(vm.rpcUrl("mainnet"), 16283051);
        _selectPayloadExecutor(AaveGovernanceV2.SHORT_EXECUTOR);
    }

    // Full Payment Term Test. Stream 5 months.
    function testExecuteUsdc() public {
        uint256 actualAmountUSDC = (AUSDC_STREAM_AMOUNT / STREAMS_DURATION) * STREAMS_DURATION; // rounding
        uint256 initialChaosAUSDCBalance = AUSDC.balanceOf(CHAOS_RECIPIENT);

        // Capturing next Stream IDs before proposal is executed
        uint256 nextMainnetReserveFactorStreamID = STREAMABLE_AAVE_COLLECTOR.getNextStreamId();

        // Pass vote and execute proposal
        _executePayload(address(new ProposalPayload()));

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
        assertEq(depositAusdc, actualAmountUSDC);
        assertEq(tokenAddressAusdc, address(AUSDC));
        assertEq(stopTimeAusdc - startTimeAusdc, STREAMS_DURATION);
        assertEq(remainingBalanceAusdc, actualAmountUSDC);

        // Checking if Chaos can withdraw from streams
        vm.startPrank(CHAOS_RECIPIENT);
        // Checking Chaos withdrawal every 30 days over 12 month period
        for (uint256 i = 0; i < ENGAGEMENT_RANGE; i++) {
            vm.warp(block.timestamp + 30 days);
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
        assertEq(AUSDC.balanceOf(CHAOS_RECIPIENT) >= initialChaosAUSDCBalance + actualAmountUSDC, true);
        vm.stopPrank();
    }

    // Full Payment Term Test. Stream 5 months.
    function testExecuteAave() public {
        uint256 actualAmountAave = (AAVE_STREAM_AMOUNT / STREAMS_DURATION) * STREAMS_DURATION; // rounding
        uint256 initialChaosAAVEBalance = AAVE.balanceOf(CHAOS_RECIPIENT);

        // Capturing next Stream IDs before proposal is executed
        uint256 nextEcosystemReserveStreamID = STREAMABLE_AAVE_ECOSYSTEM_RESERVE.getNextStreamId();

        // Pass vote and execute proposal
        _executePayload(address(new ProposalPayload()));

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
        assertEq(depositAave, actualAmountAave);
        assertEq(tokenAddressAave, address(AAVE));
        assertEq(stopTimeAave - startTimeAave, STREAMS_DURATION);
        assertEq(remainingBalanceAave, actualAmountAave);

        // Checking if Chaos can withdraw from streams
        vm.startPrank(CHAOS_RECIPIENT);
        // Checking Chaos withdrawal every 30 days over 12 month period
        for (uint256 i = 0; i < ENGAGEMENT_RANGE; i++) {
            vm.warp(block.timestamp + 30 days);
            uint256 currentAaveChaosBalance = AAVE.balanceOf(CHAOS_RECIPIENT);
            uint256 currentAaveChaosStreamBalance = STREAMABLE_AAVE_ECOSYSTEM_RESERVE.balanceOf(
                nextEcosystemReserveStreamID,
                CHAOS_RECIPIENT
            );

            STREAMABLE_AAVE_ECOSYSTEM_RESERVE.withdrawFromStream(
                nextEcosystemReserveStreamID,
                currentAaveChaosStreamBalance
            );

            // Checking AAVE stream amount
            assertEq(AAVE.balanceOf(CHAOS_RECIPIENT), currentAaveChaosBalance + currentAaveChaosStreamBalance);
            assertEq(AAVE.balanceOf(CHAOS_RECIPIENT), currentAaveChaosBalance + (ratePerSecondAave * 30 days));
        }

        //check final numbers:
        assertEq(AAVE.balanceOf(CHAOS_RECIPIENT) >= initialChaosAAVEBalance + actualAmountAave, true);
        vm.stopPrank();
    }
}
