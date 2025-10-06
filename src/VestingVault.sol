// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract ERC20Mintable is ERC20 {
    constructor() ERC20("Mintable Token", "MTK") {}
}

interface IVestingVaultErrors {
    /// @dev Error when the token address is zero
    error WrongTokenAddress();

    /// @dev Error when granting to an address that already has a grant
    error AlreadyGranted();
}

contract VestingVault is IVestingVaultErrors, Ownable {
    struct Grant {
        uint128 total; // total tokens granted
        uint128 claimed; // tokens already claimed
        uint64 start; // vesting start timestamp
        uint64 cliff; // cliff seconds after start
        uint64 duration; // vesting duration in seconds
    }

    ERC20Mintable public immutable token;
    mapping(address => Grant) public grants;

    constructor(ERC20Mintable _token) Ownable(msg.sender) {
        require(address(_token) != address(0), WrongTokenAddress());
        token = _token;
    }

    function addGrant(address beneficiary, uint128 amount, uint64 cliffSeconds, uint64 durationSeconds)
        external
        onlyOwner
    {
        require(grants[beneficiary].total == 0, AlreadyGranted());
        grants[beneficiary] = Grant({
            total: amount,
            claimed: 0,
            start: uint64(block.timestamp),
            cliff: cliffSeconds,
            duration: durationSeconds
        });
    }

    function claim() external {
        Grant storage grant = grants[msg.sender];

        uint256 vested = vestedOf(msg.sender);
        grant.claimed += uint128(vested);

        token.transfer(msg.sender, vested);
    }

    function vestedOf(address account) public view returns (uint256 vestedAmount) {
        Grant storage grant = grants[account];
        if (block.timestamp < grant.start + grant.cliff) {
            return 0;
        } else if (block.timestamp >= grant.start + grant.duration) {
            return grant.total - grant.claimed;
        } else {
            return ((block.timestamp - grant.start) * grant.total / grant.duration) - grant.claimed;
        }
    }
}
