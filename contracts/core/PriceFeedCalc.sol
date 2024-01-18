// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol';

contract FilteredPriceContract {
    // State variables for Kalman filter
    ABDKMath64x64.uq112x112 public kalmanFilteredPrice;
    ABDKMath64x64.uq112x112 public kalmanVariance = ABDKMath64x64.fromUInt(1);
    ABDKMath64x64.uq112x112 public kalmanQ = ABDKMath64x64.fromUInt(1);

    // State variables for Gaussian filter
    ABDKMath64x64.uq112x112 public gaussianMean;
    ABDKMath64x64.uq112x112 public gaussianVariance = ABDKMath64x64.fromUInt(1);
    ABDKMath64x64.uq112x112 public gaussianR = ABDKMath64x64.fromUInt(25000); // Assuming 0.25 in fixed-point representation

    // Smoothing factor (α) determines the relative weights of Kalman and Gaussian filters
    ABDKMath64x64.uq112x112 public smoothingFactor = ABDKMath64x64.fromUInt(50000); // Assuming 0.5 in fixed-point representation

    // Event to log filtered price updates
    event FilteredPriceUpdated(uint112 newFilteredPrice);

    // Function to update Kalman filter with a new observation
    function updateKalmanFilter(uint112 newObservation) external {
        // Kalman gain
        ABDKMath64x64.uq112x112 kalmanGain = ABDKMath64x64.div(kalmanVariance, ABDKMath64x64.add(kalmanVariance, gaussianR));

        // Update mean and variance
        kalmanFilteredPrice = ABDKMath64x64.add(
            kalmanFilteredPrice,
            ABDKMath64x64.mul(
                kalmanGain,
                ABDKMath64x64.sub(ABDKMath64x64.fromUInt(newObservation), kalmanFilteredPrice)
            )
        );
        kalmanVariance = ABDKMath64x64.add(
            ABDKMath64x64.mul(ABDKMath64x64.sub(ABDKMath64x64.fromUInt(1), kalmanGain), kalmanVariance),
            kalmanQ
        );

        emit FilteredPriceUpdated(uint112(ABDKMath64x64.toUInt(kalmanFilteredPrice)));
    }

    // Function to update Gaussian filter with a new observation
    function updateGaussianFilter(uint112 newObservation) external {
        // Kalman gain for Gaussian filter
        ABDKMath64x64.uq112x112 kalmanGain = ABDKMath64x64.div(gaussianVariance, ABDKMath64x64.add(gaussianVariance, gaussianR));

        // Update mean and variance
        gaussianMean = ABDKMath64x64.add(
            gaussianMean,
            ABDKMath64x64.mul(
                kalmanGain,
                ABDKMath64x64.sub(ABDKMath64x64.fromUInt(newObservation), gaussianMean)
            )
        );
        gaussianVariance = ABDKMath64x64.mul(ABDKMath64x64.sub(ABDKMath64x64.fromUInt(1), kalmanGain), gaussianVariance);

        emit FilteredPriceUpdated(uint112(ABDKMath64x64.toUInt(gaussianMean)));
    }

    // Function to combine Kalman and Gaussian filtered prices
    function calculateFilteredPrice() external view returns (uint112) {
        return uint112(
            ABDKMath64x64.add(
                ABDKMath64x64.mul(ABDKMath64x64.sub(ABDKMath64x64.fromUInt(1), smoothingFactor), kalmanFilteredPrice),
                ABDKMath64x64.mul(smoothingFactor, gaussianMean)
            )
        );
    }
}
