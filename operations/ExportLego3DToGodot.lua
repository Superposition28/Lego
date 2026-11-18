---@class ExportCliOptions
---@field MaxPerGame integer
---@field SkipGodotImport boolean
---@field SkipSync boolean
---@field Force boolean

---@param RawArgs string[]|nil
---@return ExportCliOptions Options
local function ParseOptions(RawArgs)
    ---@type ExportCliOptions
    local Options = {
        MaxPerGame = 0,
        SkipGodotImport = false,
        SkipSync = false,
        Force = false,
    }
    if not RawArgs then
        return Options
    end
    for _, Arg in ipairs(RawArgs) do
        if Arg == "--skip-import" then
            Options.SkipGodotImport = true
        elseif Arg == "--skip-sync" then
            Options.SkipSync = true
        elseif Arg == "--force" then
            Options.Force = true
        elseif Arg:match("^%-%-max%-per%-game=") then
            local Parsed = tonumber(Arg:sub(16))
            assert(Parsed and Parsed >= 0 and Parsed % 1 == 0, "Invalid --max-per-game value: " .. Arg)
            Options.MaxPerGame = math.floor(Parsed)
        else
            warn("ExportLego3DToGodot ignoring unknown argument: " .. tostring(Arg))
        end
    end
    return Options
end

---@return string BlenderExecutable
local function FindBlenderExecutable()
    local Resolved = ResolveToolPath and ResolveToolPath("Blender", "4.5.4") or nil
    if Resolved and sdk.is_file(Resolved) then
        return Resolved
    end
    local Preferred = Project_Root .. "/EngineApps/Tools/Blender-4.5.4-win-x64/blender.exe"
    assert(sdk.is_file(Preferred), "Blender 4.5.4 executable not found at " .. Preferred)
    return Preferred
end

---@return string GodotExecutable
local function FindGodot45Executable()
    local Resolved = ResolveToolPath and ResolveToolPath("Godot", "4.5-stable-mono") or nil
    if Resolved and sdk.is_file(Resolved) then
        local ConsoleCandidate = Resolved:gsub("win64%.exe$", "win64_console.exe")
        if sdk.is_file(ConsoleCandidate) then
            return ConsoleCandidate
        end
        return Resolved
    end
    local Preferred = Project_Root .. "/EngineApps/Tools/Godot-4.5-stable-mono-win-x64/Godot_v4.5-stable_mono_win64_console.exe"
    assert(sdk.is_file(Preferred), "Godot 4.5 console executable not found at " .. Preferred)
    return Preferred
end

---@param BlenderExe string
---@param ConverterPy string
---@param StagingDir string
---@param TargetDir string
---@return nil
local function SyncStagingToTarget(BlenderExe, ConverterPy, StagingDir, TargetDir)
    sdk.ensure_dir(TargetDir)
    local SyncCmd = {
        BlenderExe,
        "--background",
        "--factory-startup",
        "--python", ConverterPy,
        "--",
        "--lego-root", Game_Root,
        "--godot-dir", StagingDir,
        "--sync-only",
        "--sync-to", TargetDir,
    }
    ---@type RunResult
    local SyncResult = sdk.run_process(SyncCmd, {timeout_ms = 600000})
    if SyncResult.stdout and SyncResult.stdout ~= "" then
        print(SyncResult.stdout)
    end
    assert(SyncResult.success, "Failed syncing test_staging -> test: " .. (SyncResult.stderr or ""))
end

---@return nil
local function Main()
    assert(Game_Root and Game_Root ~= "", "Game_Root global must be set by engine")
    local Options = ParseOptions(argv)
    local ConverterPy = Game_Root .. "/operations/ConvertGhgGscToGlb.py"
    local StagingDir = Game_Root .. "/godot/test_staging"
    local TargetDir = Game_Root .. "/godot/test"

    assert(sdk.is_file(ConverterPy), "Missing converter script: " .. ConverterPy)
    sdk.ensure_dir(StagingDir)

    local BlenderExe = FindBlenderExecutable()
    local Cmd = {
        BlenderExe,
        "--background",
        "--factory-startup",
        "--python", ConverterPy,
        "--",
        "--lego-root", Game_Root,
        "--godot-dir", StagingDir,
    }
    if Options.MaxPerGame > 0 then
        Cmd[#Cmd + 1] = "--max-per-game"
        Cmd[#Cmd + 1] = tostring(Options.MaxPerGame)
    end
    if Options.Force then
        Cmd[#Cmd + 1] = "--force"
    end

    print("[ExportLego3DToGodot] Converting and linking 3D assets to staging project: " .. StagingDir)
    ---@type RunResult
    local ConvertResult = sdk.run_process(Cmd, {timeout_ms = 600000})
    if ConvertResult.stdout and ConvertResult.stdout ~= "" then
        print(ConvertResult.stdout)
    end
    assert(ConvertResult.success, "ConvertGhgGscToGlb.py failed: " .. (ConvertResult.stderr or ""))

    if not Options.SkipGodotImport then
        local GodotExe = FindGodot45Executable()
        print("[ExportLego3DToGodot] Running headless Godot 4.5 import verification on " .. StagingDir)
        ---@type RunResult
        local ImportResult = sdk.run_process({GodotExe, "--headless", "--path", StagingDir, "--import", "--quit"}, {timeout_ms = 900000})
        if ImportResult.stdout and ImportResult.stdout ~= "" then
            print(ImportResult.stdout)
        end
        assert(ImportResult.success, "Headless Godot staging import failed: " .. (ImportResult.stderr or ""))
    end

    if not Options.SkipSync then
        print("[ExportLego3DToGodot] Syncing verified addon, viewer scenes, and 3D assets into " .. TargetDir)
        SyncStagingToTarget(BlenderExe, ConverterPy, StagingDir, TargetDir)
    end
end

Main()
