---@type TtArchiveResearch
local Research = import("TtArchiveResearch.lua")

---@class ExtractCliOptions
---@field Force boolean
---@field AllFiles boolean
---@field Limit integer

---@class SourceScanResult
---@field Archives string[]
---@field LooseModels string[]
---@field SkippedNotes string[]

---@param RawArgs string[]|nil
---@return ExtractCliOptions Options
local function ParseOptions(RawArgs)
    ---@type ExtractCliOptions
    local Options = {
        Force = false,
        AllFiles = false,
        Limit = 0,
    }
    if not RawArgs then
        return Options
    end
    for _, Arg in ipairs(RawArgs) do
        if Arg == "--force" then
            Options.Force = true
        elseif Arg == "--all-files" then
            Options.AllFiles = true
        elseif Arg:match("^%-%-limit=") then
            local Parsed = tonumber(Arg:sub(9))
            assert(Parsed and Parsed >= 0 and Parsed % 1 == 0, "Invalid --limit value: " .. Arg)
            Options.Limit = math.floor(Parsed)
        else
            warn("ExtractModuleAssets ignoring unknown argument: " .. tostring(Arg))
        end
    end
    return Options
end

---@param DirPath string
---@return string|nil FirstModelPath
local function FindAnyExtractedModel(DirPath)
    if not sdk.is_dir(DirPath) then
        return nil
    end
    local Entries = sdk.list_dir(DirPath)
    table.sort(Entries)
    for _, Name in ipairs(Entries) do
        if Name ~= ".history" and Name ~= ".backup" and Name ~= "TMP" then
            local FullPath = DirPath .. "/" .. Name
            if sdk.is_file(FullPath) then
                local Lower = Name:lower()
                if Lower:match("%.ghg$") or Lower:match("%.gsc$") then
                    return FullPath
                end
            elseif sdk.is_dir(FullPath) then
                local Nested = FindAnyExtractedModel(FullPath)
                if Nested then
                    return Nested
                end
            end
        end
    end
    return nil
end

---@param ArchivePath string
---@param BaseRoot string
---@return string SafeKey
local function MakeArchiveOutputKey(ArchivePath, BaseRoot)
    local PrefixLen = #BaseRoot + 2
    local Relative = #ArchivePath >= PrefixLen and ArchivePath:sub(PrefixLen) or ArchivePath
    return Relative:gsub("[\\/]", "__"):gsub("[^%w%._%-]", "_")
end

