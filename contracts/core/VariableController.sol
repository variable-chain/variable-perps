// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../interfaces/IVariableMarketRegistry.sol";
import "../interfaces/IVariableOrderSettler.sol";

import "../interfaces/IVariableVault.sol";

import "../interfaces/IVariableController.sol";

contract VariableController is Ownable, IVariableController {
    IVariableVault public variableVault;

    IVariableOrderSettler public variableOrderSettler;

    IVariableMarketRegistry public variableMarketRegistry;

    constructor(
        address _initialOwner,
        address _variableVault,
        address _variableOrderSettler,
        address _variableMarketRegistry
    ) Ownable(_initialOwner) {
        variableVault = IVariableVault(_variableVault);
        variableOrderSettler = IVariableOrderSettler(_variableOrderSettler);
        variableMarketRegistry = IVariableMarketRegistry(
            _variableMarketRegistry
        );
    }

    function updateVariableController(
        address newController
    ) external override onlyOwner {
        require(
            newController != address(0),
            "VariableController: Invalid address"
        );
        IVariableOrderSettler(variableOrderSettler).updateVariableController(
            newController
        );
    }

    function updateVariableMarketRegistry(
        address newMarketRegistry
    ) external override onlyOwner {
        require(
            newMarketRegistry != address(0),
            "VariableOrderSettlement: Invalid address"
        );
        IVariableOrderSettler(variableOrderSettler)
            .updateVariableMarketRegistry(newMarketRegistry);
    }

    function matchOrders(
        OrderStruct[] memory buyOrders,
        OrderStruct[] memory sellOrders
    ) external override onlyOwner {
        IVariableOrderSettler(variableOrderSettler).matchOrders(
            buyOrders,
            sellOrders
        );
    }

    function updateVariableVault(
        address newVariableVault
    ) external override onlyOwner {
        require(
            newVariableVault != address(0),
            "VariableOrderSettlement: Invalid address"
        );
        IVariableOrderSettler(variableOrderSettler).updateVariableVault(
            newVariableVault
        );
    }

    function updateWithdrawCap(uint256 newCap) external override onlyOwner {
        require(newCap != 0, "VariableVault: Invalid withdrawal amount");
        IVariableVault(variableVault).updateWithdrawCap(newCap);
    }

    function updateVaultController(
        address newVaultController
    ) external onlyOwner {
        require(
            newVaultController != address(0),
            "VariableVault: Invalid address"
        );
        IVariableVault(variableVault).updateVaultController(newVaultController);
    }

    function updateVariableOrderSettler(
        address newSettler
    ) external override onlyOwner {
        require(newSettler != address(0), "VariableVault: Invalid address");
        IVariableVault(variableVault).updateVariableOrderSettler(newSettler);
    }

    function withdrawRemainingBalance() external override onlyOwner {
        IVariableVault(variableVault).withdrawRemainingBalance();
    }

    function withdrawToken(address to) external override onlyOwner {
        IVariableVault(variableVault).withdrawToken(to);
    }

    function registerPerpMarket(
        bytes32 perpMarketId
    ) external override onlyOwner {
        require(
            perpMarketId != bytes32(0),
            "VariableMarketRegistry: Invalid perpMarketId"
        );
        IVariableMarketRegistry(variableMarketRegistry).registerPerpMarket(
            perpMarketId
        );
    }

    function deRegisterPerpMarket(bytes32 perpMarketId) external override {
        require(
            perpMarketId != bytes32(0),
            "VariableMarketRegistry: Invalid perpMarketId"
        );
        IVariableMarketRegistry(variableMarketRegistry).deRegisterPerpMarket(
            perpMarketId
        );
    }
}
