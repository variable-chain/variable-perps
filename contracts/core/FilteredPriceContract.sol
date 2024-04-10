// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "abdk-libraries-solidity/ABDKMath64x64.sol";

contract FilteredPriceContract {
    using ABDKMath64x64 for int128;

    // State variables for Kalman filter
    int128 public kalmanFilteredPrice;
    int128 public kalmanVariance = ABDKMath64x64.fromUInt(1);
    int128 public kalmanQ = ABDKMath64x64.fromUInt(1);
    int128 public kalmanR = ABDKMath64x64.fromUInt(1);

    // State variables for Gaussian filter
    int128 public gaussianMean;
    int128 public gaussianVariance = ABDKMath64x64.fromUInt(1);
    int128 public gaussianR = ABDKMath64x64.fromUInt(25).div(100); // 0.25 represented as fixed-point

    // Smoothing factor (α) determines the relative weights of Kalman and Gaussian filters
    int128 public smoothingFactor = ABDKMath64x64.fromUInt(5).div(100); // 0.5 represented as fixed-point

    // Event to log filtered price updates
    event FilteredPriceUpdated(int128 newFilteredPrice);

    // Function to update Kalman filter with a new observation
    function updateKalmanFilter(int128 newObservation) external {
        // Kalman gain
        int128 kalmanGain = kalmanVariance.div(kalmanVariance.add(kalmanR));

        // Update mean and variance
        kalmanFilteredPrice = kalmanFilteredPrice.add(
            kalmanGain.mul(newObservation.sub(kalmanFilteredPrice))
        );
        kalmanVariance = ABDKMath64x64
            .fromUInt(1)
            .sub(kalmanGain)
            .mul(kalmanVariance)
            .add(kalmanQ);

        emit FilteredPriceUpdated(kalmanFilteredPrice);
    }

    // Function to update Gaussian filter with a new observation
    function updateGaussianFilter(int128 newObservation) external {
        // Kalman gain for Gaussian filter
        int128 kalmanGain = gaussianVariance.div(
            gaussianVariance.add(gaussianR)
        );

        // Update mean and variance
        gaussianMean = gaussianMean.add(
            kalmanGain.mul(newObservation.sub(gaussianMean))
        );
        gaussianVariance = ABDKMath64x64.fromUInt(1).sub(kalmanGain).mul(
            gaussianVariance
        );

        emit FilteredPriceUpdated(gaussianMean);
    }

    // Function to combine Kalman and Gaussian filtered prices
    function calculateFilteredPrice() external view returns (int128) {
        return (
            smoothingFactor.mul(kalmanFilteredPrice).add(
                ABDKMath64x64.fromUInt(1).sub(smoothingFactor).mul(gaussianMean)
            )
        );
    }
}
