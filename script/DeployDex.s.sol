// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "forge-std/Script.sol";
import "@uniswap/v3-core/contracts/UniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/SwapRouter.sol";
import "@uniswap/v3-periphery/contracts/lens/QuoterV2.sol";

/// Deploys the minimal Uniswap V3 stack a strategy needs to actually swap:
/// a factory to hold pools, a router to swap through, a quoter to price a
/// swap before proposing it. No NonfungiblePositionManager -- liquidity gets
/// added with a direct pool.mint() call instead (see SeedPool.s.sol), which
/// skips pulling in the NFT-rendering dependencies periphery needs for that
/// contract and has nothing to do with swapping.
contract DeployDex is Script {
    function run() external {
        address weth = vm.envAddress("VAULT_ASSET"); // testnet WETH, already deployed

        vm.startBroadcast();

        UniswapV3Factory factory = new UniswapV3Factory();
        SwapRouter router = new SwapRouter(address(factory), weth);
        QuoterV2 quoter = new QuoterV2(address(factory), weth);

        vm.stopBroadcast();

        console.log("UniswapV3Factory", address(factory));
        console.log("SwapRouter", address(router));
        console.log("QuoterV2", address(quoter));
    }
}
