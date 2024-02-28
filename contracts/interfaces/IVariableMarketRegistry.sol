// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

/**
 * @title IVariableMarketRegistry
 * @dev Interface for the VariableMarketRegistry contract.
 */
interface IVariableMarketRegistry {
    /**
     * @dev Returns the address of the VariableVault contract.
     * @return variableVault The address of the VariableVault contract.
     */
    function variableVault() external view returns (address);

    /**
     * @dev Returns the address of the VariableLedger contract for a given baseToken and quoteToken pair.
     * @param baseToken The address of the baseToken in the trading pair.
     * @param quoteToken The address of the quoteToken in the trading pair.
     * @return margin The address of the VariableLedger contract.
     */
    function getPerpLedger(
        address baseToken,
        address quoteToken
    ) external view returns (address margin);

    /**
     * @dev Updates the VariableVault address. Only callable by the owner.
     * @param newVault The new address of the VariableVault contract.
     */
    function updateVariableVault(address newVault) external;

    /**
     * @dev Creates a new VariableLedger contract for a given baseToken and quoteToken pair.
     * @param baseToken The address of the baseToken in the trading pair.
     * @param quoteToken The address of the quoteToken in the trading pair.
     * @return margin The address of the newly created VariableLedger contract.
     */
    function createPerpLedger(
        address baseToken,
        address quoteToken
    ) external returns (address margin);
}
