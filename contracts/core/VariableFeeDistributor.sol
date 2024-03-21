// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IVariableFeeDistributor.sol";
import "../interfaces/IVariableController.sol";

contract VariableFeeDistributor is Ownable {
    constructor(address _initialOwner) Ownable(_initialOwner) {}
}
