// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

interface ITradingMarginFactory {
    event MarginCreated(
        address indexed baseToken,
        address indexed quoteToken,
        address margin
    );

    /**
     * @dev Sets a new pair factory contract.
     * @param pairFactoryAdd Address of the pair factory contract.
     */
    function setPairFactory(address pairFactoryAdd) external;

    /**
     * @dev Creates a new trading margin contract for the specified baseToken and quoteToken pair.
     * @param baseToken Address of the base token.
     * @param quoteToken Address of the quote token.
     * @return margin Address of the newly created trading margin contract.
     */
    function createMargin(
        address baseToken,
        address quoteToken
    ) external returns (address margin);

    /**
     * @dev Initializes the trading margin contract with the specified baseToken, quoteToken, and AMM (Automated Market Maker) address.
     * @param baseToken Address of the base token.
     * @param quoteToken Address of the quote token.
     */
    function initMargin(address baseToken, address quoteToken) external;

    /**
     * @dev Retrieves the address of the trading margin contract associated with the given trading pair.
     * @param baseToken Address of the base token for the trading pair.
     * @param quoteToken Address of the quote token for the trading pair.
     */
    function getMargin(
        address baseToken,
        address quoteToken
    ) external view returns (address margin);
}
