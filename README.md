# 🦘 KangarooDeFi Smart Contracts

This repository contains the core smart contracts that power [KangarooDeFi](https://kangaroodefi.com), a decentralized prediction market protocol built on Binance Smart Chain (BSC).

## Contracts Included

| Contract               | Description                                                                 |
|------------------------|-----------------------------------------------------------------------------|
| `KangarooRouter`       | Manages prediction rounds, token generation, and round resolution           |
| `UDToken`              | Up/Down tokens representing directional bets in each round                  |
| `KWBNB`                | Wrapped BNB used as collateral across the prediction market                 |
| `KangarooAirdrop`      | ERC20-compatible token used for distributing user rewards                   |

## Features

- 🧠 On-chain prediction logic with automated liquidity pairing via PancakeSwap
- 🔄 Round-based token issuance and reward settlement
- 🎯 Winner/loser evaluation with dynamic reward distribution
- 💰 Collateralized by KWBNB, with airdrop-based incentive mechanisms
- 🔐 Pausable, upgradeable, and security-aware architecture

## Docs

For full documentation: [📖 KangarooDeFi Docs](https://kangaroodefi.gitbook.io)

---

## License

GPL-3.0-or-later
