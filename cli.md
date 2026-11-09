# Local CLI Tools and Engine Commands

This reference adapts the Simpsons module's CLI workflow for the LEGO research project. Examples use PowerShell. Run Remake Engine commands from the real engine root, currently `A:\RemakeEngine\Main`; paths may differ in another checkout.

## Current Availability

The LEGO parent's `operations.toml` is empty. Shared Lua archive research now lives in `operations/`, with runnable entry scripts and manifests in `Games/Lego_Batman` and `Games/Lego_Harry_Potter`. Their inventory and Windows extraction workflows are documented in [Research/cross-reference/Evidence-and-commands.md](research/cross-reference/Evidence-and-commands.md). Use the respective game context; the parent examples below remain generic templates. No numeric registry module ID is assumed.

## Engine Discovery

From the engine root:

```pwsh
Set-Location -LiteralPath 'A:\RemakeEngine\Main'
dotnet run -c Debug --project .\EngineNet\ -- --help
dotnet run -c Debug --project .\EngineNet\ -- --list-games
```

Once the engine recognizes the target module, inspect its available operations:

```pwsh
dotnet run -c Debug --project .\EngineNet\ -- --list-ops '.\EngineApps\Games\Lego'
```

An empty manifest does not establish a usable module. The 2026-11-08 research runs verified nested discovery and execution by the names `Lego_Harry_Potter` and `Lego_Batman`. Explicit nested-path operation listing failed in that checkout; use the discovered names shown in the linked commands. Automatic inter-module dependency installation remains unverified; folder placement alone does not establish it.

## Operation and Script Templates

Select an actual operation ID or exact display name from the target manifest. Replace `<ID>` before using this template:

```pwsh
dotnet run -c Debug --project .\EngineNet\ -- --game_module '.\EngineApps\Games\Lego' --run_op <ID>
```

Direct Lua execution can bypass an operation entry, but still requires a valid target module and an existing script. Replace `<ScriptName>` with the relevant script:

```pwsh
dotnet run -c Debug --project .\EngineNet\ -- --game_module '.\EngineApps\Games\Lego' --script_type lua --script '{{Game_Root}}/operations/<ScriptName>.lua'
```

For a child module, use its actual path and its own manifest. Do not copy the Simpsons module's name, registry ID, operation IDs, or scripts.

Supported argument patterns, appended to an appropriate command:

| Option | Purpose | Example |
| --- | --- | --- |
| `--arg` | One script argument | `--arg 'value'` |
| `--args` | Multiple script arguments; prefer a JSON array | `--args '["--input", "D:\\GameDump", "--output", "D:\\ResearchOutput"]'` |
| `--answer` | Answer a manifest prompt | `--answer verbose=true` |
| `--auto_prompt` | Answer a Lua prompt by its actual ID | `--auto_prompt prompt_id=response` |
| `--note` | Label the execution log | `--note 'archive-sample-check'` |

Input and output argument names depend on the script; the table does not define an existing LEGO script interface. `{{Game_Root}}` and `{{Project_Root}}` are engine placeholders. Consult the engine's [CLI reference](../../../schemas/cli-command.schema.md) when changing command syntax.

## Tool Discovery

Inspect installed tools rather than hard-coding a versioned path. If a recorded path no longer exists, check its parent directory for the installed version before reporting the tool missing.

```pwsh
Get-Command dotnet, git, python, ffmpeg -All -ErrorAction SilentlyContinue
Get-ChildItem -LiteralPath 'A:\RemakeEngine\Main\EngineApps\Tools' -Directory
```

`Tools.toml` currently declares Blender, QuickBMS, vgmstream-cli, FFmpeg, and ImageMagick. Declarations do not establish installation, compatibility, or a working extraction pipeline. Discover the actual executable and inspect its help before selecting flags. Blender's bundled Python may also be available beneath its versioned installation.

Additional utilities from the Simpsons workflow may be available on this machine. Discover them before use:

| Utility | Read or discovery usage |
| --- | --- |
| `Get-Commands` | `Get-Commands python` resolves PATH matches; the reference installation is `B:\System_Path\Flat-Path\Get-Commands.ps1`. |
| `environment-manager` | Use `summary`, `search blender`, `which ffmpeg`, or `paths --valid-only --flat`. The reference binary is `A:\environment-manager\Build\win-x64-Release\environment-manager.exe`. Running without arguments opens its GUI. |
| BetterGit | Inspect `--help` at `A:\BetterVscode\BetterGitNet\publish\win-x64\BetterGit.exe` if installed; ordinary Git commands remain available. |
| Everything Search | The reference GUI binary is `B:\Installed_Apps\Program_Files\Everything\Everything.exe`. Use targeted `rg --files` searches for repository discovery. |

Invoke quoted executable paths with PowerShell's call operator: `& 'path\to\tool.exe' --help`. Keep tool versions, commands, inputs, and output locations in research notes when they affect reproducibility.
