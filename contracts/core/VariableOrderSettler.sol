// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IVariableVault.sol";
import "../interfaces/IVariableMarketRegistry.sol";
import "../interfaces/IVariableOrderSettler.sol";
import "../interfaces/IVariableController.sol";
import "../interfaces/IVariableFeeDistributor.sol";

import "../interfaces/IVariableFeeManager.sol";

import "../interfaces/IVariableReferral.sol";

import "../interfaces/IVariablePositionManager.sol";

/**
 * @title VariableOrderSettler
 * @dev Smart contract for settling matched orders between buyers and sellers in a decentralized trading system.
 */
contract VariableOrderSettler is
    Ownable,
    ReentrancyGuard,
    IVariableOrderSettler
{
    IVariableMarketRegistry public variableMarketRegistry;

    // Address of the VariableController contract used for controlling market registration.
    IVariableController public variableController;

    IVariableVault public variableVault;

    IVariableFeeDistributor public variableFeeDistributor;

    IVariableFeeManager public variableFeeManager;

    IVariableReferral public variableReferral;

    IVariablePositionManager public variablePositionManager;

    /**
     * @dev Modifier to restrict functions to be callable only by the controller.
     */
    modifier onlyController() {
        require(
            msg.sender == address(variableController),
            "VariableMarketRegistry: Not authorized"
        );
        _;
    }

    /**
     * @dev Constructor function to initialize the contract with the owner and initial Variable Market Registry address.
     * @param _initialOwner The initial owner of the contract.
     * @param _variableMarketRegistry The address of the Variable Market Registry contract.
     * @param _variableVault The address of the Variable Vault contract.
     * @param _variableController The address of the Variable Controller contract.
     * @param _variableFeeDistributor the address of the variable fee distributor
     * @param _variableFeeManager the address of variable fee manager
     *
     */
    constructor(
        address _initialOwner,
        address _variableMarketRegistry,
        address _variableVault,
        address _variableController,
        address _variableFeeDistributor,
        address _variableFeeManager,
        address _variablePositionManager
    ) Ownable(_initialOwner) {
        variableMarketRegistry = IVariableMarketRegistry(
            _variableMarketRegistry
        );
        variableVault = IVariableVault(_variableVault);
        variableController = IVariableController(_variableController);
        variableFeeDistributor = IVariableFeeDistributor(
            _variableFeeDistributor
        );
        variableFeeManager = IVariableFeeManager(_variableFeeManager);
        variablePositionManager = IVariablePositionManager(
            _variablePositionManager
        );
    }

    /**
     * @dev Updates the VariableController address. Only callable by the controller.
     * @param newController The new address of the VariableController contract.
     */
    function updateVariableController(
        address newController
    ) external onlyController {
        variableController = IVariableController(newController);
    }

    /**
     * @dev Updates the VariableController address. Only callable by the controller.
     * @param newFeeManager The new address of the VariableController contract.
     */
    function updateVariableFeeManager(
        address newFeeManager
    ) external onlyController {
        variableFeeManager = IVariableFeeManager(newFeeManager);
    }

    function updateVariablePositionManager(
        address newPositionManager
    ) external onlyController {
        variablePositionManager = IVariablePositionManager(newPositionManager);
    }

    function updateVariableReferral(
        address newReferral
    ) external onlyController {
        variableReferral = IVariableReferral(newReferral);
    }

    /**
     * @dev Updates the VariableController address. Only callable by the controller.
     * @param newFeeDistributor The new address of the VariableController contract.
     */
    function updateVariableFeeDistributor(
        address newFeeDistributor
    ) external onlyController {
        variableFeeDistributor = IVariableFeeDistributor(newFeeDistributor);
    }

    /**
     * @dev Updates the Variable Market Registry address.
     * @param newMarketRegistry The new address of the Variable Market Registry contract.
     */
    function updateVariableMarketRegistry(
        address newMarketRegistry
    ) external onlyController {
        variableMarketRegistry = IVariableMarketRegistry(newMarketRegistry);
    }

    /**
     * @dev Updates the Variable Vault address.
     * @param newVariableVault The new address of the Variable Vault contract.
     */
    function updateVariableVault(
        address newVariableVault
    ) external onlyController {
        variableVault = IVariableVault(newVariableVault);
    }

    /**
     * @dev Function to match buy and sell orders and settle them.
     * @param buyOrders Array of buy orders.
     * @param sellOrders Array of sell orders.
     */
    function matchOrders(
        OrderStruct[] memory buyOrders,
        OrderStruct[] memory sellOrders
    ) external onlyController {
        uint256 buyIndex = 0;
        uint256 sellIndex = 0;

        while (buyIndex < buyOrders.length && sellIndex < sellOrders.length) {
            OrderStruct memory buyOrder = buyOrders[buyIndex];
            OrderStruct memory sellOrder = sellOrders[sellIndex];

            if (ordersMatch(buyOrder, sellOrder)) {
                settleMatchedOrders(buyOrder, sellOrder);
                buyIndex++;
                sellIndex++;
            } else if (buyOrder.positionSize < sellOrder.positionSize) {
                partialFulfillment(buyOrder, sellOrder);
                buyIndex++;
            } else {
                partialFulfillment(sellOrder, buyOrder);
                sellIndex++;
            }
        }
    }

    function ordersMatch(
        OrderStruct memory order1,
        OrderStruct memory order2
    ) internal pure returns (bool) {
        return (order1.positionSize == order2.positionSize &&
            order1.entryPrice == order2.entryPrice &&
            order1.perpMarketId == order2.perpMarketId);
    }

    function settleMatchedOrders(
        OrderStruct memory buyOrder,
        OrderStruct memory sellOrder
    ) internal {
        uint256 buyerCollateral = calculateCollateral(
            buyOrder.positionSize,
            buyOrder.leverageRatio
        );
        uint256 sellerCollateral = calculateCollateral(
            sellOrder.positionSize,
            sellOrder.leverageRatio
        );
        uint256 buyerFees = IVariableFeeManager(variableFeeManager)
            .calculateFees(
                buyOrder.isLiquidation,
                buyOrder.maker,
                buyOrder.positionSize
            );
        uint256 sellerFees = IVariableFeeManager(variableFeeManager)
            .calculateFees(
                sellOrder.isLiquidation,
                sellOrder.maker,
                sellOrder.positionSize
            );
        IVariablePositionManager(variablePositionManager).updatePosition(
            buyOrder.isIncreaseMargin,
            buyOrder.perpMarketId,
            buyOrder.positionId,
            buyOrder.trader,
            buyerCollateral,
            buyOrder.positionSize,
            buyOrder.leverageRatio,
            buyerFees
        );
        IVariablePositionManager(variablePositionManager).updatePosition(
            sellOrder.isIncreaseMargin,
            sellOrder.perpMarketId,
            sellOrder.positionId,
            sellOrder.trader,
            sellerCollateral,
            sellOrder.positionSize,
            sellOrder.leverageRatio,
            sellerFees
        );
    }

    function partialFulfillment(
        OrderStruct memory makerOrder,
        OrderStruct memory takerOrder
    ) internal {
        if (ordersMatch(makerOrder, takerOrder)) {
            uint256 buyerCollateral = calculateCollateral(
                makerOrder.positionSize,
                makerOrder.leverageRatio
            );
            uint256 sellerCollateral = calculateCollateral(
                takerOrder.positionSize,
                takerOrder.leverageRatio
            );
            uint256 buyerFees = IVariableFeeManager(variableFeeManager)
                .calculateFees(
                    makerOrder.isLiquidation,
                    makerOrder.maker,
                    makerOrder.positionSize
                );
            uint256 sellerFees = IVariableFeeManager(variableFeeManager)
                .calculateFees(
                    takerOrder.isLiquidation,
                    takerOrder.maker,
                    takerOrder.positionSize
                );
            IVariablePositionManager(variablePositionManager).updatePosition(
                makerOrder.isIncreaseMargin,
                makerOrder.perpMarketId,
                makerOrder.positionId,
                makerOrder.trader,
                buyerCollateral,
                makerOrder.positionSize,
                makerOrder.leverageRatio,
                buyerFees
            );
            IVariablePositionManager(variablePositionManager).updatePosition(
                takerOrder.isIncreaseMargin,
                takerOrder.perpMarketId,
                takerOrder.positionId,
                takerOrder.trader,
                sellerCollateral,
                takerOrder.positionSize,
                takerOrder.leverageRatio,
                sellerFees
            );

            takerOrder.positionSize -= makerOrder.positionSize;
        }
    }

    function calculateCollateral(
        uint256 positionSize,
        uint256 leverageRatio
    ) internal pure returns (uint256) {
        return positionSize / leverageRatio;
    }
}
