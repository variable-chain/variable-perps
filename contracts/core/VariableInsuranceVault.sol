// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract VariableInsuranceFund is Ownable {
    constructor(address _initialOwner) Ownable(_initialOwner) {}

    // Function to transfer fees to a trader
    function transferFund(
        address to,
        address token,
        uint256 amount
    ) external onlyOwner {
        require(IERC20(token).transfer(to, amount), "Transfer failed");
    }

    function checkTokenBalance(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
}
