// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

interface IVariableLedger {
    function traderPositionMap(
        address
    ) external view returns (int256, int256, uint256);

    function traderCPF(address) external view returns (int256);

    function openPositionInVault(
        uint256 amount,
        address trader
    ) external;

    function closePositionInVault(
        uint256 amount,
        int256 fundingFee,
        address trader
    ) external;

    function liquidate(
        address trader,
        address to
    ) external returns (uint256, uint256, uint256);

    function updateCPF() external returns (int256 newLatestCPF);

    function getPosition(
        address trader
    ) external view returns (int256, int256, uint256);

    function getWithdrawable(
        address trader
    ) external view returns (uint256 withdrawable);

    function getNewLatestCPF() external view returns (int256);

    function canLiquidate(address trader) external view returns (bool);

    function calFundingFee(address trader) external view returns (int256);

    function calDebtRatio(address trader) external view returns (uint256);

    function calUnrealizedPnl(address trader) external view returns (int256);

    function netPosition() external view returns (int256);

    function totalPosition() external view returns (uint256);
}
