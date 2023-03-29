from abc import ABC, abstractmethod
import os
from payload_utils_v3 import *
from git import Repo
from datetime import datetime
import calendar


class CreateFile(ABC):
    def __init__(self, pr_name: str, paylaod_name: str,  info: str, snapshot: str, discussion: str, config):
        self.chain = config[CHAIN]
        self.chain_name = CHAIN_CONFIG[self.chain]["name"]
        self.address_book = CHAIN_CONFIG[self.chain]["address_book"]
        self.paylaod_name = paylaod_name
        self.info = info
        self.pr_name = pr_name
        self.snapshot = snapshot
        self.discussion = discussion
        self.config = config

    def _create_file(self, is_test):
        self.set_up()
        data = self.get_data(is_test)
        code = self.get_code()
        tamplate = self.get_tamplate(data, code)
        path = self.get_path()
        file_name = self.get_file_name()
        if not os.path.exists(path):
            os.makedirs(path)
        with open(f'{path}/{file_name}', 'w') as f:
            print("Writing: ", tamplate)
            f.write(tamplate)

    def set_up(self):
        now = datetime.now()  # current date and time
        month = int(now.strftime("%m"))
        day = now.strftime("%d")
        month_short_name = calendar.month_abbr[month]
        current_date = month_short_name + day
        self.current_name = self.paylaod_name + current_date

    def get_data(self, is_test):
        data_set_up = ""
        for asset_change in self.config.get(Action.PARAMS, []):
            data_set_up += self.get_all_params_data(asset_change[DATA],
                                                    asset_change[ASSET], is_test) + "\n"
        for asset_change in self.config.get(Action.RISK_PARAMS, []):
            data_set_up += self.get_all_params_data(asset_change[DATA],
                                                    asset_change[ASSET], is_test) + "\n"

        return data_set_up

    def get_all_params_data(self, asset_change_data, asset_name, is_test):
        data = ""
        for type in asset_change_data:
            data += self.get_param_data(type,
                                        asset_change_data, asset_name, is_test)
        return data

    def get_param_data(self, type, asset_change_data, asset_name, is_test=False):
        comment = ""
        if type in [Field.LIQ_THRESHOLD, Field.LTV, Field.LIQ_BONUS]:
            percent = int(asset_change_data[type][VALUE]) / 100
            minus = 0
            if type == Field.LIQ_BONUS:
                minus = 100
            comment += f""" // {percent - minus}%"""
            if not asset_change_data[type].get(IS_CHANGED, True):

                if is_test:
                    return ""
                comment += ' Not Changed'

        if type in asset_change_data:
            value = asset_change_data[type][VALUE]
            if isinstance(value, (bool)):
                instance_type = BOOL
            elif isinstance(value, (int)):
                instance_type = UINT
            return f"""    {instance_type} {asset_name }_{type.name} = {str(value).lower()};""" + comment + "\n"
        return ""

    def get_code(self):
        code_change = ""
        for asset_change in self.config.get(Action.PARAMS, []):
            code_change += self.get_code_per_change(
                asset_change_data=asset_change[DATA], asset_name=asset_change[ASSET])
        for asset_change in self.config.get(Action.RISK_PARAMS, []):
            code_change += self.get_code_per_risk_change(
                asset_change_data=asset_change[DATA], asset_name=asset_change[ASSET])
        return code_change

    @abstractmethod
    def create_file(self):
        pass

    @abstractmethod
    def get_tamplate(self):
        pass

    @abstractmethod
    def get_path(self):
        pass

    @abstractmethod
    def get_code_per_change(self):
        pass

    @abstractmethod
    def get_code_per_risk_change(self, asset_change_data, asset_name):
        pass

    @abstractmethod
    def get_file_name(self):
        pass


class CreateContractFile(CreateFile):

    def create_file(self):
        return self._create_file(False)

    def get_tamplate(self, data, code):
        return f"""// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import {{IProposalGenericExecutor}} from 'aave-helpers/interfaces/IProposalGenericExecutor.sol';
import {{{self.address_book}, {self.address_book}Assets}} from 'aave-address-book/{self.address_book}.sol';

/**
* @dev {self.info}
{"* - Snapshot: "+ self.snapshot if self.snapshot else ""}
{"* - Discussion: "+ self.discussion if self.discussion else ""}
*/
contract {self.current_name} is IProposalGenericExecutor {{
{data}
    function execute() external {{
{code}
    }}
}}
"""

    def get_path(self):
        return f'src/contracts/{self.chain_name}/'

    def get_file_name(self):
        return f'{self.current_name}.sol'

    def get_code_per_change(self, asset_change_data, asset_name):
        data_change = ""
        for type in asset_change_data:
            data_change += self.set_param_change(type,
                                                 asset_change_data, asset_name) + "\n"
        return data_change

    def set_param_change(self, cap_type, asset_change_data, asset_name):
        if cap_type in asset_change_data:
            return f"""        {self.address_book}.POOL_CONFIGURATOR.{FIELD_TO_CHANGE_NAME_MAP[cap_type]}({self.address_book}Assets.{asset_name}, {asset_name}_{cap_type.name});"""
        return ""

    def get_code_per_risk_change(self, asset_change_data, asset_name):
        return f"""        {self.address_book}.POOL_CONFIGURATOR.configureReserveAsCollateral(
            {self.address_book}Assets.{asset_name},
            {asset_name}_{Field.LTV.name},
            {asset_name}_{Field.LIQ_THRESHOLD.name},
            {asset_name}_{Field.LIQ_BONUS.name}
        ); \n"""


