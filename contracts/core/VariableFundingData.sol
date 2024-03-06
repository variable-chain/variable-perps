// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "./libs/VariableFunding.sol";
import "../interfaces/IVariableMarketRegistry.sol";

contract VariableFunding {
    using VariableFundingLibrary for *;

    IVariableMarketRegistry public variableMarketRegistry;

    uint256 private constant TIME_FACTOR = 3300;

    // State variables
    uint256 public perpPrice;
    uint256 public spotPrice;
    uint256 public averagePrice;
    uint256 public leverageFactor;
    uint256 public interestRate;
    uint256 public timeFactor;

    struct FundingRateData {
        uint256 timestamp;
        uint256 fundingRate;
    }
    // mapping of perp market to funding rate data
    mapping(address => FundingRateData[24]) public fundingRateHistory;

    event FundingRateCalculated(uint256 fundingRate);

    // Calculate Funding Rate
    function calculateFundingRate(
        address quoteToken,
        address baseToken
    ) external returns (uint256) {
        uint256 fundingRate = VariableFundingLibrary.calculateFundingRate(
            perpPrice,
            spotPrice,
            interestRate,
            timeFactor,
            averagePrice,
            leverageFactor
        );

        // add the funding rate in the history
        addFundingRate(fundingRate, quoteToken, baseToken);

        return fundingRate;
    }

    // Set values for the variables
    function setValues(
        uint256 _perpPrice,
        uint256 _spotPrice,
        uint256 _averagePrice,
        uint256 _leverageFactor,
        uint256 _interestRate,
        uint256 _timeFactor
    ) external {
        perpPrice = _perpPrice;
        spotPrice = _spotPrice;
        averagePrice = _averagePrice;
        leverageFactor = _leverageFactor;
        interestRate = _interestRate;
        timeFactor = _timeFactor;
    }

    // Add funding rate in history
    function addFundingRate(
        uint256 _fundingRate,
        address _quoteToken,
        address _baseToken
    ) internal {
        address perpMarket = getMarketPair(_quoteToken, _baseToken);

        uint256 index = fundingRateHistory[perpMarket].length % 24;

        fundingRateHistory[perpMarket][index] = FundingRateData(
            block.timestamp,
            _fundingRate
        );
    }

    function getMarketPair(
        address quoteToken,
        address baseToken
    ) internal view returns (address perpMarket) {
        perpMarket = IVariableMarketRegistry(variableMarketRegistry)
            .getPerpLedger(baseToken, quoteToken);
    }
}
