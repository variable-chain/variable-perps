// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IVariableController.sol";
import "../interfaces/IVariableOrderSettler.sol";

import "../interfaces/IVariablePositionManager.sol";

/**
 * @title VariableVault
 * @dev Smart contract for managing user balances and margin positions in a decentralized trading system.
 */
contract VariableVault is Ownable, ReentrancyGuard {
    uint256 public withdrawCap;

    // Address of the VariableController contract used for controlling market registration.
    IVariableController public variableController;

    IVariableOrderSettler public variableOrderSettler;

    IVariablePositionManager public variablePositionManager;

    // trader -> bytes32(name) -> amount
    mapping(address => mapping(bytes32 => uint256)) public balances;

    mapping(bytes32 => address) public whitelistedTokens;

    event Deposit(address indexed user, bytes32 indexed token, uint256 amount);
    event Withdrawal(
        address indexed user,
        bytes32 indexed token,
        uint256 amount
    );
    event TokenWithdrawnByOwner(
        bytes32 indexed name,
        address indexed token,
        address to,
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
     * @param _variableController The address of the VariableController contract.
     * @param _variableOrderSettler The address of the VariableOrderSettler contract.
     * @param _withdrawCap The maximum withdrawal amount allowed.
     */
    constructor(
        address _initialOwner,
        address _variableController,
        address _variableOrderSettler,
        address _variablePositionManager,
        uint256 _withdrawCap
    ) Ownable(_initialOwner) {
        withdrawCap = _withdrawCap;
        variableController = IVariableController(_variableController);
        variableOrderSettler = IVariableOrderSettler(_variableOrderSettler);
        variablePositionManager = IVariablePositionManager(
            _variablePositionManager
        );
    }

    // Function to update the address for a given token key
    function updateWhitelistedToken(
        bytes32 tokenKey,
        address tokenAddress
    ) public onlyOwner {
        // TODO: auth call by controller
        require(tokenAddress != address(0), "Invalid address"); // Ensure the address is not the zero address
        whitelistedTokens[tokenKey] = tokenAddress;
    }

    // Optional: Function to remove a token from the whitelist
    function removeWhitelistedToken(bytes32 tokenKey) public onlyOwner {
        // TODO: auth call by controller
        delete whitelistedTokens[tokenKey];
    }

    /**
     * @dev Updates the VariableController address. Only callable by the owner.
     * @param newController The new address of the VariableController contract.
     */
    function updateVaultController(
        address newController
    ) external onlyController {
        variableController = IVariableController(newController);
    }

    /**
     * @dev Updates the VariableOrderSettler address. Only callable by the owner.
     * @param newSettler The new address of the VariableOrderSettler contract.
     */
    function updateVariableOrderSettler(
        address newSettler
    ) external onlyController {
        require(newSettler != address(0), "VariableVault: Invalid address");
        variableOrderSettler = IVariableOrderSettler(newSettler);
    }

    /**
     * @dev Updates the withdraw cap. Only callable by the owner.
     * @param newCap The new withdraw cap amount.
     */
    function updateWithdrawCap(uint256 newCap) external onlyController {
        withdrawCap = newCap;
    }

    /**
     * @dev Deposits tokens into the vault.
     * @param tokenName The name (or` identifier) of the token to deposit.
     * @param amount The amount of tokens to deposit.
     */
    function deposit(bytes32 tokenName, uint256 amount) external nonReentrant {
        address tokenAddress = whitelistedTokens[tokenName];
        require(
            tokenAddress != address(0),
            "VariableVault: Token not whitelisted"
        );

        IERC20 token = IERC20(tokenAddress);
        require(amount > 0, "VariableVault: Amount must be greater than 0");
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "VariableVault: Token transfer failed"
        );
        balances[msg.sender][tokenName] += amount;
        emit Deposit(msg.sender, tokenName, amount);
    }
    // TODO: need to check open position before withdraw
    /**
     * @dev Withdraws tokens from the vault.
     * @param trader The address of the trader withdrawing tokens.
     * @param token The bytes32 token to withdraw.
     * @param amount The amount of tokens to withdraw.
     */
    function withdraw(
        address trader,
        bytes32 token,
        uint256 amount
    ) external nonReentrant onlyController {
        // TODO: need to check for opening position
        // TODO: need to create function for collateral
        require(amount > 0, "VariableVault: Amount must be greater than 0");
        require(amount <= withdrawCap, "VariableVault: Cap exceeded");
        require(
            balances[trader][token] >= amount,
            "VariableVault: Insufficient balance"
        );
        address tokenAddress = whitelistedTokens[token];
        require(
            IERC20(tokenAddress).transfer(trader, amount),
            "VariableVault: Token transfer failed"
        );
        balances[trader][token] -= amount;
        emit Withdrawal(trader, token, amount);
    }

    function manageVaultBalance(
        bool increase,
        address user,
        bytes32 assetId,
        uint256 amount
    ) external {
        if (increase) {
            // Update the balance in the mapping
            balances[user][assetId] += amount;
        } else {
            // Update the balance in the mapping
            balances[user][assetId] -= amount;
        }

        // Emit an event for the balance update (optional)
        emit BalanceUpdated(user, assetId, amount);
    }

    // Event declaration for a balance update (optional but recommended for transparency)
    event BalanceUpdated(
        address indexed user,
        bytes32 indexed assetId,
        uint256 newBalance
    );

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
     * @dev Withdraws all balance of a specified token by name to a given address.
     * @param name The bytes32 name of the token.
     * @param to The address to send the token to.
     */
    function withdrawTokenByOwner(
        bytes32 name,
        address to
    ) external onlyController {
        address tokenAddress = whitelistedTokens[name];
        require(tokenAddress != address(0), "VariableVault: Token not found");

        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        require(balance > 0, "VariableVault: No tokens to withdraw");

        require(
            IERC20(tokenAddress).transfer(to, balance),
            "VariableVault: Transfer failed"
        );

        emit TokenWithdrawnByOwner(name, tokenAddress, to, balance);
    }
}
