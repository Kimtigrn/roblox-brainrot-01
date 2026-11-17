# roblox-brainrot-01

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/Kimtigrn/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/Kimtigrn/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

Brainrot Base Battles — a 3D Roblox brainrot game of your own, inspired by Steal a Brainrot and the genre's hits, built by your coding agent in Roblox Studio and published as a Public experience with its own icon and thumbnail. A central conveyor belt walks absurd meme-born brainrots past four player bases: buy one off the belt, place it on your base, and it earns money every second at its own rate. Climb the ladder of rarities (Common to Brainrot God), chase Golden and Rainbow mutations, upgrade your best earners, rebirth for a permanent bonus — and lock your base before another player steals your best one. Built by an AI agent for make.fun's "Make the best AI Roblox brainrot game" bounty, $1,000 in USDC.

## Run it

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

---

<sub>Entered on [make.fun](https://make.fun/?ref=&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>

## The game

- `main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output`, leaving out every name that starts with a dot (such as `.gitkeep` or `.DS_Store`, which fail an entry), and writes `/output/dossier.json` with `vendor/makefun-roblox.ts`, the kit's copy, unchanged. It first fails fast with a plain message when the place, the link file, or 3–4 screenshots inside the 256 KiB cap are missing.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`; `screenshots/` holds three images of it; `PLAY.json` names the published place once the experience is Public (the account can publish from 2026-11-19, two days after it was made).
- `src/shared/BrainrotData.luau` holds the cast (ten original brainrots), the rarity ladder, mutations and every economy number, so the server and the client always agree.
- `src/server/` runs the game: `BeltService` walks brainrots down the conveyor and sells them, `BaseService` owns the bases, slots, locks, stealing, upgrades and rebirths, `EconomyService` pays one second of income at a time, `PlayerState` keeps each player's money, rebirths and base in one place, and `init.server.luau` wires the remotes.
- `src/client/` shows it: `Hud.luau` builds the ScreenGui (money, income, your brainrots, next tier, lock and rebirth) and `Game.client.luau` passes messages both ways.
- One of the screenshots is also the game's first thumbnail on Roblox: the same picture, uploaded on the Creator Dashboard with the game's icon.
- `TOUR.json` is the optional tour: for each screenshot, the keys that bring the game to that screen.
