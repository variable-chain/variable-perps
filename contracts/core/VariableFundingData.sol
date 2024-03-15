// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "./libs/VariableFunding.sol";
import "../interfaces/IVariableMarketRegistry.sol";

contract VariableFunding {
    using VariableFundingLibrary for *;

    IVariableMarketRegistry public variableMarketRegistry;

    uint256 private constant TIME_FACTOR = 3300;

    // State variables
    uint256 public interestRate;
    uint256 public timeFactor;

    struct FundingRateData {
        uint256 timestamp;
        uint256 fundingRate;
    }
    // mapping of perp market to funding rate data
    mapping(bytes32 => FundingRateData[24]) public fundingRateHistory;

    event FundingRateCalculated(uint256 fundingRate);

    // Calculate Funding Rate
    function calculateFundingRate(
        bytes32 perpMarketId,
        uint256 perpPrice,
        uint256 spotPrice,
        uint256 averagePrice,
        uint256 leverageFactor
    ) external returns (uint256) {
        require(
            IVariableMarketRegistry(variableMarketRegistry).activePerpMarkets(
                perpMarketId
            ),
            "VariableFunding: Inactive market"
        );
        uint256 fundingRate = VariableFundingLibrary.calculateFundingRate(
            perpPrice,
            spotPrice,
            interestRate,
            timeFactor,
            averagePrice,
            leverageFactor
        );

        // add the funding rate in the history
        addFundingRate(fundingRate, perpMarketId);

        return fundingRate;
    }

    // Set values for the variables
    function setValues(uint256 _interestRate, uint256 _timeFactor) external {
        interestRate = _interestRate;
        timeFactor = _timeFactor;
    }

    // Add funding rate in history
    function addFundingRate(
        uint256 _fundingRate,
        bytes32 perpMarketId
    ) internal {
        uint256 index = fundingRateHistory[perpMarketId].length % 24;

        fundingRateHistory[perpMarketId][index] = FundingRateData(
            block.timestamp,
            _fundingRate
        );
    }
}
