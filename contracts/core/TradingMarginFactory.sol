// SPDX-License-Identifier: MIT
// This contract represents a factory for creating and initializing trading margin contracts.
pragma solidity =0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./TradingMargin.sol";
import "../interfaces/ITradingMarginFactory.sol";
import "../interfaces/ITradingMargin.sol";

// TradingMarginFactory contract implements the ITradingMarginFactory interface and is called by the TradingPairFactory.
contract TradingMarginFactory is ITradingMarginFactory, Ownable {
    // The address of the TradingPairFactory contract that calls this factory.
    address public override tradingPairFactory;

    // The address of the configuration contract.
    address public override config;

    // Mapping to store the trading margin contract address for each baseToken and quoteToken pair.
    mapping(address => mapping(address => address)) public override getMargin;

    // Modifier to restrict access to only the TradingPairFactory.
    modifier onlyPairFactory() {
        require(msg.sender == tradingPairFactory, "TMF: Unauthorized");
        _;
    }

    /**
     * @dev Constructor initializes the TradingMarginFactory with the TradingPairFactory and configuration contract addresses.
     * @param _tradingPairFactory Address of the TradingPairFactory contract.
     * @param _config Address of the configuration contract.
     */
    constructor(
        address _tradingPairFactory,
        address _config
    ) Ownable(msg.sender) {
        require(_tradingPairFactory != address(0), "TMF: Invalid Address");
        require(_config != address(0), "TMF: Invalid Address");
        tradingPairFactory = _tradingPairFactory;
        config = _config;
    }

    /**
     * @dev Sets a new pair factory contract.
     * @param pairFactoryAdd Address of the pair factory contract.
     */
    function setPairFactory(address pairFactoryAdd) external onlyOwner {
        require(pairFactoryAdd != address(0), "TMF: Invalid Address");
        tradingPairFactory = pairFactoryAdd;
    }

    /**
     * @dev Creates a new trading margin contract for the specified baseToken and quoteToken pair.
     * @param baseToken Address of the base token.
     * @param quoteToken Address of the quote token.
     * @return margin Address of the newly created trading margin contract.
     */
    function createMargin(
        address baseToken,
        address quoteToken
    ) external override onlyPairFactory returns (address margin) {
        // Ensure baseToken and quoteToken are different and not zero addresses.
        require(baseToken != quoteToken, "TMF: Identical addresses");
        require(
            baseToken != address(0) && quoteToken != address(0),
            "TMF: Invalid Address"
        );

        // Ensure a trading margin contract does not already exist for the specified pair.
        require(
            getMargin[baseToken][quoteToken] == address(0),
            "TMF: Contract exist"
        );

        // Generate a salt using the keccak256 hash of the pair's baseToken and quoteToken.
        bytes32 salt = keccak256(abi.encodePacked(baseToken, quoteToken));

        margin = address(new TradingMargin{salt: salt}(baseToken, quoteToken));

        // Update the mapping with the new trading margin contract address.
        getMargin[baseToken][quoteToken] = margin;

        // Emit an event to signal the creation of a new trading margin contract.
        emit MarginCreated(baseToken, quoteToken, margin);
    }

    /**
     * @dev Initializes the trading margin contract with the specified baseToken, quoteToken, and AMM (Automated Market Maker) address.
     * @param baseToken Address of the base token.
     * @param quoteToken Address of the quote token.
     */
    function initMargin(
        address baseToken,
        address quoteToken
    ) external override onlyPairFactory {
        // Retrieve the trading margin contract address for the specified pair.
        address margin = getMargin[baseToken][quoteToken];
        require(margin != address(0), "TMF: Invalid Address");

        // Initialize the trading margin contract with the specified parameters.
        ITradingMargin(margin).initialize(baseToken, quoteToken);
    }
}
