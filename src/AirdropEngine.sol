// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20, SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
//import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

contract AirdropEngine is EIP712 {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    IERC20 private immutable i_airdropToken;
    bytes32 private immutable i_merkleRoot;
    bytes32 private constant MESSAGE_TYPE_HASH = keccak256("AirdropClaim(address account, uint256 amount)");

    //mappings
    mapping(address => bool) s_hasClaimed;
    //struct

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    //events
    event AirdropClaimed(address account, uint256 amount);

    //erors
    error AirdropEngine__airdropAlreadyClaimed();
    error AirdropEngine__invalidProof();
    error AirdropEngine__inValidSignature();

    constructor(IERC20 _airdropToken, bytes32 _merkleRoot) EIP712("AirdropEngine", "1") {
        i_airdropToken = _airdropToken;
        i_merkleRoot = _merkleRoot;
    }

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s)
        external
    {
        if (s_hasClaimed[account]) {
            revert AirdropEngine__airdropAlreadyClaimed();
        }
        if (!_isValidSignature(account, getMessageHash(account, amount), v, r, s)) {
            revert AirdropEngine__inValidSignature();
        }

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert AirdropEngine__invalidProof();
        }

        s_hasClaimed[account] = true;
        emit AirdropClaimed(account, amount);
        i_airdropToken.safeTransfer(account, amount);
    }

    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        return
            _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPE_HASH, AirdropClaim({account: account, amount: amount}))));
    }

    function getToken() public view returns (IERC20) {
        return i_airdropToken;
    }

    function getMarkelRoot() public view returns (bytes32) {
        return i_merkleRoot;
    }

    function _isValidSignature(address account, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        // (address actualSigner , , ) = ECDSA.tryRecover(digest, v, r, s);
        // return actualSigner == account;

        (address actualSigner, , ) = ECDSA.tryRecover(digest, v, r, s);
        return actualSigner == account;
    }
}
