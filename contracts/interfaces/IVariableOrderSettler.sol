// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

/**
 * @title IVariableOrderSettler
 * @dev Interface for the VariableOrderSettler contract.
 */
interface IVariableOrderSettler {
    // Order struct
    struct OrderStruct {
        bool isLiquidation;
        bool isIncreaseMargin;
        bool maker;
        address trader;
        bytes32 referralCode;
        bytes32 positionId;
        bytes32 perpMarketId;
        uint256 entryPrice;
        uint256 positionSize;
        uint256 leverageRatio;
        int256 fundingFee;
    }

    /**
     * @dev Updates the Variable Market Registry address.
     * @param newMarketRegistry The new address of the Variable Market Registry contract.
     */
    function updateVariableMarketRegistry(address newMarketRegistry) external;

    function updateVariableController(address newController) external;

    function updateVariableVault(address newVariableVault) external;

    function updateVariableReferral(address variableReferral) external;

    /**
     * @dev Function to match buy and sell orders and settle them.
     * @param buyOrders Array of buy orders.
     * @param sellOrders Array of sell orders.
     */
    function matchOrders(
        OrderStruct[] memory buyOrders,
        OrderStruct[] memory sellOrders
    ) external;
}
