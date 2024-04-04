// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

interface IVariablePositionManager {
    function updateVariableOrderSettler(address newSettler) external;
    function updatePositionController(address newController) external;
    function updatePosition(
        bool isAddPosition,
        bytes32 perpMarketId,
        bytes32 positionId,
        address trader,
        uint256 allocatedCollateral,
        uint256 positionSize,
        uint256 leverageRatio,
        uint256 fees
    ) external;
    function adjustMargin(
        bytes32 positionId,
        uint256 amount,
        address trader,
        bool increase
    ) external;
}
