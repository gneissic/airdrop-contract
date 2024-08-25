// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DeployAirdrop} from "../script/DeployAirdrop.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {AirdropToken} from "../src/AirdropToken.sol";
import {AirdropEngine} from "../src/AirdropEngine.sol";
import {IERC20, SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ZkSyncChainChecker} from "../lib/foundry-devops/src/ZkSyncChainChecker.sol";

contract AirdropTest is ZkSyncChainChecker, Test {
    AirdropToken public token;
    AirdropEngine public engine;
    address user;
    uint256 userprivKey;
    address gasPayer;
    bytes32 public markelRoot = 0x474d994c58e37b12085fdb7bc6bbcd046cf1907b90de3b7fb083cf3636c8ebfb;
    uint256 public constant userAmountToClaim = 25 * 1e18;
    uint256 public constant amountTokenToSendToEngine = userAmountToClaim * 4;
    bytes32 proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo = 0x46f4c7c1c21e8a90c03949beda51d2d02d1ec75b55dd97a999d3edbafa5a1e2f;
    bytes32[] public proofs = [proofOne, proofTwo];

    using SafeERC20 for IERC20;

    function setUp() external {
        if (!isZkSyncChain()) {
            DeployAirdrop deployer = new DeployAirdrop();
            (engine, token) = deployer.deplpyMerkleAirdrop();
        } else {
            token = new AirdropToken();
            engine = new AirdropEngine(token, markelRoot);
            token.mint(token.owner(), amountTokenToSendToEngine);
            token.transfer(address(engine), amountTokenToSendToEngine);
        }

        (user, userprivKey) = makeAddrAndKey("user");
        gasPayer = makeAddr("gasPayer");
    }

    function signMessage(uint256 privKey, address account) public view returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 hashedMessage = engine.getMessageHash(account, userAmountToClaim);
        (v, r, s) = vm.sign(privKey, hashedMessage);
    }

    function test__UsersCanClaimTokens() public {
        uint256 startingBalance = token.balanceOf(user);

        vm.startPrank(user);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(userprivKey, user);
        vm.stopPrank();
        vm.prank(gasPayer);
        engine.claim(user, userAmountToClaim, proofs, v, r, s);
        uint256 endingBalance = token.balanceOf(user);
        // console.log("endinging balance :", endingBalance);
        assertEq(endingBalance - startingBalance, userAmountToClaim);
    }

    function test__markelRootIsCorrect() public view {
        bytes32 markel = engine.getMarkelRoot();
        assertEq(markelRoot, markel);
    }

    function test__tokenIsCorrect() public view {
        IERC20 engineToken = engine.getToken();
        assertEq(address(token), address(engineToken));
    }
}
