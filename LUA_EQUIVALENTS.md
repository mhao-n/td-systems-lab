# Small Lua equivalents

| Roblox/Luau feature | Pure Lua replacement in `demo.lua` |
|---|---|
| `Random.new(seed)` | Local deterministic LCG with `number()` and `integer()` |
| Player attributes | Plain input tables and function arguments |
| Roblox ModuleScripts | Ordinary local Lua tables and functions |
| Luau string interpolation | `string.format` |
| Studio UI labels and charts | Aligned terminal tables and Monte Carlo output |
| `workspace` day attributes | Explicit numeric `period` passed to quest generation |

The replacements are not Roblox emulators; they are the smallest portable pieces needed to preserve the original systems’ behavior.