class CreateContractTestFile(CreateFile):

    def create_file(self):
        self._create_file(True)

    def get_tamplate(self, data, code):
        pool = f"{self.address_book}.POOL"
        return f"""// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import 'forge-std/Test.sol';

import {{{self.address_book}, {self.address_book}Assets}} from 'aave-address-book/{self.address_book}.sol';
import {{{self.current_name}}} from '../../../{self.get_contract_path()}{self.current_name}.sol';
import {{TestWithExecutor}} from 'aave-helpers/GovHelpers.sol';
import {{AaveGovernanceV2}} from 'aave-address-book/AaveGovernanceV2.sol';
import {{ProtocolV3TestBase, ReserveConfig}} from 'aave-helpers/ProtocolV3TestBase.sol';

contract {self.current_name}Test is ProtocolV3TestBase, TestWithExecutor {{
{data}
    function setUp() public {{
        vm.createSelectFork(vm.rpcUrl('{self.chain_name}'), {
                            self.config[BLOCK_NUMBER_TO_TEST]});
        _selectPayloadExecutor({CHAIN_CONFIG[self.chain]["executor"]});

    }}

    function testPayload() public {{
        {self.current_name} proposalPayload = new {self.current_name}();

        ReserveConfig[] memory allConfigsBefore = _getReservesConfigs({pool});

        // execute payload
        _executePayload(address(proposalPayload));

        //Verify payload:
        ReserveConfig[] memory allConfigsAfter = _getReservesConfigs({pool});
{code}
    }}
}}
"""

    def get_contract_path(self):
        return f'src/contracts/{self.chain_name}/'

    def get_path(self):
        return f'src/test/{self.chain_name}/'

    def get_file_name(self):
        return f'{self.current_name}Test.t.sol'

    def get_code_per_change(self, asset_change_data, asset_name):
        config_name = f"{asset_name}_CONFIG"
        asset_check = f"""

        ReserveConfig memory {config_name} = ProtocolV3TestBase._findReserveConfig(
        allConfigsBefore,
        {self.address_book}Assets.{asset_name}
        );
    """
        for field in asset_change_data.keys():
            if asset_change_data[field].get(IS_CHANGED, True):
                asset_check += f"""
        {config_name}.{FIELD_TO_ASSERT_NAME_MAP[field]} = {asset_name}_{field.name};""" + "\n"

        asset_check += f"""
        ProtocolV3TestBase._validateReserveConfig({config_name}, allConfigsAfter);""" + "\n"
        return asset_check

    def get_code_per_risk_change(self, asset_change_data, asset_name):
        return self.get_code_per_change(asset_change_data, asset_name)


def set_up_repo(proposal_name):
    repo_path = os.getenv(GIT_REPO_PATH)
    repo = Repo(repo_path)
    current = repo.create_head(proposal_name)
    current.checkout()
    # master = repo.heads.master
    # repo.git.pull('origin', master)
    build = "make build"
    print("run command: ", build)
    os.system(build)
    return repo, current


def commit_and_create_pr(repo, current, pr_name):
    if repo.index.diff(None) or repo.untracked_files:

        repo.git.add(A=True)
        print('git add')
        repo.git.commit(m=pr_name)
        print('git commit')

        repo.git.push('--set-upstream', 'origin', current)
        print('git push')
    else:
        print('no changes')


def create_proposal_pr(pr_name, proposal_name, payload_info, snapshot_link, discussion_link, config, to_push=False):
    repo, current = set_up_repo(proposal_name)
    create = CreateContractFile(
        pr_name,  proposal_name, payload_info, snapshot_link, discussion_link, config)
    createTest = CreateContractTestFile(
        pr_name, proposal_name, payload_info, snapshot_link, discussion_link, config)

    create.create_file()
    createTest.create_file()

    run_test = f"forge test -vvv --match-contract {create.current_name}Test"
    print("run command: ", run_test)
    os.system(run_test)

    if to_push:
        commit_and_create_pr(repo, current, pr_name)
