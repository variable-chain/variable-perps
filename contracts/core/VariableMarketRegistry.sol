// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IVariableVault.sol";
import "../interfaces/IVariableController.sol";

/**
 * @title VariableMarketRegistry
 * @dev This contract serves as a registry for Perpetual market in a decentralized trading system.
 */
contract VariableMarketRegistry is Ownable {
    // Address of the VariableVault contract used in the trading system.
    IVariableVault public variableVault;

    // Address of the VariableController contract used for controlling market registration.
    IVariableController public variableController;

    // Mapping to track active perpetual markets.
    mapping(bytes32 => bool) public activePerpMarkets;

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
     * @dev Constructor to initialize the VariableMarketRegistry with the initial owner and VariableVault address.
     * @param _initialOwner The address of the initial owner of the contract.
     * @param _variableVault The address of the VariableVault contract to be used in the trading system.
     * @param _variableController The address of the VariableController contract for controlling market registration.
     */
    constructor(
        address _initialOwner,
        address _variableVault,
        address _variableController
    ) Ownable(_initialOwner) {
        variableVault = IVariableVault(_variableVault);
        variableController = IVariableController(_variableController);
    }

    /**
     * @dev Updates the VariableVault address. Only callable by the controller.
     * @param newVault The new address of the VariableVault contract.
     */
    function updateVariableVault(address newVault) external onlyController {
        require(
            newVault != address(0),
            "VariableMarketRegistry: Invalid address"
        );
        variableVault = IVariableVault(newVault);
    }

    /**
     * @dev Updates the VariableController address. Only callable by the controller.
     * @param newController The new address of the VariableController contract.
     */
    function updateVariableController(
        address newController
    ) external onlyController {
        require(
            newController != address(0),
            "VariableMarketRegistry: Invalid address"
        );
        variableController = IVariableController(newController);
    }

    /**
     * @dev Register a new Perpetual market.
     * @param perpMarketId Unique perpetual market Id.
     */
    function registerPerpMarket(bytes32 perpMarketId) external onlyController {
        require(
            perpMarketId != bytes32(0),
            "VariableMarketRegistry: Invalid perpMarketId"
        );
        activePerpMarkets[perpMarketId] = true;
    }

    /**
     * @dev Deregister a Perpetual market.
     * @param perpMarketId Unique perpetual market Id.
     */
    function deRegisterPerpMarket(
        bytes32 perpMarketId
    ) external onlyController {
        require(
            perpMarketId != bytes32(0),
            "VariableMarketRegistry: Invalid perpMarketId"
        );
        activePerpMarkets[perpMarketId] = false;
    }
}
