# LEGO Project Agent Guidelines

These instructions apply to this module and its descendants. Follow the parent engine's guidance and any more specific `AGENTS.md` in the area being changed. Read [Readme.md](Readme.md), [Style.md](Style.md), and [cli.md](cli.md) before making relevant changes.

## Project Scope

This is an extraction, research, and reverse-engineering project for LEGO games. A remake, gameplay implementation, or generated Godot project is outside the current scope unless the user explicitly requests it.

The parent module is intended to hold shared functionality, with individual game modules nested under `Games/`. Keep game-specific assumptions within the corresponding game. Do not assume a format or parser works across titles, platforms, regions, or releases without evidence.

Read [TODO.md](TODO.md) as planning context. Its engine changes are pending work, not instructions to implement them during unrelated tasks. Nested module discovery and inter-module dependencies must not be described as available until verified in the engine.

## Research and Evidence

- Inspect existing notes and relevant implementation before drawing conclusions.
- Distinguish observations, hypotheses, and confirmed interpretations. Record unresolved fields explicitly.
- Make findings reproducible: identify the game, platform, release or build when known, input path or hash, relevant offsets, tool version, command, and result as appropriate.
- Preserve original game files. Write extraction and conversion outputs separately; keep generated files out of source documentation.
- Validate parsers against representative inputs and malformed or truncated data when relevant. Include file and offset context in diagnostics.
- Keep proprietary game binaries and extracted assets out of commits. Prefer synthetic examples and metadata for sharing findings.
- Update relevant research notes and usage documentation when behavior or understanding changes.

## Repository Boundaries

The Simpsons project is a reference for workflow, not a source of LEGO format assumptions. This project does not currently have its `reversing/docs` submodule, `EngineFiles/` mirror, operation IDs, or registry module ID.

If a nested game or research directory becomes a separate repository or Git submodule, read its own instructions and preserve its existing work. Changes belong to that repository; the parent tracks a submodule commit separately.

Avoid `.history/`, `.backup/`, original `Source/` trees, and generated output during broad searches unless they are relevant to the task. Search targeted inputs when investigating game data.

## Engine and CLI Integration

Use [cli.md](cli.md) for operation execution, arguments, and tool discovery. Run engine commands from the real engine root, currently `A:\RemakeEngine\Main`, rather than from a source mirror or nested game folder.

Read the target module's manifest before selecting an operation. The parent `operations.toml` is currently empty: do not invent runnable operations, numeric module IDs, or working extraction commands. Use explicit module paths where appropriate, and verify discovery before assuming nested game modules resolve.

Inspect engine APIs in `../../api_definitions/` and engine source in `../../../EngineNet/` before relying on them. Engine changes are separate from module changes. When authorized to change engine APIs or configuration behavior, follow the engine's instructions for API stubs, demo coverage, schemas, and documentation.

## Lua Types and Documentation

As in the Simpsons module, all Lua functions must document each parameter and return value with `---@param` and `---@return`. Annotate imports and engine-provided components with their known types.

Define a `---@class` for objects shared across functions or files, objects with more than three fields, and core domain structures. Reuse shared definitions, type collection elements, and use `---@cast` where inference loses information. Casts must reflect verified types rather than hide unchecked assumptions.

```lua
---@class ArchiveEntry
---@field Name string
---@field Offset integer
---@field StoredSize integer
---@field UnpackedSize integer|nil

---@param Entry ArchiveEntry
---@param FileSize integer
---@return boolean IsValid
local function IsEntryInBounds(Entry, FileSize)
    return Entry.Offset >= 0
        and Entry.StoredSize >= 0
        and Entry.Offset <= FileSize
        and Entry.StoredSize <= FileSize - Entry.Offset
end
```

## Validation

For documentation changes, check links, paths, examples, and claims against the current files. For extraction or parser changes, use focused checks that verify the affected behavior and record the inputs and limitations. For Lua operation changes, provide the exact engine command for manual validation, following the parent engine's workflow. Do not claim a command or platform was tested unless it was.
