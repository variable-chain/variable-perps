// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

interface IVariablePositionManager {
    function updateVariableOrderSettler(address newSettler) external;
    function updatePositionController(address newController) external;
    function updatePosition(
        bytes32 perpMarketId,
        bytes32 positionId,
        address trader,
        uint256 positionSize,
        uint256 leverageRatio,
        uint256 fees
    ) external;
}
