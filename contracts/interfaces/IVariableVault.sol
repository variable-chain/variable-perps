// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVariableVault {
    function usdcToken() external view returns (address);

    function balances(address) external view returns (uint256, uint256);

    function perpMarginBalances(
        address,
        address
    ) external view returns (uint256);

    function depositUsdc(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function openMarginPosition(
        uint256 amount,
        address trader,
        address perpMargin
    ) external;

    function closeMarginPosition(
        uint256 amount,
        address trader,
        address perpMargin
    ) external;

    function withdrawRemainingBalance() external;

    function withdrawToken(address to) external;
}
