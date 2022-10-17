// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

// testing libraries
import "@forge-std/Test.sol";

// contract dependencies
import {GovHelpers} from "@aave-helpers/GovHelpers.sol";
import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";
import {ProposalPayload} from "../ProposalPayload.sol";
import {DeployMainnetProposal} from "../../script/DeployMainnetProposal.s.sol";
import {IStreamable} from "../external/aave/IStreamable.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract ProposalPayloadTest is Test {
    address public constant AAVE_WHALE = 0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8;

    uint256 public proposalId;

    IERC20 public constant AUSDC = IERC20(0xBcca60bB61934080951369a648Fb03DF4F96263C);

    address public immutable AAVE_MAINNET_RESERVE_FACTOR = AaveV2Ethereum.COLLECTOR;
    address public constant AAVE_ECOSYSTEM_RESERVE = 0x25F2226B597E8F9514B3F68F00f494cF4f286491;
    address public constant CHAOS_RECIPIENT = 0xb428C6812E53F843185986472bb7c1E25632e0f7;

    IStreamable public immutable STREAMABLE_AAVE_MAINNET_RESERVE_FACTOR = IStreamable(AaveV2Ethereum.COLLECTOR);
    IStreamable public constant STREAMABLE_AAVE_ECOSYSTEM_RESERVE = IStreamable(AAVE_ECOSYSTEM_RESERVE);

    uint256 public constant AUSDC_STREAM_AMOUNT = 500026624000;
    uint256 public constant STREAMS_DURATION = 180 days;

    function setUp() public {
        // To fork at a specific block: vm.createSelectFork(vm.rpcUrl("mainnet", BLOCK_NUMBER));
        vm.createSelectFork(vm.rpcUrl("mainnet"));

        // Deploy Payload
        ProposalPayload proposalPayload = new ProposalPayload();

        // Create Proposal
        vm.prank(AAVE_WHALE);
        proposalId = DeployMainnetProposal._deployMainnetProposal(
            address(proposalPayload),
            0x344d3181f08b3186228b93bac0005a3a961238164b8b06cbb5f0428a9180b8a7 // TODO: Replace with actual IPFS Hash
        );
    }

    function testExecute() public {
        uint256 initialMainnetReserveFactorAusdcBalance = AUSDC.balanceOf(AAVE_MAINNET_RESERVE_FACTOR);
        uint256 initialCHAOSAusdcBalance = AUSDC.balanceOf(CHAOS_RECIPIENT);

        // Capturing next Stream IDs before proposal is executed
        uint256 nextMainnetReserveFactorStreamID = STREAMABLE_AAVE_MAINNET_RESERVE_FACTOR.getNextStreamId();
        uint256 nextEcosystemReserveStreamID = STREAMABLE_AAVE_ECOSYSTEM_RESERVE.getNextStreamId();

        // Pass vote and execute proposal
        GovHelpers.passVoteAndExecute(vm, proposalId);

        // Checking upfront aUSDC payment of $0.35 million
        assertLe(
            initialMainnetReserveFactorAusdcBalance - AUSDC_UPFRONT_AMOUNT,
            AUSDC.balanceOf(AAVE_MAINNET_RESERVE_FACTOR)
        );
        // Compensating for +1/-1 precision issues when rounding, mainly on aTokens
        assertApproxEqAbs(initialCHAOSAusdcBalance + AUSDC_UPFRONT_AMOUNT, AUSDC.balanceOf(CHAOS_RECIPIENT), 1);

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
        ) = STREAMABLE_AAVE_MAINNET_RESERVE_FACTOR.getStream(nextMainnetReserveFactorStreamID);

        assertEq(senderAusdc, AAVE_MAINNET_RESERVE_FACTOR);
        assertEq(recipientAusdc, CHAOS_RECIPIENT);
        assertEq(depositAusdc, AUSDC_STREAM_AMOUNT);
        assertEq(tokenAddressAusdc, address(AUSDC));
        assertEq(stopTimeAusdc - startTimeAusdc, STREAMS_DURATION);
        assertEq(remainingBalanceAusdc, AUSDC_STREAM_AMOUNT);

        // Checking if CHAOS can withdraw from streams
        vm.startPrank(CHAOS_RECIPIENT);
        // Checking CHAOS withdrawal every 30 days over 12 month period
        for (uint256 i = 0; i < 12; i++) {
            vm.warp(block.timestamp + 30 days);

            uint256 currentAusdcCHAOSBalance = AUSDC.balanceOf(CHAOS_RECIPIENT);
            uint256 currentAusdcCHAOSStreamBalance = STREAMABLE_AAVE_MAINNET_RESERVE_FACTOR.balanceOf(
                nextMainnetReserveFactorStreamID,
                CHAOS_RECIPIENT
            );

            STREAMABLE_AAVE_MAINNET_RESERVE_FACTOR.withdrawFromStream(
                nextMainnetReserveFactorStreamID,
                currentAusdcCHAOSStreamBalance
            );

            // Compensating for +1/-1 precision issues when rounding, mainly on aTokens
            // Checking aUSDC stream amount
            assertApproxEqAbs(
                AUSDC.balanceOf(CHAOS_RECIPIENT),
                currentAusdcCHAOSBalance + currentAusdcCHAOSStreamBalance,
                1
            );
            assertApproxEqAbs(
                AUSDC.balanceOf(CHAOS_RECIPIENT),
                currentAusdcCHAOSBalance + (ratePerSecondAusdc * 30 days),
                1
            );
        }
        vm.stopPrank();
    }
}
