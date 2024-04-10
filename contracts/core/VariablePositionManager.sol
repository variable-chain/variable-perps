// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IVariableController.sol";
import "../interfaces/IVariableOrderSettler.sol";
import "../interfaces/IVariableVault.sol";

/**
 * @title VariablePositionManager
 * @dev A contract for managing variable positions in a financial system.
 *      This contract allows for the management of positions, including adjusting margins,
 *      updating positions, and calculating total open position collateral.
 */
contract VariablePositionManager is Ownable, ReentrancyGuard {
    struct PositionDetail {
        bytes32 perpMarketId;
        uint256 positionSize;
        uint256 leverageRatio;
        uint256 allocatedCollateral;
        uint256 fees;
    }

    // Instance variables for external contracts
    IVariableOrderSettler public variableOrderSettler;
    IVariableController public variableController;
    IVariableVault public variableVault;

    // Mapping to store position details
    // trader -> positionId -> positionDetail
    mapping(address => mapping(bytes32 => PositionDetail))
        public positionManager;

    /**
     * @dev Modifier to restrict functions to be callable only by the controller.
     */
    modifier onlyController() {
        require(
            msg.sender == address(variableController),
            "VariableVault: Not authorized"
        );
        _;
    }

    /**
     * @dev Modifier to restrict functions to be callable only by the order settler.
     */
    modifier onlyOrderSettler() {
        require(
            msg.sender == address(variableOrderSettler),
            "VariableVault: Not authorized"
        );
        _;
    }

    /**
     * @dev Constructor to initialize the contract with the provided addresses.
     * @param _intialOwner The initial owner of the contract.
     * @param _variableController The address of the VariableController contract.
     * @param _variableOrderSettler The address of the VariableOrderSettler contract.
     * @param _variableVault The address of variable vault.
     */
    constructor(
        address _intialOwner,
        address _variableController,
        address _variableOrderSettler,
        address _variableVault
    ) Ownable(_intialOwner) {
        variableController = IVariableController(_variableController);
        variableOrderSettler = IVariableOrderSettler(_variableOrderSettler);
        variableVault = IVariableVault(_variableVault);
    }

    /**
     * @dev Function to update the address of the VariableOrderSettler contract.
     * @param newSettler The new address of the VariableOrderSettler contract.
     */
    function updateVariableOrderSettler(
        address newSettler
    ) external onlyController {
        require(newSettler != address(0), "VariableVault: Invalid address");
        variableOrderSettler = IVariableOrderSettler(newSettler);
    }

    /**
     * @dev Function to update the address of the VariableVault contract.
     * @param newVault The new address of the VariableOrderSettler contract.
     */
    function updateVariableVault(address newVault) external onlyController {
        require(newVault != address(0), "VariableVault: Invalid address");
        variableVault = IVariableVault(newVault);
    }

    /**
     * @dev Function to update the address of the VariableController contract.
     * @param newController The new address of the VariableController contract.
     */
    function updatePositionController(
        address newController
    ) external onlyController {
        variableController = IVariableController(newController);
    }

    /**
     * @dev Function to update a position with new details.
     * @param perpMarketId The identifier of the perpetual market associated with the position.
     * @param positionId The unique identifier of the position.
     * @param trader The address of the trader owning the position.
     * @param allocatedCollateral The amount of collateral allocated to the position.
     * @param positionSize The size of the position.
     * @param leverageRatio The leverage ratio of the position.
     * @param fees The fees associated with the position.
     */
    function updatePosition(
        bool addPosition,
        bytes32 quoteTokenName,
        bytes32 perpMarketId,
        bytes32 positionId,
        address trader,
        uint256 allocatedCollateral,
        uint256 positionSize,
        uint256 leverageRatio,
        uint256 fees
    ) external onlyOrderSettler {
        PositionDetail storage position = positionManager[trader][positionId];
        position.perpMarketId = perpMarketId;
        position.leverageRatio = leverageRatio;
        position.fees += fees;

        variableVault.manageVaultBalance(
            addPosition,
            trader,
            quoteTokenName,
            allocatedCollateral
        );
        if (addPosition) {
            position.positionSize += positionSize;

            position.allocatedCollateral += allocatedCollateral;
        } else {
            position.positionSize -= positionSize;

            position.allocatedCollateral -= allocatedCollateral;
        }
    }

    /**
     * @dev Function to adjust the margin of a position.
     * @param positionId The unique identifier of the position.
     * @param amount The amount by which to adjust the margin.
     * @param trader The address of the trader owning the position.
     * @param increase A boolean indicating whether to increase or decrease the margin.
     */
    function adjustCollateral(
        bytes32 positionId,
        bytes32 quoteTokenName,
        uint256 amount,
        address trader,
        bool increase
    ) external {
        // TODO: validation checks & caller
        // Ensure the position exists
        require(
            positionManager[trader][positionId].positionSize > 0,
            "Position does not exist"
        );
        variableVault.manageVaultBalance(
            increase,
            trader,
            quoteTokenName,
            amount
        );
        if (increase) {
            // Increase allocated collateral
            positionManager[trader][positionId].allocatedCollateral += amount;
        } else {
            // Decrease allocated collateral
            positionManager[trader][positionId].allocatedCollateral -= amount;
        }
    }

    /**
     * @dev Function to calculate the total open position collateral for a trader.
     * @param trader The address of the trader.
     * @param positionIds An array of position identifiers.
     * @return totalCollateral The total collateral of the trader's open positions.
     */
    function calculateTotalOpenPositionCollateral(
        address trader,
        bytes32[] memory positionIds
    ) external view returns (uint256) {
        uint256 totalCollateral = 0;

        for (uint256 i = 0; i < positionIds.length; i++) {
            bytes32 positionId = positionIds[i];
            PositionDetail memory position = positionManager[trader][
                positionId
            ];

            // Ensure position exists and leverage ratio is not zero
            require(
                position.positionSize != 0 && position.leverageRatio != 0,
                "Invalid position"
            );

            // Calculate open position collateral using the formula: positionSize / leverageRatio
            totalCollateral += position.positionSize / position.leverageRatio;
        }

        return totalCollateral;
    }
}
