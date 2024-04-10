// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

interface IVariableFeeVault {
    function transferFee(address to, address token, uint256 amount) external;

    function bulkTransfer(
        address token,
        address[] memory recipients,
        uint256[] memory amounts
    ) external;

    function checkTokenBalance(address token) external view returns (uint256);
}
