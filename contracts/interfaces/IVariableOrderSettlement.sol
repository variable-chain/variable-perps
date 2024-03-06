// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IVariableOrderSettlement
 * @dev Interface for the VariableOrderSettlement contract.
 */
interface IVariableOrderSettlement {
    // Order struct
    struct OrderStruct {
        address baseToken;
        address quoteToken;
        address buyer;
        address seller;
        uint256 entryPrice;
        uint256 positionSize;
        uint256 leverageRatio;
        uint256 fundingFee;
        SideType side;
        OrderType orderType;
        bytes32 referralCode;
    }

    // Enum definitions
    enum SideType {
        LONG,
        SHORT
    }

    enum OrderType {
        LIMIT_ORDER,
        MARKET_ORDER,
        STOP_MARKET,
        STOP_LIMIT,
        TRAILING_STOP,
        TAKE_PROFIT,
        TAKE_PROFIT_LIMIT
    }

    /**
     * @dev Updates the Variable Market Registry address.
     * @param newMarketRegistry The new address of the Variable Market Registry contract.
     */
    function updateVariableMarketRegistry(address newMarketRegistry) external;

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
