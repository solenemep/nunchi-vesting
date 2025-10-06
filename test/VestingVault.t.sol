// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {ERC20Mintable, VestingVault} from "../src/VestingVault.sol";

contract VestingVaultTest is Test {
    ERC20Mintable public token;
    VestingVault public vestingVault;

    address public user1 = address(0x1);

    function setUp() public {
        token = new ERC20Mintable();
        vestingVault = new VestingVault(token);

        token.transfer(address(vestingVault), 1000e18);
    }

    function test_claim_beforeCliff() public {
        vestingVault.addGrant(user1, 100e18, 10, 1000);

        uint256 balanceBefore = token.balanceOf(user1);

        vm.prank(user1);
        vestingVault.claim();

        uint256 balanceAfter = token.balanceOf(user1);

        assertEq(balanceAfter - balanceBefore, 0);
    }

    function test_claim_afterDuration() public {
        vestingVault.addGrant(user1, 100e18, 10, 1000);

        uint256 balanceBefore = token.balanceOf(user1);

        vm.warp(block.timestamp + 1000 + 1);

        vm.prank(user1);
        vestingVault.claim();

        uint256 balanceAfter = token.balanceOf(user1);

        assertEq(balanceAfter - balanceBefore, 100e18);
    }
}
