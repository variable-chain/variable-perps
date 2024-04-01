// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IVariableController.sol";
import "../interfaces/IVariableOrderSettler.sol";

contract VariablePositionManager is Ownable, ReentrancyGuard {
    struct PositionDetail {
        bytes32 perpMarketId;
        address trader;
        uint256 positionSize;
        uint256 leverageRatio;
        uint256 fees;
    }
    IVariableOrderSettler public variableOrderSettler;

    IVariableController public variableController;

    mapping(bytes32 => PositionDetail) public positionManager;

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
    constructor(
        address _intialOwner,
        address _variableController,
        address _variableOrderSettler
    ) Ownable(_intialOwner) {
        variableController = IVariableController(_variableController);
        variableOrderSettler = IVariableOrderSettler(_variableOrderSettler);
    }

    function updateVariableOrderSettler(
        address newSettler
    ) external onlyController {
        require(newSettler != address(0), "VariableVault: Invalid address");
        variableOrderSettler = IVariableOrderSettler(newSettler);
    }

    function updatePositionController(
        address newController
    ) external onlyController {
        variableController = IVariableController(newController);
    }

    function updatePosition(
        bytes32 perpMarketId,
        bytes32 positionId,
        address trader,
        uint256 positionSize,
        uint256 leverageRatio,
        uint256 fees
    ) external onlyOrderSettler {
        PositionDetail storage position = positionManager[positionId];
        position.perpMarketId = perpMarketId;
        position.trader = trader;
        position.positionSize = positionSize;
        position.leverageRatio = leverageRatio;
        position.fees = fees;
    }
}
