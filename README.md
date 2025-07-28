# 🦘 KangarooDeFi Smart Contracts

This repository contains the core smart contracts that power [KangarooDeFi](https://kangaroodefi.com), a decentralized prediction market protocol built on Binance Smart Chain (BSC).

## Contracts Included

| Contract               | Description                                                                 |
|------------------------|-----------------------------------------------------------------------------|
| `KangarooRouter`       | Manages prediction rounds, token generation, and round resolution           |
| `UDToken`              | Up/Down tokens representing directional bets in each round                  |
| `KWBNB`                | Wrapped BNB used as collateral across the prediction market                 |
| `KangarooAirdrop`      | ERC20-compatible token used for distributing user rewards                   |

## 🌐 Deployed Addresses (BSC Testnet)

| Contract          | Address                                                      |
|------------------|--------------------------------------------------------------|
| `KangarooRouter` | `0xec2d4a1877c9d149f918bf1b066f1fff71683e3d`                  |
| `KWBNB`          | `0x942199Bf52504487a05f35e39692a78B6Fb98496`                  |
| `KangarooAirdrop`| `0x4b09dFCaC4f29ae3CF23E0Bc9CD5FD49e6A4F279`                  |

> 🔗 These contracts are deployed on **Binance Smart Chain Testnet** and can be verified via [testnet.bscscan.com](https://testnet.bscscan.com).

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
