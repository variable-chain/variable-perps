// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IVariableLedger.sol";
import "../interfaces/IVariableMarketRegistry.sol";
import "../interfaces/IVariableOrderSettlement.sol";

/**
 * @title VariableOrderSettlement
 * @dev Smart contract for settling matched orders between buyers and sellers in a decentralized trading system.
 */
contract VariableOrderSettlement is
    Ownable,
    ReentrancyGuard,
    IVariableOrderSettlement
{
    IVariableMarketRegistry public variableMarketRegistry;

    /**
     * @dev Constructor function to initialize the contract with the owner and initial Variable Market Registry address.
     * @param _initialOwner The initial owner of the contract.
     * @param _variableMarketRegistry The address of the Variable Market Registry contract.
     */
    constructor(
        address _initialOwner,
        address _variableMarketRegistry
    ) Ownable(_initialOwner) {
        require(
            _variableMarketRegistry != address(0),
            "VariableVault: Invalid address"
        );
        variableMarketRegistry = IVariableMarketRegistry(
            _variableMarketRegistry
        );
    }

    /**
     * @dev Updates the Variable Market Registry address.
     * @param newMarketRegistry The new address of the Variable Market Registry contract.
     */
    function updateVariableMarketRegistry(
        address newMarketRegistry
    ) external onlyOwner {
        require(
            newMarketRegistry != address(0),
            "VariableVault: Invalid address"
        );
        variableMarketRegistry = IVariableMarketRegistry(newMarketRegistry);
    }

    /**
     * @dev Function to match buy and sell orders and settle them.
     * @param buyOrders Array of buy orders.
     * @param sellOrders Array of sell orders.
     */
    function matchOrders(
        OrderStruct[] memory buyOrders,
        OrderStruct[] memory sellOrders
    ) external onlyOwner {
        uint256 buyOrderLength = buyOrders.length;
        uint256 sellOrderLength = sellOrders.length;

        if (buyOrderLength < sellOrderLength) {
            // Iterate through buy orders
            for (uint256 i = 0; i < buyOrderLength; i++) {
                OrderStruct memory buyOrder = buyOrders[i];

                // Find suitable sell orders for the current buy order
                for (uint256 j = 0; j < sellOrderLength; j++) {
                    OrderStruct memory sellOrder = sellOrders[j];

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

                    // Get the Perpetual Market contract address
                    address perpMarket = variableMarketRegistry.getPerpLedger(
                        buyOrder.baseToken,
                        buyOrder.quoteToken
                    );

                    // Update perpMarginBalance and balanceInfo for the buyer and seller
                    if (buyOrder.isOpeningPosition) {
                        IVariableLedger(perpMarket).openPositionInVault(
                            matchedPositionSize,
                            buyOrder.leverageRatio,
                            buyOrder.buyer,
                            buyOrder.positionId,
                            buyOrder.isLong
                        );
                    } else {
                        IVariableLedger(perpMarket).closePositionInVault(
                            matchedPositionSize,
                            buyOrder.leverageRatio,
                            buyOrder.fundingFee,
                            buyOrder.buyer,
                            buyOrder.positionId,
                            buyOrder.isLong
                        );
                    }

                    if (sellOrder.isOpeningPosition) {
                        IVariableLedger(perpMarket).openPositionInVault(
                            matchedPositionSize,
                            sellOrder.leverageRatio,
                            sellOrder.seller,
                            sellOrder.positionId,
                            sellOrder.isLong
                        );
                    } else {
                        IVariableLedger(perpMarket).closePositionInVault(
                            matchedPositionSize,
                            sellOrder.leverageRatio,
                            sellOrder.fundingFee,
                            sellOrder.seller,
                            sellOrder.positionId,
                            sellOrder.isLong
                        );
                    }

                    // Adjust position size of the buy order
                    buyOrders[i].positionSize -= matchedPositionSize;
                }
            }
        } else {
            // Iterate through sell orders
            for (uint256 i = 0; i < sellOrderLength; i++) {
                OrderStruct memory sellOrder = sellOrders[i];

                // Find suitable sell orders for the current buy order
                for (uint256 j = 0; j < buyOrderLength; j++) {
                    OrderStruct memory buyOrder = buyOrders[j];

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

                    // Get the Perpetual Market contract address
                    address perpMarket = variableMarketRegistry.getPerpLedger(
                        buyOrder.baseToken,
                        buyOrder.quoteToken
                    );

                    // Update perpMarginBalance and balanceInfo for the buyer and seller
                    if (buyOrder.isOpeningPosition) {
                        IVariableLedger(perpMarket).openPositionInVault(
                            matchedPositionSize,
                            buyOrder.leverageRatio,
                            buyOrder.buyer,
                            buyOrder.positionId,
                            buyOrder.isLong
                        );
                    } else {
                        IVariableLedger(perpMarket).closePositionInVault(
                            matchedPositionSize,
                            buyOrder.leverageRatio,
                            buyOrder.fundingFee,
                            buyOrder.buyer,
                            buyOrder.positionId,
                            buyOrder.isLong
                        );
                    }

                    if (sellOrder.isOpeningPosition) {
                        IVariableLedger(perpMarket).openPositionInVault(
                            matchedPositionSize,
                            sellOrder.leverageRatio,
                            sellOrder.seller,
                            sellOrder.positionId,
                            sellOrder.isLong
                        );
                    } else {
                        IVariableLedger(perpMarket).closePositionInVault(
                            matchedPositionSize,
                            sellOrder.leverageRatio,
                            sellOrder.fundingFee,
                            sellOrder.seller,
                            sellOrder.positionId,
                            sellOrder.isLong
                        );
                    }

                    // Adjust position size of the sell order
                    sellOrders[i].positionSize -= matchedPositionSize;
                }
            }
        }
    }
}
