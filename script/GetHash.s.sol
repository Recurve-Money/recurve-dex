// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import "@uniswap/v3-core/contracts/UniswapV3Pool.sol";

interface ConsoleLog {
    function logBytes32(bytes32) external view;
}

contract GetHash {
    ConsoleLog constant console = ConsoleLog(0x000000000000000000636F6e736F6c652e6c6f67);

    function run() external view {
        console.logBytes32(keccak256(type(UniswapV3Pool).creationCode));
    }
}
