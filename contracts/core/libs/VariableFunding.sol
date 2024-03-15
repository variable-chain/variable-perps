// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

library VariableFundingLibrary {
    uint256 private constant DECIMALS = 18;
    uint32 constant FUNDING_PERIOD = 3600 * 8;

    function calculateFundingRate(
        uint256 perpPrice,
        uint256 spotPrice,
        uint256 interestRate,
        uint256 timeFactor,
        uint256 averagePrice,
        uint256 leverageFactor
    ) internal pure returns (uint256) {
        require(
            spotPrice != 0,
            "VariableFundingLibrary: Spot price cannot be zero"
        );

        uint256 premComponent = calculatePremComponent(
            perpPrice,
            spotPrice,
            averagePrice,
            leverageFactor
        );
        uint256 fundingRate = (((perpPrice - spotPrice) * 10 ** DECIMALS) *
            interestRate *
            timeFactor) /
            spotPrice +
            premComponent;

        return fundingRate;
    }

    function calculatePremComponent(
        uint256 perpPrice,
        uint256 spotPrice,
        uint256 averagePrice,
        uint256 leverageFactor
    ) internal pure returns (uint256) {
        require(
            averagePrice != 0,
            "VariableFundingLibrary: Average price cannot be zero"
        );

        uint256 premComponent = (((perpPrice - spotPrice) * 10 ** DECIMALS) *
            leverageFactor) / averagePrice;

        return premComponent;
    }
}
