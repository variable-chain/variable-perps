// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../interfaces/IPriceOracle.sol";
import "../interfaces/IVariableVault.sol";

contract VariableLedger is Ownable, ReentrancyGuard {
    address public baseToken;
    address public quoteToken;
    address public priceOracle;

    IVariableVault public variableVault;

    struct Position {
        int256 quoteSize; //quote amount of position
        int256 baseSize; //margin + fundingFee + unrealizedPnl + deltaBaseWhenClosePosition
        uint256 tradeSize; //if quoteSize>0 unrealizedPnl = baseValueOfQuoteSize - tradeSize; if quoteSize<0 unrealizedPnl = tradeSize - baseValueOfQuoteSize;
    }

    mapping(address => Position) public traderPositionMap;
    mapping(address => int256) public traderCPF;
    event OpenPosition(
        address indexed trader,
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
        address _quoteToken,
        address _variableVault
    ) Ownable(_initialOwner) {
        baseToken = _baseToken;
        quoteToken = _quoteToken;
        variableVault = IVariableVault(_variableVault);
    }

    function setDepositCap(
        address token,
        uint256 depositCap
    ) external onlyOwner {}

    function setMaxCollateralTokensPerAccount(
        uint8 maxCollateralTokensPerAccount
    ) external onlyOwner {}

    function setLiquidationRatio(uint24 liquidationRatio) external onlyOwner {}

    function setCLInsuranceFundFeeRatio(
        uint24 clInsuranceFundFeeRatio
    ) external onlyOwner {}

    function setDebtThreshold(uint256 debtThreshold) external onlyOwner {}

    function openPositionInVault(
        uint256 amount,
        address trader,
        address perpMargin
    ) external nonReentrant {
        (uint256 avalAmount, ) = variableVault.balances(trader);
        // Check if the trader has sufficient balance in the VariableVault
        require(
            amount <= avalAmount,
            "VariableLedger: Insufficient balance in VariableVault"
        );

        // Call the openPosition function of VariableVault
        variableVault.openMarginPosition(amount, trader, perpMargin);

        // Update the trader's position in the VariableLedger contract
        Position storage traderPosition = traderPositionMap[trader];
        traderPosition.baseSize += int256(amount); // Update the baseSize in VariableLedger
        traderPosition.quoteSize += int256(amount); // Update the quoteSize in VariableLedger

        // Emit an event or perform any other necessary actions
        emit OpenPosition(trader, 0, amount, 0, traderPosition);
    }

    function closePositionInVault(
        uint256 amount,
        address trader,
        address perpMargin
    ) external nonReentrant {
        // Check if the trader has a position to close in the VariableLedger
        Position storage traderPosition = traderPositionMap[trader];
        require(
            amount <= uint256(traderPosition.quoteSize),
            "VariableLedger.closePositionInVault: Insufficient position to close"
        );

        // Call the closeMarginPosition function of VariableVault
        variableVault.closeMarginPosition(amount, trader, perpMargin);

        // Update the trader's position in the VariableLedger contract
        traderPosition.baseSize -= int256(amount); // Update the baseSize in VariableLedger
        traderPosition.quoteSize -= int256(amount); // Update the quoteSize in VariableLedger

        // Emit an event or perform any other necessary actions
        emit ClosePosition(trader, 0, amount, 0, traderPosition);
    }

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
