// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

interface ITradingPairFactory {
    event NewPair(address indexed baseToken, address indexed quoteToken, address margin);

    /**
     * @dev Creates a new trading pair and its associated margin contract.
     * @param baseToken Address of the base token for the trading pair.
     * @param quoteToken Address of the quote token for the trading pair.
     * @return margin Address of the newly created trading margin contract.
     */
    function createPair(address baseToken, address quoteToken) external returns (address margin);

    // Address of the margin factory contract responsible for creating and initializing trading margin contracts.
    function marginFactory() external view returns (address);

    /**
     * @dev Retrieves the address of the trading margin contract associated with the given trading pair.
     * @param baseToken Address of the base token for the trading pair.
     * @param quoteToken Address of the quote token for the trading pair.
     * @return Address of the associated trading margin contract.
     */
    function getMargin(address baseToken, address quoteToken) external view returns (address);
}
