# OspryOS Anticheat
The OspryOS Anticheat is a simple, lightweight and open-sourced Anticheat System for Roblox games, featuring strong Client and Server-sided Detections, which are highly configurable. The Anticheat also has integration with the _G API from the popular Admin System [Adonis](https://github.com/Epix-Incorporated/Adonis/tree/master), which will be expanded upon in the future.

## Setup
Please check out the [Setup Guide](https://github.com/Alex-Tech-Incorporated/OspryOS-Anticheat/wiki/Setup) on our Wiki Page for everything you need to know to set up the Anticheat for your Game, and potential false positives for detections

## Features
**All recommended checks are enabled by default, as they are the most reliable.** For all other checks, please check out the [Detections Wiki Page](https://github.com/Alex-Tech-Incorporated/OspryOS-Anticheat/wiki/Detections) for more info on how the Checks work and/or potential false positives.

### Server-Sided checks
* Humanoid State change detection
* Magnitude change detection (Anti-Fly)

### Client-Sided checks
* Client load timeout
  * Timeout can be configured
* Noclip detection
  * Raycasting
  * Aggressive (RootPart checks)
* Btools detection
* Gui detection
* Dex detection
* AWP Injection detection
  * **This feature is deprecated, and will be removed in the future**

### Behavior
* Hiding Kick Reasons
  * This feature can be overwritten by usage of the _G API or internal function calls.
  * You can also exclude certian detections from this Rule
* Sending information to Webhooks
  * Also supports HTTP Secrets

### Punishments
* Punishments of all Anticheat Modules are configurable
* You can either Kick a Player, Warn them or log the trip to a Webhook

### Whitelists
* Adonis Whitelist
  * Minimum Rank is configurable, functions via _G API
* Player Whitelist
* Group Whitelist

## Anticheat _G API
The _G API allows Server Scripts to access certain Anticheat features, like access to functions or Tokens. Check out the [API Wiki Page](https://github.com/Alex-Tech-Incorporated/OspryOS-Anticheat/wiki/API) for more info on how to use the _G API of the Anticheat.

> [!IMPORTANT]
> The _G API is unfinished, and subjected to change

# Credits
## Contributors
<a href="https://github.com/Alex-Tech-Incorporated/OspryOS-Anticheat/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=Alex-Tech-Incorporated/OspryOS-Anticheat" />
</a>

## External Sources
This section covers external Models, code or Tools used by the Anticheat or in its Repo, show these people some love!
- [@Evercyan](https://gist.github.com/EvercyanRBX) for his [Remotes](https://devforum.roblox.com/t/remotes-%E2%80%94-natural-type-checking-debounce-and-more/3379709) Module
- [@rinq](https://www.roblox.com/users/177766193/profile) for his [Dex and AWP Detection](https://devforum.roblox.com/t/awp-injection-detection-hook-detection-infinite-yield-detection-dex-explorer-detection/3560554) methods
- [@stravant](https://github.com/stravant) for [GoodSignal](https://github.com/stravant/goodsignal/tree/master), being used for the Client get requests.
- [@Kampfkarren](https://github.com/Kampfkarren) for [selene](https://github.com/Kampfkarren/selene), being used for workflows
- [contrib.rocks](https://contrib.rocks/) for the Contributors part within [README](https://github.com/Alex-Tech-Incorporated/OspryOS-Anticheat/blob/main/README.md)
