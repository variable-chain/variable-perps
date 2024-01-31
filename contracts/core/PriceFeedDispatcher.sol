// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IPriceFeed} from "../interfaces/IPriceFeed.sol";
import {IPriceFeedDispatcher} from "../interfaces/IPriceFeedDispatcher.sol";
import {ChainlinkPriceFeedV3} from "./ChainlinkPriceFeedV3.sol";

/**
 * @title PriceFeedDispatcher
 * @dev Contract to dispatch and retrieve price information using ChainlinkPriceFeedV3.
 */
contract PriceFeedDispatcher is IPriceFeed, IPriceFeedDispatcher, Ownable {
    uint8 private constant _DECIMALS = 18;

    Status internal _status = Status.Chainlink;
    ChainlinkPriceFeedV3 internal immutable _chainlinkPriceFeedV3;

    /**
     * @dev Constructor to initialize the PriceFeedDispatcher contract.
     * @param chainlinkPriceFeedV3 The address of the ChainlinkPriceFeedV3 contract.
     * @param owner The owner address.
     */
    constructor(address chainlinkPriceFeedV3, address owner) Ownable(owner) {
        // PFD: CNC: ChainlinkPriceFeed is not contract
        require(isContract(chainlinkPriceFeedV3), "PFD: CNC");

        _chainlinkPriceFeedV3 = ChainlinkPriceFeedV3(chainlinkPriceFeedV3);
    }

    /**
     * @dev Dispatches the price for the specified interval using ChainlinkPriceFeedV3.
     * @param interval The time interval for calculating the Twap.
     */
    function dispatchPrice(uint256 interval) external override {
        _chainlinkPriceFeedV3.cacheTwap(interval);
    }

    /**
     * @dev Retrieves the dispatched price for the specified interval.
     * @param interval The time interval for calculating the Twap.
     * @return The dispatched price.
     */
    function getPrice(
        uint256 interval
    ) external view override returns (uint256) {
        return getDispatchedPrice(interval);
    }

    function getChainlinkPriceFeedV3()
        external
        view
        override
        returns (address)
    {
        return address(_chainlinkPriceFeedV3);
    }

    function decimals()
        external
        pure
        override(IPriceFeed, IPriceFeedDispatcher)
        returns (uint8)
    {
        return _DECIMALS;
    }

    function getDispatchedPrice(
        uint256 interval
    ) public view override returns (uint256) {
        return
            _formatFromDecimalsToX10_18(
                _chainlinkPriceFeedV3.getPrice(interval),
                _chainlinkPriceFeedV3.decimals()
            );
    }

    function _formatFromDecimalsToX10_18(
        uint256 value,
        uint8 fromDecimals
    ) internal pure returns (uint256) {
        uint8 toDecimals = _DECIMALS;

        if (fromDecimals == toDecimals) {
            return value;
        }

        return
            fromDecimals > toDecimals
                ? value / (10 ** (fromDecimals - toDecimals))
                : value * (10 ** (toDecimals - fromDecimals));
    }

    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}
