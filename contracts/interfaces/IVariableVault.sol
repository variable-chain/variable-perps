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

    function updateWithdrawCap(uint256 newCap) external;

    function updateVaultController(address newController) external;

    function updateVariableOrderSettler(address newSettler) external;

    function depositUsdc(address trader, uint256 amount) external;

    function withdraw(address trader, uint256 amount) external;

    function openMarginPosition(uint256 amount, address trader) external;

    function closeMarginPosition(uint256 amount, address trader) external;

    function withdrawRemainingBalance() external;

    function withdrawToken(address to) external;

    function manageVaultBalance(
        bool increase,
        address user,
        bytes32 assetName,
        uint256 amount
    ) external;
}
