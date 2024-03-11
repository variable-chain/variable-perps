// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./VariableOrderSettlement.sol";
import "../interfaces/IPriceOracle.sol";
import "../interfaces/IVariableVault.sol";

contract VariableLedger is Ownable, ReentrancyGuard {
    address public baseToken;
    address public quoteToken;
    address public priceOracle;
    uint256 public interestRate;

    IVariableVault public variableVault;

    struct Position {
        uint256 positionSize;
        uint256 allocatedCollateral;
        bool isLong;
    }

    // mapping of user -> positionId -> position
    mapping(address => mapping(bytes32 => Position)) public traderPositions;

    event UpdatedTraderPosition(
        address indexed trader,
        bytes32 indexed positionId,
        uint256 marginAmount
    );
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
        address _variableVault,
        uint256 _interestRate
    ) Ownable(_initialOwner) {
        baseToken = _baseToken;
        quoteToken = _quoteToken;
        variableVault = IVariableVault(_variableVault);
        interestRate = _interestRate;
    }

    function adjustPositionMargin(
        address trader,
        bytes32 positionId,
        uint256 marginAmount
    ) external {
        require(
            msg.sender == address(variableVault),
            "VariableLedger: Unauthorized Access"
        );
        require(trader != address(0), "VariableLedger: Invalid trader address");

        Position storage position = traderPositions[trader][positionId];
        position.allocatedCollateral += marginAmount;

        // Emit an event or perform any other necessary actions
        emit UpdatedTraderPosition(trader, positionId, marginAmount);
    }

    function updateInterestRate(uint256 newRate) external onlyOwner {
        require(newRate != 0, "VariableLedger: Greater than zero");
        interestRate = newRate;
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
        uint256 leverageRatio,
        address trader,
        bytes32 positionId,
        bool isLong
    ) external nonReentrant {
        (uint256 avalAmount, ) = variableVault.balances(trader);
        // Check if the trader has sufficient balance in the VariableVault
        require(
            amount <= avalAmount,
            "VariableLedger: Insufficient balance in VariableVault"
        );
        uint256 collateralAmount = amount / leverageRatio;
        // Call the openPosition function of VariableVault
        variableVault.openMarginPosition(
            collateralAmount,
            trader,
            address(this)
        );

        // Update the trader's position in the VariableLedger contract
        Position storage traderPosition = traderPositions[trader][positionId];

        traderPosition.positionSize = amount;
        traderPosition.allocatedCollateral = amount / leverageRatio;
        traderPosition.isLong = isLong;

        // Emit an event or perform any other necessary actions
        // emit OpenPosition(trader, 0, amount, 0, traderPosition);
    }

    function closePositionInVault(
        uint256 amount,
        uint256 leverageRatio,
        int256 fundingFee,
        address trader,
        bytes32 positionId,
        bool isLong
    ) external nonReentrant {
        // Check if the trader has a position to close in the VariableLedger
        Position storage traderPosition = traderPositions[trader][positionId];
        require(
            amount <= uint256(traderPosition.positionSize),
            "VariableLedger.closePositionInVault: Insufficient position to close"
        );
        int256 netAmount;
        if (fundingFee > 0) {
            netAmount = int(amount) + fundingFee;
        } else {
            // calculate fee components
            netAmount = int256(amount) - fundingFee;
        }
        int256 collateralAmount = netAmount / int(leverageRatio);
        // Call the closeMarginPosition function of VariableVault
        variableVault.closeMarginPosition(
            collateralAmount,
            trader,
            address(this)
        );

        // Update the trader's position in the VariableLedger contract

        traderPosition.positionSize -= amount;
        traderPosition.isLong = isLong;
        traderPosition.allocatedCollateral = amount / leverageRatio;

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
        address trader,
        bytes32 positionId
    ) external view returns (uint256, uint256, bool) {
        Position memory position = traderPositions[trader][positionId];
        return (
            position.positionSize,
            position.allocatedCollateral,
            position.isLong
        );
    }

    function getWithdrawable(
        address trader,
        bytes32 positionId
    ) external view returns (uint256 withdrawable) {
        // Position memory position = traderPositions[trader][positionId];
        // int256 fundingFee = _calFundingFee(trader, _getNewLatestCPF());
        // (withdrawable, ) = _getWithdrawable(
        //     position.positionSize,
        //     position.baseSize + fundingFee,
        //     position.tradeSize
        // );
    }

    function getNewLatestCPF() external view returns (int256) {
        return _getNewLatestCPF();
    }

    function canLiquidate(address trader) external view returns (bool) {}

    // function calFundingFee(address trader) public view returns (int256) {
    //     return _calFundingFee(trader, _getNewLatestCPF());
    // }

    function calDebtRatio(
        address trader
    ) external view returns (uint256 debtRatio) {}

    function calUnrealizedPnl(
        address trader,
        bytes32 positionId
    ) external view returns (int256 unrealizedPnl) {
        // Position memory position = traderPositions[trader][positionId];
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
        int256 _latestCPF,
        bytes32 positionId
    ) internal view returns (int256) {}
}
