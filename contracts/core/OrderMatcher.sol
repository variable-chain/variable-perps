// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IVariableLedger.sol";

contract VariableOrderMatcher is Ownable, ReentrancyGuard {
    IVariableLedger public variableLedger;

    // Order struct
    struct OrderStruct {
        address baseToken;
        address quoteToken;
        address buyer;
        address seller;
        uint256 entryPrice;
        uint256 positionSize;
        uint256 leverageRatio;
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

    constructor(
        address _initialOwner,
        address _variableLedger
    ) Ownable(_initialOwner) {
        variableLedger = IVariableLedger(_variableLedger);
    }

    function updatePerpLedger(address newLedger) external onlyOwner {
        require(
            newLedger != address(0),
            "VariableOrderMatcher: Invalid address"
        );
        variableLedger = IVariableLedger(newLedger);
    }

    function matchOrders(
        OrderStruct memory buyOrder,
        OrderStruct memory sellOrder
    ) external onlyOwner {
        require(
            buyOrder.side == SideType.LONG && sellOrder.side == SideType.SHORT,
            "VariableOrderMatcher: Invalid order sides"
        );

        // Check if the tokens and prices match
        require(
            buyOrder.baseToken == sellOrder.baseToken &&
                buyOrder.quoteToken == sellOrder.quoteToken,
            "VariableOrderMatcher: Tokens do not match"
        );
        require(
            buyOrder.entryPrice >= sellOrder.entryPrice,
            "VariableOrderMatcher: Buy entry price should be greater than or equal to sell entry price"
        );

        // Calculate the matched position size based on the smaller of the two orders
        uint256 matchedPositionSize = (buyOrder.positionSize <
            sellOrder.positionSize)
            ? buyOrder.positionSize
            : sellOrder.positionSize;

        // Update perpMarginBalance and balanceInfo for the buyer and seller
        variableLedger.openPositionInVault(
            matchedPositionSize,
            buyOrder.buyer,
            address(this)
        );
        variableLedger.openPositionInVault(
            matchedPositionSize,
            sellOrder.seller,
            address(this)
        );

        if (buyOrder.orderType == OrderType.MARKET_ORDER) {} else if (
            buyOrder.orderType == OrderType.LIMIT_ORDER
        ) {} else if (buyOrder.orderType == OrderType.STOP_MARKET) {} else if (
            buyOrder.orderType == OrderType.MARKET_ORDER
        ) {} else if (buyOrder.orderType == OrderType.STOP_LIMIT) {} else if (
            buyOrder.orderType == OrderType.TAKE_PROFIT
        ) {} else if (
            buyOrder.orderType == OrderType.TAKE_PROFIT_LIMIT
        ) {} else if (buyOrder.orderType == OrderType.TRAILING_STOP) {}
    }
}
