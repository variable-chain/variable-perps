// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract VariableVault is Ownable, ReentrancyGuard {
    address public immutable usdcToken;

    struct BalanceInfo {
        uint256 availableAmount;
        uint256 lockedAmount;
    }
    mapping(address => BalanceInfo) public balances;

    mapping(address => mapping(address => uint256)) public perpMarginBalances;

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdrawal(
        address indexed user,
        address indexed token,
        uint256 amount
    );

    constructor(
        address _initialOwner,
        address _usdcToken
    ) Ownable(_initialOwner) {
        usdcToken = _usdcToken;
    }

    // Function to receive native ETH
    receive() external payable {}

    // Deposit and Withdraw ERC-20 token
    function depositUsdc(uint256 amount) external nonReentrant {
        BalanceInfo storage balanceInfo = balances[msg.sender];
        require(amount > 0, "VariableVault: Amount must be greater than 0");

        IERC20 token = IERC20(usdcToken);
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "VariableVault: Token transfer failed"
        );
        balanceInfo.availableAmount += amount;
        emit Deposit(msg.sender, usdcToken, amount);
    }

    // Withdraw native ETH or ERC-20 token
    function withdraw(uint256 amount) external nonReentrant {
        BalanceInfo storage balanceInfo = balances[msg.sender];
        require(
            amount > 0 && amount <= balanceInfo.availableAmount,
            "VariableVault: Invalid withdrawal amount"
        );
        require(
            IERC20(usdcToken).transfer(msg.sender, amount),
            "VariableVault: Token transfer failed"
        );
        balanceInfo.availableAmount -= amount;

        emit Withdrawal(msg.sender, usdcToken, amount);
    }

    // called by perp margin contract
    function openMarginPosition(
        uint256 amount,
        address trader,
        address perpMargin
    ) external {
        require(msg.sender == perpMargin, "VariableVault: Unauthorized Access");
        require(amount > 0, "VariableVault: Invalid amount");
        BalanceInfo storage balanceInfo = balances[trader];
        perpMarginBalances[trader][perpMargin] += amount;
        balanceInfo.lockedAmount += amount;
        balanceInfo.availableAmount -= amount;
    }

    // called by perp margin contract
    function closeMarginPosition(
        uint256 amount,
        address trader,
        address perpMargin
    ) external {
        require(msg.sender == perpMargin, "VariableVault: Unauthorized Access");
        require(amount > 0, "VariableVault: Invalid amount");
        BalanceInfo storage balanceInfo = balances[trader];
        perpMarginBalances[trader][perpMargin] -= amount;
        balanceInfo.lockedAmount -= amount;
        balanceInfo.availableAmount += amount;
    }

    // Owner can withdraw any remaining balance
    function withdrawRemainingBalance() external onlyOwner {
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            payable(owner()).transfer(ethBalance);
        }
    }

    // Utility function to withdraw tokens
    function withdrawToken(address to) external onlyOwner {
        uint256 tokenBalance = IERC20(usdcToken).balanceOf(address(this));
        if (tokenBalance > 0) {
            IERC20 token = IERC20(usdcToken);
            require(
                token.transfer(to, tokenBalance),
                "VariableVault: Token transfer failed"
            );
        }
    }
}
