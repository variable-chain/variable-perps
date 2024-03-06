// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

library VariableFundingLibrary {
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
        uint256 fundingRate = ((perpPrice - spotPrice) / spotPrice) *
            interestRate *
            timeFactor +
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

        uint256 premComponent = ((perpPrice - spotPrice) / averagePrice) *
            leverageFactor;

        return premComponent;
    }
}
