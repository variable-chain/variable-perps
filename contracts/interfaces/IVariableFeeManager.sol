// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

interface IVariableFeeManager {
    function updateFeeController(address newController) external;
    function setCompositFee(uint256 fee) external;
    function setLiquidationFee(uint256 fee) external;
    function calculateFees(
        bool isLiquidation,
        uint256 positionSize
    ) external view returns (uint256 totalFees);
}