---@param SourceDir string
---@return SourceScanResult Scan
local function ScanSourceDirectory(SourceDir)
    ---@type SourceScanResult
    local Scan = {
        Archives = {},
        LooseModels = {},
        SkippedNotes = {},
    }
    if not sdk.is_dir(SourceDir) then
        return Scan
    end
    ---@type string[]
    local AllFiles = {}
    Research.Walk(SourceDir, AllFiles)
    for _, FilePath in ipairs(AllFiles) do
        local Lower = FilePath:lower()
        if Lower:match("%.dat$") or Lower:match("%.datwin$") then
            Scan.Archives[#Scan.Archives + 1] = FilePath
        elseif Lower:match("%.ghg$") or Lower:match("%.gsc$") then
            Scan.LooseModels[#Scan.LooseModels + 1] = FilePath
        elseif Lower:match("%.iso$") or Lower:match("%.lnk$") or Lower:match("%.rvz$") then
            Scan.SkippedNotes[#Scan.SkippedNotes + 1] = FilePath
        end
    end
    return Scan
end

---@param LooseModels string[]
---@param SourceDir string
---@param LooseOutputRoot string
---@param Force boolean
---@return integer CopiedCount
local function CopyLooseModels(LooseModels, SourceDir, LooseOutputRoot, Force)
    local CopiedCount = 0
    for _, ModelPath in ipairs(LooseModels) do
        local Rel = #ModelPath > (#SourceDir + 1) and ModelPath:sub(#SourceDir + 2) or ModelPath:match("([^\\/]+)$")
        local DestPath = LooseOutputRoot .. "/" .. Rel
        if Force or not sdk.path_exists(DestPath) then
            local DestDir = DestPath:match("^(.+)[\\/][^\\/]+$")
            if DestDir then
                sdk.ensure_dir(DestDir)
            end
            sdk.copy_file(ModelPath, DestPath)
            CopiedCount = CopiedCount + 1
        end
    end
    return CopiedCount
end

---@return nil
local function Main()
    assert(Game_Root and Game_Root ~= "", "Game_Root global must be set by engine")
    local Options = ParseOptions(argv)
    local GameFilesDir = Game_Root .. "/GameFiles"
    local SourceDir = Game_Root .. "/Source"

    if not Options.Force then
        local ExistingModel = FindAnyExtractedModel(GameFilesDir)
        if ExistingModel then
            print("[ExtractModuleAssets] Existing extracted 3D assets found (e.g. " .. ExistingModel .. "); skipping redundant extraction.")
            return
        end
    end

    if not sdk.is_dir(SourceDir) then
        print("[ExtractModuleAssets] No Source directory at " .. SourceDir .. "; skipping cleanly.")
        return
    end

    local Scan = ScanSourceDirectory(SourceDir)
    if #Scan.Archives == 0 and #Scan.LooseModels == 0 then
        if #Scan.SkippedNotes > 0 then
            print("[ExtractModuleAssets] Only unsupported/shortcut/disc source files found (" .. #Scan.SkippedNotes .. " item(s), e.g. " .. Scan.SkippedNotes[1] .. "); skipping cleanly.")
        else
            print("[ExtractModuleAssets] No extractable archives or models found under " .. SourceDir .. "; skipping cleanly.")
        end
        return
    end

    local ExtractedRoot = GameFilesDir .. "/extracted/assets"
    sdk.ensure_dir(ExtractedRoot)

    local ExtractedArchives = 0
    local ExtractedEntries = 0
    for _, ArchivePath in ipairs(Scan.Archives) do
        local ReadOk, ArchiveOrErr = pcall(Research.Read, ArchivePath)
        if not ReadOk then
            warn("[ExtractModuleAssets] Skipping unreadable/unsupported archive '" .. ArchivePath .. "': " .. tostring(ArchiveOrErr))
        else
            ---@cast ArchiveOrErr TtArchive
            local Key = MakeArchiveOutputKey(ArchivePath, Game_Root)
            local OutputDir = ExtractedRoot .. "/" .. Key
            if sdk.path_exists(OutputDir) then
                print("[ExtractModuleAssets] Output already exists for " .. Key .. "; skipping.")
            else
                ---@type string|nil
                local FilterPattern = nil
                if not Options.AllFiles and #ArchiveOrErr.Entries > 1000 then
                    FilterPattern = "%.ghg$"
                end
                if FilterPattern then
                    -- Extract 3D models and scene geometry (*.ghg / *.gsc / *.sub / *.anm / *.fib) from huge archives cleanly.
                    FilterPattern = "%.g[hs][gc]$"
                    print("[ExtractModuleAssets] Extracting 3D models (*.ghg/*.gsc) from " .. ArchivePath .. " (" .. #ArchiveOrErr.Entries .. " total entries) -> " .. OutputDir)
                else
                    print("[ExtractModuleAssets] Extracting " .. ArchivePath .. " (" .. #ArchiveOrErr.Entries .. " entries) -> " .. OutputDir)
                end
                local Count = Research.Extract(ArchiveOrErr, OutputDir, Options.Limit, FilterPattern)
                ExtractedArchives = ExtractedArchives + 1
                ExtractedEntries = ExtractedEntries + Count
            end
        end
    end

    local CopiedLoose = CopyLooseModels(Scan.LooseModels, SourceDir, ExtractedRoot .. "/loose", Options.Force)
    print(string.format("[ExtractModuleAssets] Completed module %s: %d archive(s), %d file(s) extracted, %d loose model(s) copied.", Game_Root, ExtractedArchives, ExtractedEntries, CopiedLoose))
end

Main()
