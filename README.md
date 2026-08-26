# recurve-dex

A minimal Uniswap V3 deployment for Robinhood Chain testnet (46630): `UniswapV3Factory`,
`SwapRouter`, and `QuoterV2`. Real, unmodified Uniswap source
([v3-core](https://github.com/Uniswap/v3-core) v1.0.0,
[v3-periphery](https://github.com/Uniswap/v3-periphery) v1.3.0) — nothing here is
custom AMM logic.

## Why this exists

`PortfolioStrategy` swaps through `ISwapRouter.exactInputSingle`. No official Uniswap V3
deployment is documented for Robinhood Chain testnet (only mainnet, chain 4663, is —
see [Uniswap's deployments page](https://developers.uniswap.org/docs/protocols/v3/deployments/v3-robinhood-chain-deployments)).
So this deploys the same stack ourselves, on testnet only, to unblock strategy testing.

No `NonfungiblePositionManager` — it pulls in NFT-rendering dependencies
(`base64-sol`, `@uniswap/v2-core`) unrelated to swapping. Liquidity gets added with a
direct `pool.mint()` call instead (`script/SeedPool.s.sol`).

## Deploy

```bash
git submodule update --init --recursive
export PATH="$PATH:$HOME/.foundry/bin"
export VAULT_ASSET=0x7943e237c7F95DA44E0301572D358911207852Fa  # testnet WETH
forge script script/DeployDex.s.sol --rpc-url https://rpc.testnet.chain.robinhood.com --broadcast
```
