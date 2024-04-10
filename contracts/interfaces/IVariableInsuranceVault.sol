// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

interface IVariableInsuranceFund {
    function transferFund(address to, address token, uint256 amount) external;

    function checkTokenBalance(address token) external view returns (uint256);
}
