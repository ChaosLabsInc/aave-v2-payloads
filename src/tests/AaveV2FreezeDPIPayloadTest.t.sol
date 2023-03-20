// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

// testing libraries
import "@forge-std/Test.sol";

// contract dependencies
import {GovHelpers, TestWithExecutor} from "@aave-helpers/GovHelpers.sol";
import {AaveV2Ethereum, AaveV2EthereumAssets} from "@aave-address-book/AaveV2Ethereum.sol";
import {AaveV2FreezeDPIPayload} from "../payloads/AaveV2FreezeDPIPayload.sol";
import {ProtocolV2TestBase, ReserveConfig} from "@aave-helpers/ProtocolV2TestBase.sol";
import {AaveGovernanceV2} from "@aave-address-book/AaveAddressBook.sol";

contract AaveV2FreezeDPIPayloadTest is ProtocolV2TestBase, TestWithExecutor {
    AaveV2FreezeDPIPayload public proposalPayload;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 16870763);
        _selectPayloadExecutor(AaveGovernanceV2.SHORT_EXECUTOR);
    }

    function testDPIFreeze() public {
        ReserveConfig[] memory allConfigsBefore = _getReservesConfigs(AaveV2Ethereum.POOL);

        ReserveConfig memory DPIConfig = ProtocolV2TestBase._findReserveConfig(
            allConfigsBefore,
            AaveV2EthereumAssets.DPI_UNDERLYING
        );
        DPIConfig.isFrozen = true;

        // 1. deploy l2 payload
        proposalPayload = new AaveV2FreezeDPIPayload();

        // 2. execute l2 payload
        _executePayload(address(proposalPayload));

        ReserveConfig[] memory allConfigsAfter = ProtocolV2TestBase._getReservesConfigs(AaveV2Ethereum.POOL);

        ProtocolV2TestBase._validateReserveConfig(DPIConfig, allConfigsAfter);
    }
}
