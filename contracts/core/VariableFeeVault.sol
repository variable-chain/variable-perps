// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract VariableFeeVault is Ownable {
    // Event declarations for logging activities
    event FeesDistributed(
        address indexed token,
        address[] recipients,
        uint256[] amounts
    );

    constructor(address _initialOwner) Ownable(_initialOwner) {}

    function transferFee(
        address to,
        address token,
        uint256 amount
    ) external onlyOwner {
        require(IERC20(token).transfer(to, amount), "Transfer failed");
    }

    function bulkTransfer(
        address token,
        address[] memory recipients,
        uint256[] memory amounts
    ) external onlyOwner {
        require(
            recipients.length == amounts.length,
            "Recipients and amounts do not match"
        );

        for (uint i = 0; i < recipients.length; i++) {
            require(
                IERC20(token).transfer(recipients[i], amounts[i]),
                "Transfer failed"
            );
        }

        emit FeesDistributed(token, recipients, amounts);
    }

    function checkTokenBalance(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
}
