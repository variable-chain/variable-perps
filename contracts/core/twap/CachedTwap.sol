// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {CumulativeTwap} from "./CumulativeTwap.sol";

/**
 * @title CachedTwap
 * @dev Abstract contract providing caching functionality for Cumulative Time-Weighted Average Price (Twap).
 */
abstract contract CachedTwap is CumulativeTwap {
    uint256 internal _cachedTwap;
    uint160 internal _lastUpdatedAt;
    uint80 internal _interval;

    /**
     * @dev Constructor to set the time interval for the Twap calculations.
     * @param interval The time interval for calculating the Twap.
     */
    constructor(uint80 interval) {
        _interval = interval;
    }

    /**
     * @dev Internal function to cache the Twap based on the provided interval, latest price, and timestamp.
     * @param interval The time interval for calculating the Twap.
     * @param latestPrice The latest observed price.
     * @param latestUpdatedTimestamp The timestamp when the price was last updated.
     * @return The cached Twap value.
     */
    function _cacheTwap(
        uint256 interval,
        uint256 latestPrice,
        uint256 latestUpdatedTimestamp
    ) internal virtual returns (uint256) {
        // always help update price for CumulativeTwap
        _update(latestPrice, latestUpdatedTimestamp);

        // if interval is not the same as _interval, won't update _lastUpdatedAt & _cachedTwap
        // and if interval == 0, return latestPrice directly as there won't be twap
        if (_interval != interval) {
            return
                interval == 0
                    ? latestPrice
                    : _getTwap(interval, latestPrice, latestUpdatedTimestamp);
        }

        // only calculate twap and cache it when there's a new timestamp
        if (block.timestamp != _lastUpdatedAt) {
            _lastUpdatedAt = uint160(block.timestamp);
            _cachedTwap = _getTwap(
                interval,
                latestPrice,
                latestUpdatedTimestamp
            );
        }

        return _cachedTwap;
    }

    /**
     * @dev Internal function to get the cached Twap based on the provided interval, latest price, and timestamp.
     * @param interval The time interval for calculating the Twap.
     * @param latestPrice The latest observed price.
     * @param latestUpdatedTimestamp The timestamp when the price was last updated.
     * @return The cached Twap value.
     */
    function _getCachedTwap(
        uint256 interval,
        uint256 latestPrice,
        uint256 latestUpdatedTimestamp
    ) internal view returns (uint256) {
        if (block.timestamp == _lastUpdatedAt && interval == _interval) {
            return _cachedTwap;
        }
        return _getTwap(interval, latestPrice, latestUpdatedTimestamp);
    }

    /**
     * @dev Internal function to calculate the Twap based on the provided interval, latest price, and timestamp.
     * @param interval The time interval for calculating the Twap.
     * @param latestPrice The latest observed price.
     * @param latestUpdatedTimestamp The timestamp when the price was last updated.
     * @return The calculated Twap value.
     */
    function _getTwap(
        uint256 interval,
        uint256 latestPrice,
        uint256 latestUpdatedTimestamp
    ) internal view returns (uint256) {
        uint256 twap = _calculateTwap(
            interval,
            latestPrice,
            latestUpdatedTimestamp
        );
        return twap == 0 ? latestPrice : twap;
    }
}
