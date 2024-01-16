// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title PriceOracle
 * @dev A decentralized oracle contract for fetching and calculating prices using Pyth and Chainlink oracles.
 */
contract PriceOracle is Ownable {
    uint256 public pythWeight = 1;
    uint256 public chainlinkWeight = 1;

    struct PriceOracleEntry {
        bytes32 pythPriceId;
        address chainlinkOracleAddress;
    }

    IPyth public pyth;

    // Mapping to associate unique Perp addresses with Pyth Price ID and Chainlink Oracle Address
    mapping(address => PriceOracleEntry) public priceOracleEntries;

    /**
     * @dev Constructor to initialize the PriceOracle contract.
     * @param _pythContractAddress The address of the Pyth contract.
     * @param _initialOwner The initial owner of the contract.
     */
    constructor(
        address _pythContractAddress,
        address _initialOwner
    ) Ownable(_initialOwner) {
        pyth = IPyth(_pythContractAddress);
    }

    /**
     * @dev Set the weightage for Pyth and Chainlink prices.
     * @param pythWeightage The weightage for Pyth prices.
     * @param chainlinkWeightage The weightage for Chainlink prices.
     */
    function setWeightage(
        uint256 pythWeightage,
        uint256 chainlinkWeightage
    ) external onlyOwner {
        pythWeight = pythWeightage;
        chainlinkWeight = chainlinkWeightage;
    }

    /**
     * @dev Add a new price oracle entry for a Perp contract.
     * @param pythPriceId The Pyth Price ID.
     * @param chainlinkOracleAddress The Chainlink Oracle Address.
     * @param perpAddress The Perp contract address.
     */
    function addPriceOracleEntry(
        bytes32 pythPriceId,
        address chainlinkOracleAddress,
        address perpAddress
    ) external onlyOwner {
        require(perpAddress != address(0), "PriceOracle: Invalid address");
        require(
            pythPriceId != bytes32(0),
            "PriceOracle: Invalid Pyth Price ID"
        );
        require(
            chainlinkOracleAddress != address(0),
            "PriceOracle: Invalid Chainlink Oracle Address"
        );

        priceOracleEntries[perpAddress] = PriceOracleEntry(
            pythPriceId,
            chainlinkOracleAddress
        );
    }

    /**
     * @dev Get the aggregated price for a given Perp contract.
     * @param perpAddress The Perp contract address.
     * @return The aggregated price.
     */
    function getPrices(address perpAddress) external view returns (uint256) {
        PriceOracleEntry storage entry = priceOracleEntries[perpAddress];
        require(
            entry.pythPriceId != bytes32(0),
            "PriceOracle: Entry not found"
        );

        uint256 pythPrice = getPythPrice(entry.pythPriceId);
        uint256 chainlinkPrice = getChainlinkPrice(
            entry.chainlinkOracleAddress
        );

        return
            (pythPrice * pythWeight + chainlinkPrice * chainlinkWeight) /
            (pythWeight + chainlinkWeight);
    }

    /**
     * @dev Get the Pyth price for a given Pyth Price ID.
     * @param _pythPriceId The Pyth Price ID.
     * @return The Pyth price.
     */
    function getPythPrice(
        bytes32 _pythPriceId
    ) internal view returns (uint256) {
        PythStructs.Price memory currentBasePrice = pyth.getPrice(_pythPriceId);
        require(currentBasePrice.price > 0, "PriceOracle: Invalid Pyth price");

        // Cast to int256 first before converting to uint256
        int256 signedPrice = currentBasePrice.price;
        return uint256(signedPrice);
    }

    /**
     * @dev Get the Chainlink price for a given Chainlink Oracle Address.
     * @param _chainlinkOracleAddress The Chainlink Oracle Address.
     * @return The Chainlink price.
     */
    function getChainlinkPrice(
        address _chainlinkOracleAddress
    ) internal view returns (uint256) {
        AggregatorV3Interface chainlinkOracle = AggregatorV3Interface(
            _chainlinkOracleAddress
        );
        (, int256 chainlinkPrice, , , ) = chainlinkOracle.latestRoundData();
        require(chainlinkPrice > 0, "PriceOracle: Invalid Chainlink price");
        return uint256(chainlinkPrice);
    }
}
