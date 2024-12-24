// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct VestSchedule{
    uint256 releaseDate;
    uint256 releaseAmount;
    bool hasBeenClaimed;
}