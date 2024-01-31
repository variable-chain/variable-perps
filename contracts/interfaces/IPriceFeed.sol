// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

interface IPriceFeed {
    function decimals() external view returns (uint8);

    function getPrice(uint256 interval) external view returns (uint256);
}
