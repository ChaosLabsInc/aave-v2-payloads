// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

// testing libraries
import "@forge-std/Test.sol";

// contract dependencies
import {GovHelpers} from "@aave-helpers/GovHelpers.sol";
import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";
import {AaveAddressBookV2} from "@aave-address-book/AaveAddressBook.sol";
import {ProposalPayload} from "../payloads/PaymentProposalPayload.sol";
import {DeployMainnetProposal} from "../../script/DeployMainnetProposal.s.sol";
import {AaveV2Helpers, ReserveConfig, ReserveTokens, InterestStrategyValues} from "./utils/AaveV2Helpers.sol";

contract ProposalPayloadTest is Test {
    address public constant AAVE_WHALE = 0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8;
    string public constant DAISymbol = "DAI";

    uint256 public proposalId;

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

    function testDAILTProposal() public {
        ReserveConfig[] memory allConfigsBefore = AaveV2Helpers._getReservesConfigs(
            false,
            AaveAddressBookV2.AaveV2Ethereum
        );

        GovHelpers.passVoteAndExecute(vm, proposalId);

        ReserveConfig[] memory allConfigsAfter = AaveV2Helpers._getReservesConfigs(
            false,
            AaveAddressBookV2.AaveV2Ethereum
        );

        AaveV2Helpers._validateCountOfListings(0, allConfigsBefore, allConfigsAfter);

        ReserveConfig memory config = AaveV2Helpers._findReserveConfig(allConfigsBefore, DAISymbol, false);
        // WETHConfig.borrowCap = WETHe_CAP;
        AaveV2Helpers._validateReserveConfig(config, allConfigsAfter);

        // ReserveConfig memory expectedLusdConfig = ReserveConfig({
        //     symbol: "LUSD",
        //     underlying: LUSD,
        //     aToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
        //     variableDebtToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
        //     stableDebtToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
        //     decimals: 18,
        //     ltv: 0,
        //     liquidationThreshold: 0,
        //     liquidationBonus: 0,
        //     reserveFactor: 1000,
        //     usageAsCollateralEnabled: false,
        //     borrowingEnabled: true,
        //     interestRateStrategy: 0x545Ae1908B6F12e91E03B1DEC4F2e06D0570fE1b,
        //     stableBorrowRateEnabled: true,
        //     isActive: true,
        //     isFrozen: false
        // });

        // AaveV2Helpers._validateReserveConfig(expectedLusdConfig, allConfigsAfter);
    }
}
