// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

interface IVariableMarketRegistry {
    function activePerpMarkets(bytes32) external view returns (bool);

    function updateVariableVault(address newVault) external;

    function updateVariableController(address newController) external;

    function registerPerpMarket(bytes32 perpMarketId) external;

    function deRegisterPerpMarket(bytes32 perpMarketId) external;
}
