# Local CLI Tools and Engine Commands

This reference adapts the Simpsons module's CLI workflow for the LEGO research project. Examples use PowerShell. Run Remake Engine commands from the real engine root, currently `A:\RemakeEngine\Main`; paths may differ in another checkout.

## Current Availability

The LEGO parent's `operations.toml` is empty and `operations/` contains no scripts yet. There is no extraction command to run at present. Operation and script examples below are templates for future work, not working LEGO operations. No registry module ID is assumed.

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

An empty manifest does not establish a usable module. Check engine discovery and manifest requirements before interpreting a failure. Nested module discovery and module dependencies are planned in [TODO.md](TODO.md); folder placement alone does not establish support.

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
