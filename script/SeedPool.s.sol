// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";

interface IERC20Min {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface Vm {
    function startBroadcast(uint256 privateKey) external;
    function stopBroadcast() external;
    function envAddress(string calldata name) external returns (address);
    function envUint(string calldata name) external returns (uint256);
    function addr(uint256 privateKey) external returns (address);
}

/// Creates the WETH/$RECURVE pool (fee 0.3%) and adds a full-range liquidity
/// position, paid for by the caller via transferFrom (approve both tokens to
/// this contract first). No NonfungiblePositionManager -- this is a direct
/// pool.mint(), which needs a contract to receive the mint callback, so the
/// "script" is also the LP position's payer.
contract SeedPool is IUniswapV3MintCallback {
    address public payer;
    address public token0;
    address public token1;

    function uniswapV3MintCallback(uint256 amount0Owed, uint256 amount1Owed, bytes calldata) external override {
        if (amount0Owed > 0) IERC20Min(token0).transferFrom(payer, msg.sender, amount0Owed);
        if (amount1Owed > 0) IERC20Min(token1).transferFrom(payer, msg.sender, amount1Owed);
    }

    /// @param recurvePerWeth how many whole $RECURVE one whole WETH is worth,
    ///        for the pool's *initial* price only -- there is no real market
    ///        for this token yet, so this is a starting point, not a quote.
    function seed(
        address factory,
        address weth,
        address recurve,
        uint24 fee,
        uint256 recurvePerWeth,
        uint256 wethAmount,
        address recipient
    ) external returns (address pool, uint256 amount0, uint256 amount1) {
        require(weth < recurve, "seed() assumes weth is token0; it is not for these addresses");
        token0 = weth;
        token1 = recurve;
        payer = msg.sender;

        pool = IUniswapV3Factory(factory).getPool(token0, token1, fee);
        if (pool == address(0)) pool = IUniswapV3Factory(factory).createPool(token0, token1, fee);

        // price = token1/token0 = RECURVE/WETH = recurvePerWeth (both are 18
        // decimals, so the raw ratio needs no decimal adjustment).
        // sqrtPriceX96 = sqrt(price) * 2^96.
        uint160 sqrtPriceX96 = uint160(sqrt(recurvePerWeth) * 2**96);

        (uint160 existingSqrtPrice, , , , , , ) = IUniswapV3Pool(pool).slot0();
        if (existingSqrtPrice == 0) IUniswapV3Pool(pool).initialize(sqrtPriceX96);

        int24 spacing = IUniswapV3Pool(pool).tickSpacing();
        int24 tickLower = (TickMath.MIN_TICK / spacing) * spacing;
        int24 tickUpper = (TickMath.MAX_TICK / spacing) * spacing;

        uint256 recurveAmount = wethAmount * recurvePerWeth;

        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(tickLower),
            TickMath.getSqrtRatioAtTick(tickUpper),
            wethAmount,
            recurveAmount
        );

        (amount0, amount1) = IUniswapV3Pool(pool).mint(recipient, tickLower, tickUpper, liquidity, "");
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

/// Deploys SeedPool, approves it to pull tokens from the deployer, then seeds
/// a WETH/$RECURVE pool with 1 WETH of full-range liquidity at a starting
/// price of 1,000,000 $RECURVE per WETH -- an arbitrary number, not a quote;
/// there is no market for $RECURVE yet.
contract Seed {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function run() external {
        address factory = vm.envAddress("DEX_FACTORY");
        address weth = vm.envAddress("VAULT_ASSET");
        address recurve = vm.envAddress("REVE_TOKEN");
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);

        uint256 wethAmount = 0.1 ether;
        uint256 recurvePerWeth = 1_000_000;

        vm.startBroadcast(pk);

        // Make sure the deployer actually holds wrapped WETH -- wrapping is
        // idempotent and cheap, and this avoids a silent transferFrom
        // failure if nobody has wrapped any yet.
        IWETH9(weth).deposit{value: wethAmount}();

        SeedPool seeder = new SeedPool();
        IApprove(weth).approve(address(seeder), wethAmount);
        IApprove(recurve).approve(address(seeder), wethAmount * recurvePerWeth);

        seeder.seed(factory, weth, recurve, 3000, recurvePerWeth, wethAmount, deployer);

        vm.stopBroadcast();
    }
}

interface IApprove {
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IWETH9 {
    function deposit() external payable;
}
