// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

interface IPriceFeedUpdate {
    /// @dev Update latest price.
    function update() external;
}
