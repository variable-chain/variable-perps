// // SPDX-License-Identifier: MIT
// pragma solidity =0.8.20;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "./VariableLedger.sol";

// contract VariableLedgerFactory is Ownable {
//     mapping(address)
//     event VariableLedgerCreated(
//         address indexed variableLedger
//     );

//     constructor(address _initialOwner) Ownable(_initialOwner) {}

//     function createVariableLedger(
//         address _baseToken,
//         address _quoteToken,
//         address _variableVault,
//         uint256 _interestRate
//     ) external onlyOwner returns (address) {
//         VariableLedger newVariableLedger = new VariableLedger(
//             msg.sender,
//             _baseToken,
//             _quoteToken,
//             _variableVault,
//             _interestRate
//         );

//         emit VariableLedgerCreated(address(newVariableLedger));

//         return address(newVariableLedger);
//     }
// }
