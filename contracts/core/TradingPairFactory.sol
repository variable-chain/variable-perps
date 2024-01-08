// SPDX-License-Identifier: MIT
// This contract represents a factory for creating trading pairs and interacting with their associated margin contracts.
pragma solidity =0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ITradingPairFactory.sol";
import "../interfaces/ITradingMarginFactory.sol";
import "../interfaces/ITradingMargin.sol";

// TradingPairFactory contract inherits from Ownable, providing basic access control functionality.
contract TradingPairFactory is ITradingPairFactory, Ownable {
    // Address of the margin factory contract responsible for creating and initializing trading margin contracts.
    address public override marginFactory;

    // Constructor sets the initial margin factory address and sets the contract owner as the deployer.
    constructor(address _marginFactory) Ownable(msg.sender) {
        marginFactory = _marginFactory;
    }

    /**
     * @dev Sets a new Margin factory contract.
     * @param marginFactoryAdd Address of the base token for the trading pair.
     */
    function setMarginFactory(address marginFactoryAdd) external onlyOwner {
        require(marginFactoryAdd != address(0), "TPF: Invalid Address");
        marginFactory = marginFactoryAdd;
    }

    /**
     * @dev Creates a new trading pair and its associated margin contract.
     * @param baseToken Address of the base token for the trading pair.
     * @param quoteToken Address of the quote token for the trading pair.
     * @return margin Address of the newly created trading margin contract.
     */
    function createPair(
        address baseToken,
        address quoteToken
    ) external override returns (address margin) {
        require(
            baseToken != address(0) && quoteToken != address(0),
            "TPF: Invalid Address"
        );
        // Delegate the creation of the margin contract to the TradingMarginFactory and initialize it.
        margin = ITradingMarginFactory(marginFactory).createMargin(
            baseToken,
            quoteToken
        );
        ITradingMarginFactory(marginFactory).initMargin(baseToken, quoteToken);

        // Emit an event to signal the creation of a new trading pair.
        emit PairCreated(baseToken, quoteToken, margin);
    }

    /**
     * @dev Retrieves the address of the trading margin contract associated with the given trading pair.
     * @param baseToken Address of the base token for the trading pair.
     * @param quoteToken Address of the quote token for the trading pair.
     * @return Address of the associated trading margin contract.
     */
    function getMargin(
        address baseToken,
        address quoteToken
    ) external view override returns (address) {
        // Delegate the retrieval of the margin contract address to the TradingMarginFactory.
        return
            ITradingMarginFactory(marginFactory).getMargin(
                baseToken,
                quoteToken
            );
    }
}
