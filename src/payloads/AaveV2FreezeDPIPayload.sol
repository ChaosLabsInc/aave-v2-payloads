// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV2Ethereum, AaveV2EthereumAssets} from "@aave-address-book/AaveV2Ethereum.sol";
import {ILendingPoolConfigurator} from "@aave-address-book/AaveV2.sol";
import {IProposalGenericExecutor} from "@aave-helpers/interfaces/IProposalGenericExecutor.sol";

/**
 * @dev Aave governance payload to freeze the DPI asset on Aave v2
 * - Snapshot: Direct to AIP
 * - Dicussion: https://governance.aave.com/t/arfc-add-dpi-to-v3-ethereum-and-freeze-on-v2-ethereum/12354
 */
contract AaveV2FreezeDPIPayload is IProposalGenericExecutor {
    function execute() external {
        AaveV2Ethereum.POOL_CONFIGURATOR.freezeReserve(AaveV2EthereumAssets.DPI_UNDERLYING);
    }
}
