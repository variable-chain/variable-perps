// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

interface ITradingMargin {
    struct Position {
        int256 quoteSize; //quote amount of position
        int256 baseSize; //margin + fundingFee + unrealizedPnl + deltaBaseWhenClosePosition
        uint256 tradeSize; //if quoteSize>0 unrealizedPnl = baseValueOfQuoteSize - tradeSize; if quoteSize<0 unrealizedPnl = tradeSize - baseValueOfQuoteSize;
    }

    event AddMargin(
        address indexed trader,
        uint256 depositAmount,
        Position position
    );
    event RemoveMargin(
        address indexed trader,
        address indexed to,
        uint256 withdrawAmount,
        int256 fundingFee,
        uint256 withdrawAmountFromMargin,
        Position position
    );
    event OpenPosition(
        address indexed trader,
        uint8 side,
        uint256 baseAmount,
        uint256 quoteAmount,
        int256 fundingFee,
        Position position
    );
    event ClosePosition(
        address indexed trader,
        uint256 quoteAmount,
        uint256 baseAmount,
        int256 fundingFee,
        Position position
    );
    event Liquidate(
        address indexed liquidator,
        address indexed trader,
        address indexed to,
        uint256 quoteAmount,
        uint256 baseAmount,
        uint256 bonus,
        int256 fundingFee,
        Position position
    );

    /**
     * @notice Initializes the margin contract with essential parameters.
     * @param baseToken_ Address of the base token.
     * @param quoteToken_ Address of the quote token.
     */
    function initialize(address baseToken_, address quoteToken_) external;

    /**
     * @notice Adds margin to a trader's position.
     * @param trader Address of the trader.
     * @param depositAmount Amount of base token to be deposited as margin.
     */
    function addTradeMargin(address trader, uint256 depositAmount) external;

    /**
     * @notice Removes margin from a trader's position.
     * @param trader Address of the trader.
     * @param to Address where the withdrawn funds will be sent.
     * @param withdrawAmount Amount of base token to be withdrawn.
     */
    function removeTradeMargin(
        address trader,
        address to,
        uint256 withdrawAmount
    ) external;

    /**
     * @notice Opens a new trading position.
     * @param trader Address of the trader.
     * @param side Side of the position (0 for long, 1 for short).
     * @param quoteAmount Amount of quote token to be used for the position.
     * @return baseAmount Amount of base token used in the position.
     */
    function openTradePosition(
        address trader,
        uint8 side,
        uint256 quoteAmount
    ) external returns (uint256 baseAmount);

    /**
     * @notice Closes a trading position.
     * @param trader Address of the trader.
     * @param quoteAmount Amount of quote token to be received from closing the position.
     * @return baseAmount Amount of base token returned from closing the position.
     */
    function closeTradePosition(
        address trader,
        uint256 quoteAmount
    ) external returns (uint256 baseAmount);

    /**
     * @notice Liquidates a trader's position.
     * @param trader Address of the trader to be liquidated.
     */
    function liquidatePosition(
        address trader,
        address to
    ) external returns (uint256 quoteAmount, uint256 baseAmount, uint256 bonus);

    /**
     * @notice Updates the position of a trader after a trade occurs on the AMM.
     * @param trader Address of the trader.
     * @param tradeSize Size of the trade.
     * @param quoteAmount Amount of quote token traded.
     */
    function updateTraderPosition(
        address trader,
        int256 tradeSize,
        uint256 quoteAmount
    ) external;

    /// @notice get factory address
    function factory() external view returns (address);

    /// @notice get config address
    function config() external view returns (address);

    /// @notice get base token address
    function baseToken() external view returns (address);

    /// @notice get quote token address
    function quoteToken() external view returns (address);

    /// @notice get all users' net position of quote
    function netPosition() external view returns (int256 netQuotePosition);

    /// @notice get all users' net position of quote
    function totalPosition() external view returns (uint256 totalQuotePosition);

    /// @notice get trader's position
    function getPosition(
        address trader
    )
        external
        view
        returns (int256 baseSize, int256 quoteSize, uint256 tradeSize);

    /// @notice get withdrawable margin of trader
    function getWithdrawable(
        address trader
    ) external view returns (uint256 amount);

    /// @notice check if can liquidate this trader's position
    function canLiquidate(address trader) external view returns (bool);

    /// @notice calculate the latest funding fee with current position
    function calFundingFee(
        address trader
    ) external view returns (int256 fundingFee);

    /// @notice calculate the latest debt ratio with Pnl and funding fee
    function calDebtRatio(
        address trader
    ) external view returns (uint256 debtRatio);

    function calUnrealizedPnl(address trader) external view returns (int256);
}
