// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {AirdropEngine} from "../src/AirdropEngine.sol";
import {AirdropToken} from "../src/AirdropToken.sol";

contract Interact is Script {
    address private constant CLAIMING_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 private constant AMOUNT_TO_CLAIM = 25 * 1e18;
    bytes32 private constant PROOF_ONE = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 private constant PROOF_TWO = 0x46f4c7c1c21e8a90c03949beda51d2d02d1ec75b55dd97a999d3edbafa5a1e2f;
    bytes32[] proof = [PROOF_ONE, PROOF_TWO];
    bytes private SIGNATURE = hex"83065ff1f313055c42b8ab457ecf71546fbace1b200070a26c1958d3b2078c67";
    //  wallet sig  = 0xdb59abec0a6762f7d94e842eecd2b37923d15738fc2b1ed5af728c8361ac0bd3600065688d49bd0a24886a0b77e8e18d4a6753b12ec287ef25181a5585bdbae21b

    error interact__InvalidSignatureLength();

    function claimAirDrop(address airdrop) public {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(SIGNATURE);
        console.log(v);
        vm.startBroadcast();
        AirdropEngine(airdrop).claim(CLAIMING_ACCOUNT, AMOUNT_TO_CLAIM, proof, v, r, s);
        vm.stopBroadcast();
    }

    function run() external {
        // address mostRecentDeployed = DevOpsTools.get_most_recent_deployment("AirdropEngine", block.chainid);
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("AidropEngine", block.chainid);
        claimAirDrop(mostRecentlyDeployed);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        if (sig.length < 65) {
            revert interact__InvalidSignatureLength();
        }
        // assembly{
        //     r:=mload(add(sig, 32))
        //     s:=mload(add(sig, 64))
        //     v := byte(0, mload(add(sig, 96)))
        // }
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}
