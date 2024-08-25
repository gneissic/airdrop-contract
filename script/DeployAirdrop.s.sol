// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AirdropEngine} from "../src/AirdropEngine.sol";
import {console} from "forge-std/Test.sol";
import {AirdropToken} from "../src/AirdropToken.sol";
import {Script} from "forge-std/Script.sol";
import {IERC20, SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract DeployAirdrop is Script {
    using SafeERC20 for IERC20;

    uint256 public amount = 25 * 1e18;
    bytes32 public merkle_root = 0x474d994c58e37b12085fdb7bc6bbcd046cf1907b90de3b7fb083cf3636c8ebfb;

    function deplpyMerkleAirdrop() public returns (AirdropEngine, AirdropToken) {
        vm.startBroadcast();
        AirdropToken token = new AirdropToken();
        AirdropEngine engine = new AirdropEngine(IERC20(token), merkle_root);
        token.mint(token.owner(), amount);
        IERC20(token).transfer(address(engine), amount);
        vm.stopBroadcast();
        return (engine, token);
    }

    function run() external returns (AirdropEngine, AirdropToken) {
        return deplpyMerkleAirdrop();
    }
}
