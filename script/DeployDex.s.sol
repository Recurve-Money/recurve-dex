// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/UniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/SwapRouter.sol";
import "@uniswap/v3-periphery/contracts/lens/QuoterV2.sol";

/// forge-std needs solc >=0.8.13, and these Uniswap contracts are pinned to
/// exactly 0.7.6 -- one file cannot compile under both. This declares just
/// the two cheatcodes this script actually needs instead of importing
/// forge-std's Script.sol.
interface Vm {
    function startBroadcast() external;
    function stopBroadcast() external;
    function envAddress(string calldata name) external returns (address);
}

/// Deploys the minimal Uniswap V3 stack a strategy needs to actually swap:
/// a factory to hold pools, a router to swap through, a quoter to price a
/// swap before proposing it. No NonfungiblePositionManager -- liquidity gets
/// added with a direct pool.mint() call instead (see SeedPool.s.sol), which
/// skips pulling in the NFT-rendering dependencies periphery needs for that
/// contract and has nothing to do with swapping.
contract DeployDex {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function run() external {
        address weth = vm.envAddress("VAULT_ASSET"); // testnet WETH, already deployed

        vm.startBroadcast();

        UniswapV3Factory factory = new UniswapV3Factory();
        SwapRouter router = new SwapRouter(address(factory), weth);
        QuoterV2 quoter = new QuoterV2(address(factory), weth);

        vm.stopBroadcast();

        // solc 0.7.6 has no console.log without forge-std; the addresses are
        // read from the broadcast JSON (broadcast/DeployDex.s.sol/.../run-latest.json)
        // instead of printed here.
        factory;
        router;
        quoter;
    }
}
