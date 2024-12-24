// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface Turnstile {
    function register(address) external returns(uint256);
}