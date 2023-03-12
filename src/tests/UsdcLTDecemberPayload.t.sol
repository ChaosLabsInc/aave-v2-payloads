// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

// testing libraries
import "@forge-std/Test.sol";

// contract dependencies
import {GovHelpers, TestWithExecutor} from "@aave-helpers/GovHelpers.sol";
import {AaveV2Ethereum, AaveV2EthereumAssets} from "@aave-address-book/AaveV2Ethereum.sol";
import {ProposalPayload} from "../payloads/UsdcLTDecemberPayload.sol";
import {ProtocolV2TestBase, ReserveConfig} from '@aave-helpers/ProtocolV2TestBase.sol';
import {AaveGovernanceV2} from '@aave-address-book/AaveAddressBook.sol';

contract ProposalUsdcLTPayloadTest is ProtocolV2TestBase, TestWithExecutor {
    uint256 public constant LTV = 8000; /// 87 -> 80
    uint256 public constant LIQUIDATION_THRESHOLD = 8750; // 89 -> 87.5

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
        ReserveConfig memory config = _findReserveConfig(allConfigsBefore, AaveV2EthereumAssets.USDC_UNDERLYING);

        _executePayload(address(proposalPayload));

        ReserveConfig[] memory allConfigsAfter = _getReservesConfigs(
            AaveV2Ethereum.POOL
        );

        _validateCountOfListings(0, allConfigsBefore, allConfigsAfter);

        config.ltv = LTV;
        config.liquidationThreshold = LIQUIDATION_THRESHOLD;
        _validateReserveConfig(config, allConfigsAfter);
    }
}
