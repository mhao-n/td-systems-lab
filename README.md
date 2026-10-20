# Tower-Defense Systems Lab

A standalone Lua 5.4 demonstration of progression, loot, and quest systems from my Roblox game. This is a simplified, demo-adapted version of code I am currently using in the game, with sample data and small replacements for Roblox APIs so the core logic can run on its own.

## Role in my game

These systems support the tower-defense progression loop: scaling combat power across rarity tiers, choosing rewards from weighted loot tables, and generating repeatable objectives for players.

- **Rarity scaling:** calculates an exponential base damage-per-second curve across six rarity tiers, providing a consistent starting point for combat balance.
- **Weighted loot:** filters items by rarity, allocates probability across units, traps, and blocks, and weights individual items using gameplay cost factors such as utility and health. The probabilities are normalized to sum to one.
- **Daily and weekly quests:** uses a period-based seed to generate repeatable quest selections, targets, and rewards. Targets are derived from wave data such as enemy count, health, currency, and score, connecting objectives to gameplay workload.
- **Balance checks:** compares expected loot probabilities with the results of 100,000 simulated rolls.

## What this demo includes

`demo.lua` prints the rarity power curve, a sample Rare loot table, a Monte Carlo comparison, and a deterministic set of daily quests. The quest generator also supports weekly settings. This repository isolates the underlying calculations rather than providing the complete game, its assets, or its runtime integration.

## Run

```bash
lua demo.lua
```

Requires Lua 5.4. No Roblox Studio, Rojo, or third-party library is required. See [LUA_EQUIVALENTS.md](LUA_EQUIVALENTS.md) for the small replacements used for Roblox APIs.