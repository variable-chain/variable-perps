// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../interfaces/IPriceOracle.sol";

contract VariableLedger is Ownable, ReentrancyGuard {
    address public baseToken;
    address public quoteToken;
    address public priceOracle;

    struct Position {
        int256 quoteSize; //quote amount of position
        int256 baseSize; //margin + fundingFee + unrealizedPnl + deltaBaseWhenClosePosition
        uint256 tradeSize; //if quoteSize>0 unrealizedPnl = baseValueOfQuoteSize - tradeSize; if quoteSize<0 unrealizedPnl = tradeSize - baseValueOfQuoteSize;
    }

    mapping(address => Position) public traderPositionMap;
    mapping(address => int256) public traderCPF;
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(
        address indexed user,
        address indexed receiver,
        uint256 amount
    );
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

    constructor(
        address _initialOwner,
        address _baseToken,
        address _quoteToken
    ) Ownable(_initialOwner) {
        baseToken = _baseToken;
        quoteToken = _quoteToken;
    }

    function addMargin(
        address trader,
        uint256 depositAmount
    ) external nonReentrant {
        Position memory traderPosition = traderPositionMap[trader];

        //traderPosition.baseSize = traderPosition.baseSize.addU(depositAmount);
        traderPositionMap[trader] = traderPosition;

        emit AddMargin(trader, depositAmount, traderPosition);
    }

    //remove baseToken from trader's fundingFee+unrealizedPnl+margin, remain position need to meet the requirement of initMarginRatio
    function removeMargin(
        address trader,
        address to,
        uint256 withdrawAmount
    ) external nonReentrant {
        require(
            withdrawAmount > 0,
            "Margin.removeMargin: ZERO_WITHDRAW_AMOUNT"
        );
    }

    function openPosition(
        address trader,
        uint8 side,
        uint256 quoteAmount
    ) external nonReentrant returns (uint256 baseAmount) {}

    function closePosition(
        address trader,
        uint256 quoteAmount
    ) external nonReentrant returns (uint256 baseAmount) {}

    function liquidate(
        address trader,
        address to
    )
        external
        nonReentrant
        returns (uint256 quoteAmount, uint256 baseAmount, uint256 bonus)
    {}

    function _executeSettle(
        address _trader,
        bool isIndexPrice,
        bool isLong,
        int256 fundingFee,
        int256 baseSize,
        uint256 baseAmount,
        uint256 quoteAmount
    ) internal returns (uint256 bonus) {}

    function deposit(address user, uint256 amount) external nonReentrant {
        require(amount > 0, "Margin.deposit: AMOUNT_IS_ZERO");
        uint256 balance = IERC20(baseToken).balanceOf(address(this));

        emit Deposit(user, amount);
    }

    function withdraw(
        address user,
        address receiver,
        uint256 amount
    ) external nonReentrant {
        _withdraw(user, receiver, amount);
    }

    function _withdraw(
        address user,
        address receiver,
        uint256 amount
    ) internal {
        require(amount > 0, "Margin._withdraw: AMOUNT_IS_ZERO");
        IERC20(baseToken).transfer(receiver, amount);

        emit Withdraw(user, receiver, amount);
    }

    function updateCPF() public returns (int256 newLatestCPF) {}

    function getPosition(
        address trader
    ) external view returns (int256, int256, uint256) {
        Position memory position = traderPositionMap[trader];
        return (position.baseSize, position.quoteSize, position.tradeSize);
    }

    function getWithdrawable(
        address trader
    ) external view returns (uint256 withdrawable) {
        Position memory position = traderPositionMap[trader];
        int256 fundingFee = _calFundingFee(trader, _getNewLatestCPF());

        (withdrawable, ) = _getWithdrawable(
            position.quoteSize,
            position.baseSize + fundingFee,
            position.tradeSize
        );
    }

    function getNewLatestCPF() external view returns (int256) {
        return _getNewLatestCPF();
    }

    function canLiquidate(address trader) external view returns (bool) {}

    function calFundingFee(address trader) public view returns (int256) {
        return _calFundingFee(trader, _getNewLatestCPF());
    }

    function calDebtRatio(
        address trader
    ) external view returns (uint256 debtRatio) {}

    function calUnrealizedPnl(
        address trader
    ) external view returns (int256 unrealizedPnl) {
        Position memory position = traderPositionMap[trader];
    }

    function netPosition() external view returns (int256) {}

    function totalPosition()
        external
        view
        returns (uint256 totalQuotePosition)
    {}

    function _getNewLatestCPF() internal view returns (int256 newLatestCPF) {}

    function _getWithdrawable(
        int256 quoteSize,
        int256 baseSize,
        uint256 tradeSize
    ) internal view returns (uint256 amount, int256 unrealizedPnl) {}

    function _calFundingFee(
        address trader,
        int256 _latestCPF
    ) internal view returns (int256) {
        Position memory position = traderPositionMap[trader];
    }
}
