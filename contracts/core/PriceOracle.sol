// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title PriceOracle
 * @dev A decentralized oracle contract for fetching and calculating prices using Pyth and Chainlink oracles.
 */
contract PriceOracle is Ownable {
    struct PriceOracleEntry {
        uint256 lastUpdatedTimestamp;
        address chainlinkOracleAddress;
    }

    // Mapping to associate unique Perp addresses with Chainlink Oracle Address
    mapping(address => PriceOracleEntry) public priceOracleEntries;

    event PriceOracleAdded(address indexed perpAddress, address oracleAddress);

    /**
     * @dev Constructor to initialize the PriceOracle contract.
     * @param _initialOwner The initial owner of the contract.
     */
    constructor(address _initialOwner) Ownable(_initialOwner) {}

    /**
     * @dev Add a new price oracle entry for a Perp contract.
     * @param chainlinkOracleAddress The Chainlink Oracle Address.
     * @param perpAddress The Perp contract address.
     */
    function addPriceOracleEntry(
        address chainlinkOracleAddress,
        address perpAddress
    ) external onlyOwner {
        require(perpAddress != address(0), "PriceOracle: Invalid address");
        require(
            chainlinkOracleAddress != address(0),
            "PriceOracle: Invalid Chainlink Oracle Address"
        );

        PriceOracleEntry storage entry = priceOracleEntries[
            chainlinkOracleAddress
        ];
        entry.chainlinkOracleAddress = chainlinkOracleAddress;
        emit PriceOracleAdded(perpAddress, chainlinkOracleAddress);
    }

    /**
     * @dev Get the aggregated price for a given Perp contract.
     * @param perpAddress The Perp contract address.
     * @return The aggregated price.
     */
    function getPrices(address perpAddress) external returns (uint256) {
        PriceOracleEntry storage entry = priceOracleEntries[perpAddress];

        (
            uint256 chainlinkPrice,
            uint256 timestamp
        ) = getChainlinkPriceAndTimestamp(entry.chainlinkOracleAddress);
        entry.lastUpdatedTimestamp = timestamp;

        return chainlinkPrice;
    }

    /**
     * @dev Get the Chainlink price and timestamp for a given Chainlink Oracle Address.
     * @param _chainlinkOracleAddress The Chainlink Oracle Address.
     * @return uint256 The Chainlink price.
     * @return uint256 The timestamp of the latest data.
     */
    function getChainlinkPriceAndTimestamp(
        address _chainlinkOracleAddress
    ) internal view returns (uint256, uint256) {
        AggregatorV3Interface chainlinkOracle = AggregatorV3Interface(
            _chainlinkOracleAddress
        );
        (, int256 chainlinkPrice, , uint256 timeStamp, ) = chainlinkOracle
            .latestRoundData();
        require(chainlinkPrice > 0, "PriceOracle: Invalid Chainlink price");

        return (uint256(chainlinkPrice), timeStamp);
    }
}
