// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IVariableController.sol";
import "../interfaces/IVariableOrderSettler.sol";

/**
 * @title VariableVault
 * @dev Smart contract for managing user balances and margin positions in a decentralized trading system.
 */
contract VariableVault is Ownable, ReentrancyGuard {
    uint256 public withdrawCap;
    address public immutable usdcToken;

    // Address of the VariableController contract used for controlling market registration.
    IVariableController public variableController;

    IVariableOrderSettler public variableOrderSettler;

    struct BalanceInfo {
        uint256 availableAmount;
        uint256 lockedAmount;
    }

    mapping(address => BalanceInfo) public balances;

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdrawal(
        address indexed user,
        address indexed token,
        uint256 amount
    );

    /**
     * @dev Modifier to restrict functions to be callable only by the controller.
     */
    modifier onlyController() {
        require(
            msg.sender == address(variableController),
            "VariableVault: Not authorized"
        );
        _;
    }

    /**
     * @dev Modifier to restrict functions to be callable only by the order settler.
     */
    modifier onlyOrderSettler() {
        require(
            msg.sender == address(variableOrderSettler),
            "VariableVault: Not authorized"
        );
        _;
    }

    /**
     * @dev Constructor to initialize the contract.
     * @param _initialOwner The initial owner of the contract.
     * @param _usdcToken The address of the USDC token contract.
     * @param _variableController The address of the VariableController contract.
     * @param _variableOrderSettler The address of the VariableOrderSettler contract.
     * @param _withdrawCap The maximum withdrawal amount allowed.
     */
    constructor(
        address _initialOwner,
        address _usdcToken,
        address _variableController,
        address _variableOrderSettler,
        uint256 _withdrawCap
    ) Ownable(_initialOwner) {
        usdcToken = _usdcToken;
        withdrawCap = _withdrawCap;
        variableController = IVariableController(_variableController);
        variableOrderSettler = IVariableOrderSettler(_variableOrderSettler);
    }

    /**
     * @dev Updates the VariableController address. Only callable by the owner.
     * @param newController The new address of the VariableController contract.
     */
    function updateVariableController(
        address newController
    ) external onlyOwner {
        require(newController != address(0), "VariableVault: Invalid address");
        variableController = IVariableController(newController);
    }

    /**
     * @dev Updates the VariableOrderSettler address. Only callable by the owner.
     * @param newSettler The new address of the VariableOrderSettler contract.
     */
    function updateVariableOrderSettler(address newSettler) external onlyOwner {
        require(newSettler != address(0), "VariableVault: Invalid address");
        variableOrderSettler = IVariableOrderSettler(newSettler);
    }

    /**
     * @dev Updates the withdraw cap. Only callable by the owner.
     * @param newCap The new withdraw cap amount.
     */
    function updateWithdrawCap(uint256 newCap) external onlyOwner {
        require(newCap != 0, "VariableVault: Invalid withdrawal amount");
        withdrawCap = newCap;
    }

    /**
     * @dev Deposits USDC tokens into the vault.
     * @param amount The amount of USDC tokens to deposit.
     */
    function depositUsdc(uint256 amount) public nonReentrant {
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

    /**
     * @dev Withdraws USDC tokens from the vault.
     * @param amount The amount of USDC tokens to withdraw.
     */
    function withdraw(uint256 amount) external nonReentrant {
        require(amount <= withdrawCap, "VariableVault: Cap exceeded");
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

    /**
     * @dev Opens a margin position for a trader.
     * @param amount The amount of USDC tokens to lock.
     * @param trader The address of the trader.
     */
    function openMarginPosition(
        uint256 amount,
        address trader
    ) external onlyOrderSettler {
        require(amount > 0, "VariableVault: Invalid amount");
        BalanceInfo storage balanceInfo = balances[trader];
        balanceInfo.lockedAmount += amount;
        balanceInfo.availableAmount -= amount;
    }

    /**
     * @dev Closes a margin position for a trader.
     * @param amount The amount of USDC tokens to unlock.
     * @param trader The address of the trader.
     */
    function closeMarginPosition(
        uint256 amount,
        address trader
    ) external onlyOrderSettler {
        require(amount > 0, "VariableVault: Invalid amount");
        BalanceInfo storage balanceInfo = balances[trader];
        balanceInfo.lockedAmount -= amount;
        balanceInfo.availableAmount += amount;
    }

    /**
     * @dev Withdraws any remaining ETH balance to the owner.
     */
    function withdrawRemainingBalance() external onlyController {
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            payable(owner()).transfer(ethBalance);
        }
    }

    /**
     * @dev Withdraws any remaining USDC token balance to the owner.
     * @param to The address to withdraw the tokens to.
     */
    function withdrawToken(address to) external onlyController {
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
