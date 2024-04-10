// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IChainlinkPriceFeedV3} from "../interfaces/IChainlinkPriceFeedV3.sol";
import {IPriceFeed} from "../interfaces/IPriceFeed.sol";
import {IPriceFeedUpdate} from "../interfaces/IPriceFeedUpdate.sol";
import {CachedTwap} from "./twap/CachedTwap.sol";

/**
 * @title ChainlinkPriceFeedV3
 * @dev Chainlink-based Price Feed contract with caching and update functionality.
 */
contract ChainlinkPriceFeedV3 is
    IPriceFeed,
    IChainlinkPriceFeedV3,
    IPriceFeedUpdate,
    CachedTwap
{
    uint8 internal immutable _decimals;
    uint256 internal immutable _timeout;
    uint256 internal _lastValidPrice;
    uint256 internal _lastValidTimestamp;
    AggregatorV3Interface internal immutable _aggregator;

    /**
     * @dev Constructor to initialize the ChainlinkPriceFeedV3 contract.
     * @param aggregator The address of the Chainlink Aggregator contract.
     * @param timeout The timeout period for determining if the price feed is timed out.
     * @param twapInterval The time interval for calculating the Twap.
     */
    constructor(
        AggregatorV3Interface aggregator,
        uint256 timeout,
        uint80 twapInterval
    ) CachedTwap(twapInterval) {
        // CPF_ANC: Aggregator is not contract
        require(isContract(address(aggregator)), "CPF_ANC");
        _aggregator = aggregator;

        _timeout = timeout;
        _decimals = aggregator.decimals();
    }

    /**
     * @dev Updates the price feed by fetching the latest data from the Chainlink Aggregator.
     */
    function update() external override {
        bool isUpdated = _cachePrice();
        // CPF_NU: not updated
        require(isUpdated, "CPF_NU");

        _update(_lastValidPrice, _lastValidTimestamp);
    }

    /**
     * @dev Caches the latest price and updates the Twap for the specified interval.
     * @param interval The time interval for calculating the Twap.
     */
    function cacheTwap(uint256 interval) external override {
        _cachePrice();

        _cacheTwap(interval, _lastValidPrice, _lastValidTimestamp);
    }

    /**
     * @dev Retrieves the last valid price stored in the contract.
     * @return The last valid price.
     */
    function getLastValidPrice() external view override returns (uint256) {
        return _lastValidPrice;
    }

    /**
     * @dev Retrieves the timestamp of the last valid price update.
     * @return The timestamp of the last valid price update.
     */
    function getLastValidTimestamp() external view override returns (uint256) {
        return _lastValidTimestamp;
    }

    /**
     * @dev Retrieves the price for the specified interval, considering Twap if interval is non-zero.
     * @param interval The time interval for calculating the Twap.
     * @return The price for the specified interval.
     */
    function getPrice(
        uint256 interval
    ) external view override returns (uint256) {
        (
            uint256 latestValidPrice,
            uint256 latestValidTime
        ) = _getLatestOrCachedPrice();

        if (interval == 0) {
            return latestValidPrice;
        }

        return _getCachedTwap(interval, latestValidPrice, latestValidTime);
    }

    /**
     * @dev Retrieves the latest or cached price along with the timestamp of the update.
     * @return The latest or cached price and timestamp.
     */
    function getLatestOrCachedPrice()
        external
        view
        override
        returns (uint256, uint256)
    {
        return _getLatestOrCachedPrice();
    }

    /**
     * @dev Checks if the price feed is timed out based on the specified timeout period.
     * @return A boolean indicating whether the price feed is timed out.
     */
    function isTimedOut() external view override returns (bool) {
        // Fetch the latest timestamp instead of _lastValidTimestamp to prevent stale data
        // when the update() doesn't get triggered.
        (, uint256 lastestValidTimestamp) = _getLatestOrCachedPrice();
        return
            lastestValidTimestamp > 0 &&
            lastestValidTimestamp + _timeout < block.timestamp;
    }

    /**
     * @dev Retrieves the reason for freezing the price feed.
     * @return The FreezedReason indicating why the price feed is frozen.
     */
    function getFreezedReason() external view override returns (FreezedReason) {
        ChainlinkResponse memory response = _getChainlinkResponse();
        return _getFreezedReason(response);
    }

    /**
     * @dev Retrieves the address of the Chainlink Aggregator contract.
     * @return The address of the Chainlink Aggregator.
     */
    function getAggregator() external view override returns (address) {
        return address(_aggregator);
    }

    /**
     * @dev Retrieves the timeout period for determining if the price feed is timed out.
     * @return The timeout period.
     */
    function getTimeout() external view override returns (uint256) {
        return _timeout;
    }

    /**
     * @dev Retrieves the decimals of the price feed.
     * @return The decimals.
     */
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    /**
     * @dev Internal function to cache the latest price and update the Twap.
     * @return A boolean indicating whether the price was successfully updated.
     */
    function _cachePrice() internal returns (bool) {
        ChainlinkResponse memory response = _getChainlinkResponse();
        if (_isAlreadyLatestCache(response)) {
            return false;
        }

        bool isUpdated = false;
        FreezedReason freezedReason = _getFreezedReason(response);
        if (_isNotFreezed(freezedReason)) {
            _lastValidPrice = uint256(response.answer);
            _lastValidTimestamp = response.updatedAt;
            isUpdated = true;
        }

        emit ChainlinkPriceUpdated(
            _lastValidPrice,
            _lastValidTimestamp,
            freezedReason
        );
        return isUpdated;
    }

    /**
     * @dev Internal function to retrieve the latest or cached price and timestamp.
     * @return The latest or cached price and timestamp.
     */
    function _getLatestOrCachedPrice()
        internal
        view
        returns (uint256, uint256)
    {
        ChainlinkResponse memory response = _getChainlinkResponse();
        if (_isAlreadyLatestCache(response)) {
            return (_lastValidPrice, _lastValidTimestamp);
        }

        FreezedReason freezedReason = _getFreezedReason(response);
        if (_isNotFreezed(freezedReason)) {
            return (uint256(response.answer), response.updatedAt);
        }

        // if frozen
        return (_lastValidPrice, _lastValidTimestamp);
    }

    function _getChainlinkResponse()
        internal
        view
        returns (ChainlinkResponse memory chainlinkResponse)
    {
        try _aggregator.decimals() returns (uint8 decimals) {
            chainlinkResponse.decimals = decimals;
        } catch {
            // if the call fails, return an empty response with success = false
            return chainlinkResponse;
        }

        try _aggregator.latestRoundData() returns (
            uint80 roundId,
            int256 answer,
            uint256, // startedAt
            uint256 updatedAt,
            uint80 // answeredInRound
        ) {
            chainlinkResponse.roundId = roundId;
            chainlinkResponse.answer = answer;
            chainlinkResponse.updatedAt = updatedAt;
            chainlinkResponse.success = true;
            return chainlinkResponse;
        } catch {
            // if the call fails, return an empty response with success = false
            return chainlinkResponse;
        }
    }

    /**
     * @dev Internal function to check if the response is already the latest cached.
     * @param response The Chainlink response data.
     * @return A boolean indicating whether the response is already the latest cached.
     */
    function _isAlreadyLatestCache(
        ChainlinkResponse memory response
    ) internal view returns (bool) {
        return
            _lastValidTimestamp > 0 &&
            _lastValidTimestamp == response.updatedAt;
    }

    /**
     * @dev Internal function to check if the price feed is not frozen.
     * @param freezedReason The reason for freezing the price feed.
     * @return A boolean indicating whether the price feed is not frozen.
     */
    function _isNotFreezed(
        FreezedReason freezedReason
    ) internal pure returns (bool) {
        return freezedReason == FreezedReason.NotFreezed;
    }

    function _getFreezedReason(
        ChainlinkResponse memory response
    ) internal view returns (FreezedReason) {
        if (!response.success) {
            return FreezedReason.NoResponse;
        }
        if (response.decimals != _decimals) {
            return FreezedReason.IncorrectDecimals;
        }
        if (response.roundId == 0) {
            return FreezedReason.NoRoundId;
        }
        if (
            response.updatedAt == 0 ||
            response.updatedAt < _lastValidTimestamp ||
            response.updatedAt > block.timestamp
        ) {
            return FreezedReason.InvalidTimestamp;
        }
        if (response.answer <= 0) {
            return FreezedReason.NonPositiveAnswer;
        }

        return FreezedReason.NotFreezed;
    }
}
