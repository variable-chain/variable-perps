// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

interface IPriceFeedDispatcherEvent {
    enum Status {
        Chainlink,
        UniswapV3
    }
    event StatusUpdated(Status status);
    event UniswapV3PriceFeedUpdated(address uniswapV3PriceFeed);
}

interface IPriceFeedDispatcher is IPriceFeedDispatcherEvent {
    function dispatchPrice(uint256 interval) external;

    function getDispatchedPrice(
        uint256 interval
    ) external view returns (uint256);

    function getChainlinkPriceFeedV3() external view returns (address);

    function decimals() external pure returns (uint8);
}
