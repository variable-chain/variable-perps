// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

interface IVariableReferral {
    function updateReferralVolume(
        bytes32 referralCode,
        uint256 volume
    ) external;
    function generateUniqueID(
        address walletAddress,
        bytes32 dexCode,
        bytes32 uniqueKey
    ) external pure returns (bytes32);
    function extractWalletAddress(
        bytes32 uniqueID
    ) external pure returns (address);
    function extractDexCode(bytes32 uniqueID) external pure returns (bytes32);
    function extractUniqueKey(bytes32 uniqueID) external pure returns (bytes32);
}
