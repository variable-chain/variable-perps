// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

interface IPriceOracle {
    function pythWeight() external view returns (uint256);

    function chainlinkWeight() external view returns (uint256);

    function setWeightage(
        uint256 pythWeightage,
        uint256 chainlinkWeightage
    ) external;

    function addPriceOracleEntry(
        bytes32 pythPriceId,
        address chainlinkOracleAddress,
        address perpAddress
    ) external;

    function getPrices(address perpAddress) external view returns (uint256);

    function getPythPrice(bytes32 _pythPriceId) external view returns (uint256);

    function getChainlinkPrice(
        address _chainlinkOracleAddress
    ) external view returns (uint256);
}
