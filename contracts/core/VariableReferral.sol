// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

/**
 * @title VariableReferral
 * @dev A contract for tracking referral volumes for different DEX codes and referral codes.
 */
contract VariableReferral {
    // referralCode -> DEX -> volume(positionSize)
    mapping(bytes32 => mapping(bytes32 => uint256))
        public referralVolumeTracker;

    /**
     * @dev Constructor function.
     */
    constructor() {}

    /**
     * @dev Updates the referral volume for a specific referral code and volume.
     * @param referralCode The referral code.
     * @param volume The volume (position size) to update.
     */
    function updateReferralVolume(bytes32 referralCode, uint256 volume) public {
        bytes32 dexCode = extractDexCode(referralCode);
        referralVolumeTracker[referralCode][dexCode] += volume;
    }

    /**
     * @dev Generates a unique ID based on wallet address, DEX code, and unique key.
     * @param walletAddress The wallet address.
     * @param dexCode The DEX code.
     * @param uniqueKey The unique key.
     * @return uniqueID The generated unique ID.
     */
    function generateUniqueID(
        address walletAddress,
        bytes32 dexCode,
        bytes32 uniqueKey
    ) public pure returns (bytes32 uniqueID) {
        bytes memory prefix = abi.encodePacked(
            walletAddress,
            dexCode,
            uniqueKey
        );
        uniqueID = keccak256(prefix);
    }

    /**
     * @dev Extracts the wallet address from a unique ID.
     * @param uniqueID The unique ID.
     * @return address The wallet address extracted from the unique ID.
     */
    function extractWalletAddress(
        bytes32 uniqueID
    ) public pure returns (address) {
        return address(uint160(uint256(uniqueID)));
    }

    /**
     * @dev Extracts the DEX code from a unique ID.
     * @param uniqueID The unique ID.
     * @return dexCode The DEX code extracted from the unique ID.
     */
    function extractDexCode(
        bytes32 uniqueID
    ) public pure returns (bytes32 dexCode) {
        assembly {
            dexCode := mload(add(uniqueID, 20))
        }
    }

    /**
     * @dev Extracts the unique key from a unique ID.
     * @param uniqueID The unique ID.
     * @return uniqueKey The unique key extracted from the unique ID.
     */
    function extractUniqueKey(
        bytes32 uniqueID
    ) public pure returns (bytes32 uniqueKey) {
        assembly {
            uniqueKey := mload(add(uniqueID, 52))
        }
    }
}
