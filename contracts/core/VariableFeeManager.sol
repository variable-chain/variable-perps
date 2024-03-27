// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IVariableFeeDistributor.sol";
import "../interfaces/IVariableController.sol";

contract VariableFeeManager is Ownable {
    // Address of the VariableController contract used for controlling market registration.
    IVariableController public variableController;
    uint256 public compositFee;
    uint256 public liquidationFee;

    constructor(
        address _initialOwner,
        address _variableController
    ) Ownable(_initialOwner) {
        variableController = IVariableController(_variableController);
    }
    /**
     * @dev Modifier to restrict functions to be callable only by the controller.
     */
    modifier onlyController() {
        require(
            msg.sender == address(variableController),
            "VariableFeeManager: Not authorized"
        );
        _;
    }

    /**
     * @dev Updates the VariableController address. Only callable by the owner.
     * @param newController The new address of the VariableController contract.
     */
    function updateFeeController(
        address newController
    ) external onlyController {
        variableController = IVariableController(newController);
    }

    function setCompositFee(uint256 fee) external onlyController {
        require(fee > 0, "VariableFeeManager: Greater than zero");
        compositFee = fee;
    }

    function setLiquidationFee(uint256 fee) external onlyController {
        require(fee > 0, "VariableFeeManager: Greater than zero");
        liquidationFee = fee;
    }

    function calculateFees(
        bool isLiquidation,
        uint256 positionSize
    ) external view returns (uint256 totalFees) {
        if (isLiquidation) {
            totalFees = (positionSize * (liquidationFee + compositFee)) / 10000;
        } else {
            totalFees = (positionSize * compositFee) / 10000;
        }
    }
}
