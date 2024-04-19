// SPDX-License-Identifier: MIT
// aaly

pragma solidity ^0.8.19;

interface ICamelotPair {
    function token0() external view returns (address);

    function token1() external view returns (address);
}
