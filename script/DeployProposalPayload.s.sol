// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@forge-std/console.sol";
import {Script} from "@forge-std/Script.sol";
import {ProposalPayload} from "../src/payloads/LTTailDecemberPayload.sol";

contract DeployProposalPayload is Script {
    function run() external {
        vm.startBroadcast();
        ProposalPayload proposalPayload = new ProposalPayload();
        console.log("Proposal Payload address", address(proposalPayload));
        vm.stopBroadcast();
    }
}
