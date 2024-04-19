// SPDX-License-Identifier: MIT
// aaly

pragma solidity ^0.8.19;

interface ICamelotRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;
}
