// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

// testing libraries
import "@forge-std/Test.sol";

// contract dependencies
import {GovHelpers, TestWithExecutor} from "@aave-helpers/GovHelpers.sol";
import {AaveV2Ethereum, AaveV2EthereumAssets} from "@aave-address-book/AaveV2Ethereum.sol";
import {ProposalPayload} from "../payloads/MKRPayload-Feb26.sol";
import {ProtocolV2TestBase, ReserveConfig} from '@aave-helpers/ProtocolV2TestBase.sol';
import {AaveGovernanceV2} from '@aave-address-book/AaveAddressBook.sol';

contract ProposalMKRPayloadTest is ProtocolV2TestBase, TestWithExecutor {
    uint256 public constant MKR_LTV = 5900; ///  59%
    uint256 public constant MKR_LIQUIDATION_THRESHOLD = 6400; // 64%

    uint256 public proposalId;
    ProposalPayload public proposalPayload;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 16182710);
        _selectPayloadExecutor(AaveGovernanceV2.SHORT_EXECUTOR);
        proposalPayload = new ProposalPayload();
    }

    function testProposal() public {
        ReserveConfig[] memory allConfigsBefore = _getReservesConfigs(AaveV2Ethereum.POOL);
        ReserveConfig memory config = _findReserveConfig(allConfigsBefore ,AaveV2EthereumAssets.MKR_UNDERLYING);

        _executePayload(address(proposalPayload));

        ReserveConfig[] memory allConfigsAfter = _getReservesConfigs(AaveV2Ethereum.POOL);

        _validateCountOfListings(0, allConfigsBefore, allConfigsAfter);

        config.ltv = MKR_LTV;
        config.liquidationThreshold = MKR_LIQUIDATION_THRESHOLD;
        _validateReserveConfig(config, allConfigsAfter);
    }
}
