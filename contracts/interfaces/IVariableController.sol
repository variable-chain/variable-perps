// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "./IVariableOrderSettler.sol";

interface IVariableController is IVariableOrderSettler {
    function updateVariableController(address newController) external;

    function updateVariableOrderSettler(address newSettler) external;

    function updateWithdrawCap(uint256 newCap) external;

    function withdrawRemainingBalance() external;

    function withdrawToken(address to) external;

    function registerPerpMarket(bytes32 perpMarketId) external;

    function deRegisterPerpMarket(bytes32 perpMarketId) external;

    function updateVariableMarketRegistry(address newMarketRegistry) external;

    function updateVariableVault(address newVariableVault) external;

    function matchOrders(
        OrderStruct[] memory buyOrders,
        OrderStruct[] memory sellOrders
    ) external;
}
