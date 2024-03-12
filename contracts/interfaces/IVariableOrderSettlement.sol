// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

/**
 * @title IVariableOrderSettlement
 * @dev Interface for the VariableOrderSettlement contract.
 */
interface IVariableOrderSettlement {
    // Order struct
    struct OrderStruct {
        bool isOpeningPosition;
        bool isLong;
        address baseToken;
        address quoteToken;
        address buyer;
        address seller;
        uint256 entryPrice;
        uint256 positionSize;
        uint256 leverageRatio;
        int256 fundingFee;
        OrderType orderType;
        bytes32 referralCode;
        bytes32 positionId;
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
