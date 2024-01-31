// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

/**
 * @title CumulativeTwap
 * @dev Contract to calculate Cumulative Time-Weighted Average Price (Twap) based on price observations.
 */
contract CumulativeTwap {
    struct Observation {
        uint256 price;
        uint256 priceCumulative;
        uint256 timestamp;
    }

    uint16 public currentObservationIndex;
    uint16 internal constant MAX_OBSERVATION = 1800;
    // stores observation for 1800 slots
    Observation[MAX_OBSERVATION] public observations;

    /**
     * @dev Updates the price observations.
     * @param price The latest observed price.
     * @param lastUpdatedTimestamp The timestamp when the price was last updated.
     * @return A boolean indicating whether the update was successful.
     */
    function _update(
        uint256 price,
        uint256 lastUpdatedTimestamp
    ) internal returns (bool) {
        // for the first time updating
        if (currentObservationIndex == 0 && observations[0].timestamp == 0) {
            observations[0] = Observation({
                price: price,
                priceCumulative: 0,
                timestamp: lastUpdatedTimestamp
            });
            return true;
        }

        Observation memory lastObservation = observations[
            currentObservationIndex
        ];

        // CT: IT: invalid timestamp
        require(lastUpdatedTimestamp >= lastObservation.timestamp, "CT: IT");

        // DO NOT accept same timestamp and different price
        // CT: IPWU: invalid price when update
        if (lastUpdatedTimestamp == lastObservation.timestamp) {
            require(price == lastObservation.price, "CT: IPWU");
        }

        // if the price remains still, there's no need for update
        if (price == lastObservation.price) {
            return false;
        }

        // ring buffer index, make sure the currentObservationIndex is less than MAX_OBSERVATION
        currentObservationIndex =
            (currentObservationIndex + 1) %
            MAX_OBSERVATION;

        uint256 timestampDiff = lastUpdatedTimestamp -
            lastObservation.timestamp;
        observations[currentObservationIndex] = Observation({
            priceCumulative: lastObservation.priceCumulative +
                (lastObservation.price * timestampDiff),
            timestamp: lastUpdatedTimestamp,
            price: price
        });
        return true;
    }

    /**
     * @dev Calculates the Cumulative Twap for a given time interval.
     * @param interval The time interval for calculating the Twap.
     * @param price The latest observed price.
     * @param latestUpdatedTimestamp The timestamp when the price was last updated.
     * @return The Cumulative Twap value.
     */
    function _calculateTwap(
        uint256 interval,
        uint256 price,
        uint256 latestUpdatedTimestamp
    ) internal view returns (uint256) {
        // for the first time calculating
        if (
            (currentObservationIndex == 0 && observations[0].timestamp == 0) ||
            interval == 0
        ) {
            return 0;
        }

        Observation memory latestObservation = observations[
            currentObservationIndex
        ];

        // DO NOT accept same timestamp and different price
        // CT: IPWCT: invalid price when calculating twap
        // it's to be consistent with the logic of _update
        if (latestObservation.timestamp == latestUpdatedTimestamp) {
            require(price == latestObservation.price, "CT: IPWCT");
        }

        uint256 currentTimestamp = block.timestamp;
        uint256 targetTimestamp = currentTimestamp - interval;
        uint256 currentCumulativePrice = latestObservation.priceCumulative +
            (latestObservation.price *
                latestUpdatedTimestamp -
                latestObservation.timestamp) +
            price *
            (currentTimestamp - latestUpdatedTimestamp);

        (
            Observation memory beforeOrAt,
            Observation memory atOrAfter
        ) = _getSurroundingObservations(targetTimestamp);
        uint256 targetCumulativePrice;

        // case1. left boundary
        if (targetTimestamp == beforeOrAt.timestamp) {
            targetCumulativePrice = beforeOrAt.priceCumulative;
        }
        // case2. right boundary
        else if (atOrAfter.timestamp == targetTimestamp) {
            targetCumulativePrice = atOrAfter.priceCumulative;
        }
        // not enough historical data
        else if (beforeOrAt.timestamp == atOrAfter.timestamp) {
            return 0;
        }
        // case3. in the middle
        else {
            // atOrAfter.timestamp == 0 implies beforeOrAt = observations[currentObservationIndex]
            // which means there's no atOrAfter from _getSurroundingObservations
            // and atOrAfter.priceCumulative should eaual to targetCumulativePrice
            if (atOrAfter.timestamp == 0) {
                targetCumulativePrice =
                    beforeOrAt.priceCumulative +
                    (beforeOrAt.price *
                        (targetTimestamp - beforeOrAt.timestamp));
            } else {
                uint256 targetTimeDelta = targetTimestamp -
                    beforeOrAt.timestamp;
                uint256 observationTimeDelta = atOrAfter.timestamp -
                    beforeOrAt.timestamp;

                targetCumulativePrice =
                    beforeOrAt.priceCumulative +
                    (((atOrAfter.priceCumulative - beforeOrAt.priceCumulative) *
                        targetTimeDelta) / observationTimeDelta);
            }
        }

        return currentCumulativePrice - (targetCumulativePrice) / interval;
    }

    /**
     * @dev Retrieves the surrounding observations for a given target timestamp.
     * @param targetTimestamp The target timestamp for which observations are retrieved.
     * @return beforeOrAt The observation before or at the target timestamp.
     * @return atOrAfter The observation at or after the target timestamp.
     */
    function _getSurroundingObservations(
        uint256 targetTimestamp
    )
        internal
        view
        returns (Observation memory beforeOrAt, Observation memory atOrAfter)
    {
        beforeOrAt = observations[currentObservationIndex];

        // if the target is chronologically at or after the newest observation, we can early return
        if (
            observations[currentObservationIndex].timestamp <= targetTimestamp
        ) {
            // if the observation is the same as the targetTimestamp
            // atOrAfter doesn't matter
            // if the observation is less than the targetTimestamp
            // simply return empty atOrAfter
            // atOrAfter repesents latest price and timestamp
            return (beforeOrAt, atOrAfter);
        }

        // now, set before to the oldest observation
        beforeOrAt = observations[
            (currentObservationIndex + 1) % MAX_OBSERVATION
        ];
        if (beforeOrAt.timestamp == 0) {
            beforeOrAt = observations[0];
        }

        // ensure that the target is chronologically at or after the oldest observation
        // if no enough historical data, simply return two beforeOrAt and return 0 at _calculateTwap
        if (beforeOrAt.timestamp > targetTimestamp) {
            return (beforeOrAt, beforeOrAt);
        }

        return _binarySearch(targetTimestamp);
    }

    /**
     * @dev Performs a binary search to find the observations surrounding a target timestamp.
     * @param targetTimestamp The target timestamp for which observations are retrieved.
     * @return beforeOrAt The observation before or at the target timestamp.
     * @return atOrAfter The observation at or after the target timestamp.
     */
    function _binarySearch(
        uint256 targetTimestamp
    )
        private
        view
        returns (Observation memory beforeOrAt, Observation memory atOrAfter)
    {
        uint256 l = (currentObservationIndex + 1) % MAX_OBSERVATION; // oldest observation
        uint256 r = l + MAX_OBSERVATION - 1; // newest observation
        uint256 i;

        while (true) {
            i = (l + r) / 2;

            beforeOrAt = observations[i % MAX_OBSERVATION];

            // we've landed on an uninitialized observation, keep searching higher (more recently)
            if (beforeOrAt.timestamp == 0) {
                l = i + 1;
                continue;
            }

            atOrAfter = observations[(i + 1) % MAX_OBSERVATION];

            bool targetAtOrAfter = beforeOrAt.timestamp <= targetTimestamp;

            // check if we've found the answer!
            if (targetAtOrAfter && targetTimestamp <= atOrAfter.timestamp)
                break;

            if (!targetAtOrAfter) r = i - 1;
            else l = i + 1;
        }
    }
}
