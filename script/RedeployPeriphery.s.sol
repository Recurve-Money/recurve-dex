// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/SwapRouter.sol";
import "@uniswap/v3-periphery/contracts/lens/QuoterV2.sol";

interface Vm {
    function startBroadcast(uint256 privateKey) external;
    function stopBroadcast() external;
    function envAddress(string calldata name) external returns (address);
    function envUint(string calldata name) external returns (uint256);
}

/// Router + Quoter only -- the factory and the already-seeded pool don't use
/// PoolAddress's hardcoded init-code-hash for anything, so they don't need
/// touching. Run this only after fixing PoolAddress.sol's constant.
contract RedeployPeriphery {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function run() external {
        address factory = vm.envAddress("DEX_FACTORY");
        address weth = vm.envAddress("VAULT_ASSET");
        uint256 pk = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(pk);
        SwapRouter router = new SwapRouter(factory, weth);
        QuoterV2 quoter = new QuoterV2(factory, weth);
        vm.stopBroadcast();

        router;
        quoter;
    }
}
