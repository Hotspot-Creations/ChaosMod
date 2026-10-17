# HSC ChaosMod

**Standalone, server-wide chaos events for FiveM.**

**Developer:** Hotspot Creations  
**Resource:** `ChaosMod`  
**Version:** `1.0.0` (as declared in `fxmanifest.lua`)  
**Game:** FiveM / GTA V  
**Framework:** Standalone (no QBCore or ESX dependency)

HSC ChaosMod introduces unpredictable, synchronized effects to your FiveM server. Effects can change players' vision, alter vehicles and traffic, trigger explosions or weather, spawn objects, teleport players, and much more. A compact NUI display tells everyone when the next event is coming and what effect is currently active.

> **Read this before using it on a live RP server:** The supplied `config.lua` ships with `Config.LiveSafeMode = false` and `Config.AllowDestructiveEffects = true`. By default, destructive effects may be chosen. These effects can alter or damage vehicles, interfere with movement, grant weapons, or move players. Use the safer preset below if you do not want this behavior.

## Features

- **67 registered effects** covering player, vehicle, miscellaneous, and weather categories.
- **Server-wide synchronization:** a single event timer drives the active effect for connected players.
- **Configurable timer:** 120 seconds between event starts by default.
- **Configurable duration:** most timed effects run for 30 seconds by default, with certain effects having their own durations or acting instantly.
- **In-game countdown HUD:** top-of-screen countdown, active effect title and description, progress bar, and brief effect announcement.
- **Admin controls:** list, force, queue, pause, resume, stop, enable, disable, and inspect status.
- **ACE-based permissions:** only authorized administrators (or the server console) can run chaos control commands.
- **Live-safe filter:** restrict both random events and forced events to six preselected visual/audio effects.
- **Additional filters:** remove destructive effects, weather effects, or individual effect IDs from rotation.
- **Performance options:** cap nearby entity processing and spawned entities.
- **Standalone NUI:** no `ox_lib`, `ox_target`, `qb-core`, or ESX requirement.

## Requirements

- A functioning FiveM server supporting the Cerulean resource manifest.
- Server console or access to `server.cfg`.
- Optional: the default FiveM `chat` resource **only if** `Config.UseChatMessages = true`.

## Installation

1. Extract the downloaded resource and keep the original folder structure.
2. Place the **`ChaosMod`** folder inside a server resources directory, for example:

   ```text
   resources/[standalone]/ChaosMod/
   ```

3. Open `ChaosMod/config.lua` and review the effect safety settings.
4. Grant administrators access by adding the following to `server.cfg` (adapt to your existing ACE principals):

   ```cfg
   add_ace group.admin chaosmod.admin allow
   ```

5. Add the resource to `server.cfg`:

   ```cfg
   ensure ChaosMod
   ```

6. Restart the server, or use `ensure ChaosMod` from the server console after installing.
7. Join and check the top-center chaos countdown. Test with `/chaos status`, `/chaos list`, and `/chaos force miscFireworks` while authorized.

> Folder naming matters: `ensure ChaosMod` must match the installed resource folder.

## Recommended configuration for live roleplay

Edit these existing values in `config.lua`:

```lua
Config.Enabled = true
Config.LiveSafeMode = true
Config.AllowDestructiveEffects = false
Config.WeatherEffects = false
Config.IntervalMs = 120000
Config.EffectDurationMs = 30000
```

Live-safe mode currently permits only these six effect IDs: `miscFireworks`, `miscNightVision`, `miscHeatVision`, `miscBlackout`, `miscPortraitMode`, and `miscIntenseMusic`. Even these may be visually intrusive; test the experience with your community. **This preset is a recommendation, not the configuration shipped in the ZIP.**

## Administrator commands

Commands below are used in-game; run without the leading `/` from the server console.

| Command | Purpose |
| --- | --- |
| `/chaos list` | List currently allowed effect IDs. |
| `/chaos force <effectId>` | Immediately trigger an effect for the server. |
| `/chaos next <effectId>` | Queue an effect for the next automatic event. |
| `/chaos pause` | Pause the automatic countdown; an active effect finishes normally. |
| `/chaos resume` | Resume the automatic countdown. |
| `/chaos stop` | Stop the current effect without disabling future automatic events. |
| `/chaos status` | Show timer, state, active effect, and queue. |
| `/chaos on` | Enable automatic events and restart the countdown. |
| `/chaos off` | Disable automatic events and stop the active effect. |
| `/ChaosMod:ForceNext <effectId>` | Alternate command for queuing the next automatic effect. |

Example:

```text
/chaos force miscFireworks
/chaos next miscNightVision
/chaos status
```

The command permission is controlled by `Config.AdminAce` (default: `chaosmod.admin`). The server console is allowed automatically. Effect filters also apply to forced and queued effects. `playerSwap` needs at least two connected players.

## Key settings

| Setting | Default | Purpose |
| --- | --- | --- |
| `Config.Enabled` | `true` | Enable automatic events at startup. |
| `Config.IntervalMs` | `120000` | Time between event starts (milliseconds). |
| `Config.EffectDurationMs` | `30000` | Default duration for timed effects. |
| `Config.LiveSafeMode` | `false` | Limit effects to the configured safe allowlist. |
| `Config.AllowDestructiveEffects` | `true` | Allow effects marked destructive in the catalog. |
| `Config.WeatherEffects` | `false` | Permit weather-category effects. |
| `Config.SkipWhenEmpty` | `true` | Do not roll effects with nobody online. |
| `Config.DisabledEffects` | `{}` | Block individual effect IDs from random and manual triggers. |
| `Config.UI.Enabled` | `true` | Show the countdown HUD. |
| `Config.UI.Accent` | `'#ef4444'` | HUD accent color. |

See `docs/chaosmod/configuration.md` for the complete configuration reference.

## File structure

```text
ChaosMod/
├── fxmanifest.lua
├── config.lua
├── shared/
│   └── effects.lua
├── server/
│   └── main.lua
├── client/
│   ├── main.lua
│   ├── effects_player.lua
│   ├── effects_vehicle.lua
│   └── effects_misc.lua
└── web/
    ├── index.html
    ├── app.js
    └── style.css
```

## Notes and limitations

- Effects are intended for all connected players. **There is no per-player opt-in or opt-out in this build.**
- Some effects have lasting gameplay consequences even after the timer ends (for example, weapon grants, burst tyres, changed wanted levels, or an instant teleport). Turning an effect off does not necessarily reverse those actions.
- Some vehicle and nearby-world changes may conflict with third-party scripts, anticheat, weather synchronization, inventory, or vehicle persistence systems. Test on a staging server.
- Weather effects are disabled by default to avoid interfering with existing weather synchronization. Do not enable without checking your setup.
- The supplied `fxmanifest.lua` identifies version `1.0.0`, but `server/main.lua` prints `Modern v2.1.1 live edition` at startup. Align these before publishing if you want consistent version labels. The downloadable documentation uses the manifest version.
- Configuration and functionality were documented by reviewing the supplied source files; they have not been verified with a live FiveM test in this documentation pass.

## Documentation

See `docs/chaosmod/` for Docusaurus-ready guides covering installation, configuration, commands, the complete effect catalog, and troubleshooting.

## Support

For help, provide the HSC support team with your resource version, FiveM server artifacts version, relevant console or F8 errors, and steps to reproduce the issue. Do **not** post server secrets or license keys publicly.

**© Hotspot Creations.** Refer to the product's actual sales terms for permitted use and redistribution; no licensing terms are supplied in this source archive.