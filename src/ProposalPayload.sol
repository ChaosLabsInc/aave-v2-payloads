// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {IAaveEcosystemReserveController} from "./external/aave/IAaveEcosystemReserveController.sol";
import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";

/**
 * @title Chaos <> AAVE Proposal
 * @authorChaos
 * @notice Payload to execute the Chaos <> AAVE Proposal
 * Governance Forum Post:
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0xad105e87d4df487bbe1daec2cd94ca49d1ea595901f5773c1804107539288b59
 */
contract ProposalPayload {
    /********************************
     *   CONSTANTS AND IMMUTABLES   *
     ********************************/

    // Reserve that holds AAVE tokens
    address public constant AAVE_ECOSYSTEM_RESERVE = 0x25F2226B597E8F9514B3F68F00f494cF4f286491;
    // TODO: Chaos Recipient address
    address public constant CHAOS_RECIPIENT = 0xb428C6812E53F843185986472bb7c1E25632e0f7;
    address public constant AUSDC_TOKEN = 0xBcca60bB61934080951369a648Fb03DF4F96263C;

    // ~500,000 aUSDC = $0.5 million
    // Small additional amount to handle remainder condition during streaming
    // https://github.com/bgd-labs/aave-ecosystem-reserve-v2/blob/release/final-proposal/src/AaveEcosystemReserveV2.sol#L229-L233
    uint256 public constant AUSDC_STREAM_AMOUNT = 500000e6;
    /*****************
     *   FUNCTIONS   *
     *****************/

    /// @notice The AAVE governance executor calls this function to implement the proposal.
    function execute() external {
        // Stream of $0.5 million in aUSDC over 12 months
        IAaveEcosystemReserveController(AaveV2Ethereum.COLLECTOR_CONTROLLER).createStream(
            AaveV2Ethereum.COLLECTOR,
            CHAOS_RECIPIENT,
            AUSDC_STREAM_AMOUNT,
            AUSDC_TOKEN,
            block.timestamp + (1 years / 2),  // in 6 months)
            block.timestamp + 1 years,  // 6 months duration
        );
    }
}
