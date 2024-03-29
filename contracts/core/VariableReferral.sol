// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

contract VariableReferral {
    // referralCode -> DEX -> volume(positionSize)
    mapping(bytes32 => mapping(bytes32 => uint256))
        public referralVolumeTracker;
    constructor() {}

    // Update referral volume for a specific referral code and volume
    function updateReferralVolume(bytes32 referralCode, uint256 volume) public {
        bytes32 dexCode = extractDexCode(referralCode);
        referralVolumeTracker[referralCode][dexCode] += volume;
    }
    function generateUniqueID(
        address walletAddress,
        bytes32 dexCode,
        bytes32 uniqueKey
    ) public pure returns (bytes32) {
        bytes memory prefix = abi.encodePacked(
            walletAddress,
            dexCode,
            uniqueKey
        );
        bytes32 uniqueID = keccak256(prefix);
        return uniqueID;
    }

    function extractWalletAddress(
        bytes32 uniqueID
    ) public pure returns (address) {
        return address(uint160(uint256(uniqueID)));
    }

    function extractDexCode(bytes32 uniqueID) public pure returns (bytes32) {
        bytes32 dexCode;
        assembly {
            dexCode := mload(add(uniqueID, 20))
        }
        return dexCode;
    }

    function extractUniqueKey(bytes32 uniqueID) public pure returns (bytes32) {
        bytes32 uniqueKey;
        assembly {
            uniqueKey := mload(add(uniqueID, 52))
        }
        return uniqueKey;
    }
}
