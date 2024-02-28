// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IVariableLedger.sol";
import "./VariableLedger.sol";
import "../interfaces/IVariableVault.sol";

/**
 * @title VariableMarketRegistry
 * @dev This contract serves as a registry for VariableLedger contracts in a decentralized trading system.
 * It allows the creation and management of perpetual ledgers for different baseToken and quoteToken pairs.
 */
contract VariableMarketRegistry is Ownable {
    // Address of the VariableVault contract used in the trading system.
    address public variableVault;

    // Mapping to store the deployed VariableLedger contracts for each baseToken and quoteToken pair.
    mapping(address => mapping(address => address)) public getPerpLedger;

    /**
     * @dev Constructor to initialize the VariableMarketRegistry with the initial owner and VariableVault address.
     * @param _initialOwner The address of the initial owner of the contract.
     * @param _variableVault The address of the VariableVault contract to be used in the trading system.
     */
    constructor(
        address _initialOwner,
        address _variableVault
    ) Ownable(_initialOwner) {
        variableVault = _variableVault;
    }

    /**
     * @dev Updates the VariableVault address. Only callable by the owner.
     * @param newVault The new address of the VariableVault contract.
     */
    function updateVariableVault(address newVault) external onlyOwner {
        require(newVault != address(0), "VariableVault: Invalid address");
        variableVault = newVault;
    }

    /**
     * @dev Creates a new VariableLedger contract for a given baseToken and quoteToken pair.
     * @param baseToken The address of the baseToken in the trading pair.
     * @param quoteToken The address of the quoteToken in the trading pair.
     * @return margin The address of the newly created VariableLedger contract.
     */
    function createPerpLedger(
        address baseToken,
        address quoteToken
    ) external returns (address margin) {
        // Ensure baseToken and quoteToken are different and not zero addresses.
        require(baseToken != quoteToken, "TMF: Identical addresses");
        require(
            baseToken != address(0) && quoteToken != address(0),
            "TMF: Invalid Address"
        );

        // Ensure no existing contract for the given pair.
        require(
            getPerpLedger[baseToken][quoteToken] == address(0),
            "TMF: Contract exists"
        );

        // Generate a salt using the keccak256 hash of the pair's baseToken and quoteToken.
        bytes32 salt = keccak256(abi.encodePacked(baseToken, quoteToken));

        // Deploy a new VariableLedger contract with the calculated salt.
        margin = address(
            new VariableLedger{salt: salt}(
                owner(),
                baseToken,
                quoteToken,
                variableVault
            )
        );

        // Update the mapping with the deployed contract address.
        getPerpLedger[baseToken][quoteToken] = margin;
    }
}
