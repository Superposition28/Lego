-- Shared only for the locally validated PakDat -4 and Collection datwin -1 layouts.
-- All archive integers are little endian, including PS3/Xbox 360 containers.
---@class TtEntry
---@field Index integer Zero based TOC ordinal.
---@field Offset integer Absolute byte offset.
---@field StoredSize integer
---@field Size integer
---@field Compression integer
---@field Hash integer
---@field Name string|nil
---@field Resolution string
---@class TtArchive
---@field Path string
---@field Kind string
---@field Size integer
---@field TocOffset integer
---@field TocSize integer
---@field Version integer
---@field Entries TtEntry[]
---@field TocSha1 string|nil
---@class TtArchiveResearch
---@field Run fun(Roots: string[], Arguments: string[]): nil
---@field Read fun(Path: string): TtArchive
---@field Hash fun(Path: string): integer
---@field Extract fun(Archive: TtArchive, Output: string, Limit: integer): integer
---@field UInt fun(Bytes: string, Position: integer, Width: integer): integer
---@field Walk fun(Path: string, Files: string[]): nil
local Research = {}

---@param Bytes string
---@param Position integer One based string index.
---@param Width integer
---@return integer Value
local function UInt(Bytes, Position, Width)
    assert(Position >= 1 and Position + Width - 1 <= #Bytes, "truncated integer at buffer offset " .. (Position - 1))
    local Value = 0
    for Index = Position + Width - 1, Position, -1 do
        -- io.read exposes Latin1 codepoints; MoonSharp string.byte uses a codepage
        -- which replaces 0xFF. Its documented string.unicode preserves all bytes.
        Value = Value * 256 + string.unicode(Bytes, Index, Index)
    end
    assert(Value <= 9007199254740991, "integer exceeds MoonSharp exact range at buffer offset " .. (Position - 1))
    return Value
end
Research.UInt = UInt

---@param Value integer
---@param Width integer
---@return integer Value
local function Signed(Value, Width)
    if Value >= 2 ^ (Width * 8 - 1) then return Value - 2 ^ (Width * 8) end
    return Value
end

---@param Path string
---@return integer Hash
local function Hash(Path)
    local Value = 0x811C9DC5
    Path = Path:upper():gsub("/", "\\")
    for Index = 1, #Path do
        -- Avoid MoonSharp 2.0 bit32's signed conversion of values above INT_MAX.
        local Low = Value % 256
        Value = ((Value - Low + bit32.bxor(Low, string.unicode(Path, Index, Index))) * 0x00199933) % 4294967296
    end
    return Value
end
Research.Hash = Hash

---@param Path string
---@param Files string[]
---@return nil
local function Walk(Path, Files)
    if not sdk.is_dir(Path) then return end
    local Names = sdk.list_dir(Path)
    table.sort(Names)
    for _, Name in ipairs(Names) do
        local Child = Path .. "/" .. Name
        if sdk.is_file(Child) then
            Files[#Files + 1] = Child
        elseif sdk.is_dir(Child) and Name ~= ".history" and Name ~= ".backup"
            and Name ~= "LHP.rep" and Name ~= "Extracted_Comparison" and Name ~= "TMP" then
            Walk(Child, Files)
        end
    end
end
Research.Walk = Walk

---@param Handle FileHandle
---@param Offset integer
---@param Count integer
---@param Path string
---@return string Bytes
local function ReadAt(Handle, Offset, Count, Path)
    assert(Handle.seek("set", Offset) == Offset, Path .. ": seek failed at " .. Offset)
    local Bytes = Handle.read(Count) or ""
    assert(#Bytes == Count, Path .. ": truncated read at " .. Offset .. ", expected " .. Count .. ", got " .. #Bytes)
    return Bytes
end

---@param Path string
---@return TtArchive Archive
local function ReadArchive(Path)
    ---@type FileHandle
    local Handle = assert(io.open(Path, "rb"))
    local FileSize = assert(Handle.seek("end", 0))
    local Header = ReadAt(Handle, 0, math.min(57, FileSize), Path)
    assert(#Header >= 16, Path .. ": truncated archive header at 0")
    local IsPak = Header:sub(9, 57) == "BEGIN_APP_ID_STRINGPakDat v1.01END_APP_ID_STRING\0"
    local TocOffset, TocSize
    if IsPak then
        TocOffset = Signed(UInt(Header, 1, 4), 4)
        if TocOffset < 0 then TocOffset = -TocOffset * 256 end
        TocSize = UInt(Header, 5, 4)
    else
        assert(Path:lower():match("%.datwin$"), Path .. ": unsupported archive signature at 8")
        TocOffset, TocSize = UInt(Header, 1, 8), UInt(Header, 9, 8)
    end
    assert(TocOffset >= (IsPak and 57 or 16) and TocSize >= 8 and TocOffset <= FileSize
        and TocSize == FileSize - TocOffset and TocSize <= 16777216, Path .. ": invalid TOC bounds at 0")
    local Toc = ReadAt(Handle, TocOffset, TocSize, Path)
    Handle.close()
    local Version, Count = Signed(UInt(Toc, 1, 4), 4), UInt(Toc, 5, 4)
    local Stride = IsPak and 16 or 24
    assert(Version == (IsPak and -4 or -1), Path .. ": unsupported TOC version at " .. TocOffset .. ": " .. Version)
    assert(Count <= math.floor((TocSize - 8) / (Stride + 4)), Path .. ": invalid entry count at " .. (TocOffset + 4))
    ---@type TtArchive
    local Archive = {Path = Path, Kind = IsPak and "PakDat" or "datwin", Size = FileSize,
        TocOffset = TocOffset, TocSize = TocSize, Version = Version, Entries = {}}
    for Index = 0, Count - 1 do
        local Position = 9 + Index * Stride
        ---@type TtEntry
        local Entry = {Index = Index, Hash = 0, Resolution = "unresolved", Offset = 0, StoredSize = 0, Size = 0, Compression = 0}
        if IsPak then
            Entry.Offset = UInt(Toc, Position, 4) * 256 + UInt(Toc, Position + 15, 1)
            Entry.StoredSize, Entry.Size = UInt(Toc, Position + 4, 4), UInt(Toc, Position + 8, 4)
            Entry.Compression = UInt(Toc, Position + 12, 1)
        else
            Entry.Offset = UInt(Toc, Position, 8)
            assert(UInt(Toc, Position + 8, 4) == 0x12345678, Path .. ": bad canary at " .. (TocOffset + Position + 7))
            Entry.StoredSize, Entry.Size = UInt(Toc, Position + 12, 4), UInt(Toc, Position + 16, 4)
            Entry.Compression = UInt(Toc, Position + 20, 1)
            assert(UInt(Toc, Position + 20, 4) == Entry.Compression * 0x01010101, Path .. ": unexpected datwin flags at " .. (TocOffset + Position + 19))
        end
        assert(Entry.Offset >= (IsPak and 57 or 16) and Entry.Offset <= TocOffset
            and Entry.StoredSize <= TocOffset - Entry.Offset, Path .. ": entry " .. Index .. " out of payload bounds at " .. (TocOffset + Position - 1))
        assert(Entry.Compression ~= 0 or Entry.StoredSize == Entry.Size, Path .. ": raw size mismatch for entry " .. Index)
        Archive.Entries[#Archive.Entries + 1] = Entry
    end
    local HashPosition = 9 + Count * Stride
    if IsPak then
        local Nodes = UInt(Toc, HashPosition, 4)
        local NodeBase = HashPosition + 4
        assert(Nodes > 0 and Nodes <= math.floor((#Toc - NodeBase) / 8), Path .. ": invalid node count at " .. (TocOffset + HashPosition - 1))
        local StringSizePosition = NodeBase + Nodes * 8
        local StringSize = UInt(Toc, StringSizePosition, 4)
        local StringBase = StringSizePosition + 4
        assert(StringSize <= #Toc - StringBase + 1 - Count * 4, Path .. ": string table exceeds TOC")
        local Strings = Toc:sub(StringBase, StringBase + StringSize - 1)
        ---@type table<integer, string>
        local Paths = {[0] = ""}
        ---@type table<integer, integer>
        local Parents = {[0] = -1}
        for Index = 1, Nodes - 1 do
            local Position = NodeBase + Index * 8
            local Child = Signed(UInt(Toc, Position, 2), 2)
            local Previous = Signed(UInt(Toc, Position + 2, 2), 2)
            local NameOffset = UInt(Toc, Position + 4, 4)
            assert(Previous >= 0 and Previous < Index, Path .. ": invalid sibling at " .. (TocOffset + Position + 1))
            assert(NameOffset < StringSize, Path .. ": invalid name offset at " .. (TocOffset + Position + 3))
            local End = NameOffset + 1
            while End <= #Strings and string.unicode(Strings, End, End) ~= 0 do End = End + 1 end
            assert(End <= #Strings, Path .. ": unterminated name at " .. (TocOffset + StringBase + NameOffset - 1))
            local Component = Strings:sub(NameOffset + 1, End - 1)
            assert(Component ~= ".." and Component ~= "." and not Component:find('[\\/:%c]'), Path .. ": unsafe name component")
            local Parent = Previous == 0 and Index - 1 or Parents[Previous]
            Parents[Index] = Parent
            Paths[Index] = Paths[Parent] == "" and Component or Paths[Parent] .. "\\" .. Component
            if Child <= 0 then
                local Entry = Archive.Entries[-Child + 1]
                assert(Entry and not Entry.Name, Path .. ": invalid/duplicate leaf at " .. (TocOffset + Position - 1))
                Entry.Name, Entry.Resolution = Paths[Index], "archive-name-tree"
            end
        end
        HashPosition = StringBase + StringSize
        assert(HashPosition + Count * 4 + 8 - 1 == #Toc, Path .. ": unexpected trailing TOC size")
    else
        assert(TocSize == 8 + Count * 28, Path .. ": unexpected datwin TOC size")
    end
    for Index, Entry in ipairs(Archive.Entries) do
        Entry.Hash = UInt(Toc, HashPosition + (Index - 1) * 4, 4)
        assert(not Entry.Name or Hash(Entry.Name) == Entry.Hash, Path .. ": name/hash mismatch for entry " .. Entry.Index .. " name=" .. (Entry.Name or "") .. string.format(" expected=%08X actual=%08X", Entry.Hash, Entry.Name and Hash(Entry.Name) or 0))
    end
    return Archive
end
---@param Path string
---@return TtArchive Archive
local function Read(Path)
    local Ok, Result = pcall(ReadArchive, Path)
    assert(Ok, Path .. ": " .. tostring(Result))
    return Result
end
Research.Read = Read

---@param Name string
---@return string SafeName
local function SafeName(Name)
    Name = Name:gsub("\\", "/")
    assert(Name ~= "" and not Name:match("^/") and not Name:find('[:%c";]'), "unsafe output name: " .. Name)
    for Part in Name:gmatch("[^/]+") do
        assert(Part ~= "." and Part ~= ".." and not Part:match("[%. ]$"), "unsafe output component: " .. Part)
    end
    return Name
end

---@param Archive TtArchive
---@return string Key
local function ArchiveKey(Archive)
    return Archive.Path:sub(#Game_Root + 2):gsub("[\\/]", "__"):gsub("[^%w%._%-]", "_")
end

---@param Archive TtArchive
---@param Output string
---@param Limit integer
---@return integer Extracted
local function Extract(Archive, Output, Limit)
    local Tool = assert(ResolveToolPath("QuickBMS", "0.12.0"), "install QuickBMS using operation -1")
    local LargeTool = Tool:gsub("quickbms%.exe$", "quickbms_4gb_files.exe")
    assert(sdk.is_file(LargeTool), "QuickBMS 64-bit-offset executable missing: " .. LargeTool)
    assert(not sdk.path_exists(Output), "extraction output already exists; choose a fresh run directory: " .. Output)
    -- Validate chunk framing against the declared entry span before QuickBMS
    -- reads it. A damaged chunk must not consume the next archive member.
    local Source = assert(io.open(Archive.Path, "rb"))
    for Index, Entry in ipairs(Archive.Entries) do
        if Limit > 0 and Index > Limit then break end
        if Entry.Compression == 2 and Entry.Size > 0 then
            local Position, Total = Entry.Offset, 0
            local End = Entry.Offset + Entry.StoredSize
            while Total < Entry.Size do
                assert(End - Position >= 12, Archive.Path .. ": truncated LZ2K header at " .. Position)
                local Header = ReadAt(Source, Position, 12, Archive.Path)
                local Size, Stored = UInt(Header, 5, 4), UInt(Header, 9, 4)
                assert(Header:sub(1, 4) == "LZ2K" and Size > 0 and Size <= 32768
                    and Size <= Entry.Size - Total and Stored > 0 and Stored <= End - Position - 12,
                    Archive.Path .. ": invalid LZ2K chunk at " .. Position)
                Position, Total = Position + 12 + Stored, Total + Size
            end
            assert(Position == End, Archive.Path .. ": LZ2K trailing bytes at " .. Position)
        end
    end
    Source.close()
    sdk.ensure_dir(Output)
    local Count = 0
    local Commands = {}
    local CommandLength = 0
    ---@type table<string, boolean>
    local Destinations = {}
    -- QuickBMS supports inline commands through -s. No generated BMS or native host scripts.
    ---@return nil
    local function Flush()
        if #Commands == 0 then return end
        ---@type RunResult
        local Result = sdk.run_process({LargeTool, "-Q", "-Y", "-s", table.concat(Commands, " ; "), "", Archive.Path, Output}, {timeout_ms = 600000})
        assert(Result.success, Archive.Path .. ": QuickBMS failed: " .. (Result.stderr or "") .. (Result.stdout or ""))
        Commands, CommandLength = {}, 0
    end
    for _, Entry in ipairs(Archive.Entries) do
        if Limit > 0 and Count >= Limit then break end
        local Name = SafeName(Entry.Name or string.format("__unresolved/%08X_%05d.bin", Entry.Hash, Entry.Index))
        assert(not Destinations[Name:lower()], Archive.Path .. ": duplicate Windows output path: " .. Name)
        Destinations[Name:lower()] = true
        local Command
        if Entry.Compression == 0 or Entry.Size == 0 then
            Command = string.format('log "%s" %.0f %.0f', Name, Entry.Offset, Entry.Size)
        elseif Entry.Compression == 3 then
            Command = string.format('comtype zlib ; clog "%s" %.0f %.0f %.0f', Name, Entry.Offset, Entry.StoredSize, Entry.Size)
        elseif Entry.Compression == 4 then
            Command = string.format('comtype lzham "15 0 5 0 0" ; clog "%s" %.0f %.0f %.0f', Name, Entry.Offset, Entry.StoredSize, Entry.Size)
        elseif Entry.Compression == 2 then
            -- Decode chunk headers within the entry bounds; LZ2K payload decoder is managed QuickBMS.
            Command = string.format('comtype lz2k ; goto %.0f ; set TOTAL long 0 ; append ; for ; getdstring MAGIC 4 ; if MAGIC != "LZ2K" ; cleanexit ; endif ; get U long ; get C long ; savepos O ; if C == U ; log "%s" O U ; else ; clog "%s" O C U ; endif ; math O + C ; goto O ; math TOTAL + U ; if TOTAL >= %.0f ; break ; endif ; next ; append', Entry.Offset, Name, Name, Entry.Size)
        else
            error(Archive.Path .. ": unsupported compression " .. Entry.Compression .. " at entry " .. Entry.Index)
        end
        if CommandLength + #Command > 18000 then Flush() end
        Commands[#Commands + 1], CommandLength = Command, CommandLength + #Command + 3
        Count = Count + 1
    end
    Flush()
    -- Check every output size; never report a raw compressed stream as an extracted asset.
    for Index = 1, Count do
        local Entry = Archive.Entries[Index]
        local Name = SafeName(Entry.Name or string.format("__unresolved/%08X_%05d.bin", Entry.Hash, Entry.Index))
        local Handle = assert(io.open(Output .. "/" .. Name, "rb"), "missing output: " .. Name)
        local Size = Handle.seek("end", 0)
        Handle.close()
        assert(Size == Entry.Size, Archive.Path .. ": output size mismatch: " .. Name)
    end
    return Count
end
Research.Extract = Extract

---@param Roots string[] Paths relative to the active game module.
---@param Arguments string[]
---@return nil
function Research.Run(Roots, Arguments)
    local DoExtract, Limit, RunName = false, 0, "cross-reference"
    for _, Argument in ipairs(Arguments) do
        if Argument == "--extract" then DoExtract = true
        elseif Argument:match("^%-%-limit=") then Limit = assert(tonumber(Argument:sub(9)))
        elseif Argument:match("^%-%-run=") then RunName = Argument:sub(7)
        else error("unknown argument: " .. Argument) end
    end
    assert(RunName:match("^[%w_-]+$") and Limit >= 0 and Limit % 1 == 0, "invalid run name or limit")
    local OutputRoot = Game_Root .. "/GameFiles/" .. RunName
    sdk.ensure_dir(OutputRoot)
    local Files, Archives = {}, {}
    for _, Root in ipairs(Roots) do Walk(Game_Root .. "/" .. Root, Files) end
    ---@type table<integer, table<string, boolean>>
    local Dictionary = {}
    for _, Path in ipairs(Files) do
        if Path:lower():match("/game%d*%.dat$") or Path:lower():match("%.datwin$") then
            local Archive = Read(Path)
            Archives[#Archives + 1] = Archive
            for _, Entry in ipairs(Archive.Entries) do
                -- Keep Collection name recovery reproducible from retail sources;
                -- adding the optional demo inventory must not rename prior outputs.
                if Entry.Name and not Path:find("/GameFiles/", 1, true) then
                    Dictionary[Entry.Hash] = Dictionary[Entry.Hash] or {}
                    Dictionary[Entry.Hash][Entry.Name] = true
                end
            end
        end
    end
    -- Candidate transformations are hash-checked, never presented as stored filenames.
    ---@type table<integer, table<string, boolean>>
    local Candidates = {}
    for _, Names in pairs(Dictionary) do
        for Name in pairs(Names) do
            local Variants = {(Name:gsub("[Pp][Ss]3", "PS4")), (Name:gsub("360", "PS4")), (Name:gsub("%.[Mm][Ss][Ff]$", ".OGG")), (Name:gsub("%.[Xx][Mm][Aa]$", ".OGG"))}
            for _, Variant in ipairs(Variants) do
                local Value = Hash(Variant)
                Candidates[Value] = Candidates[Value] or {}
                Candidates[Value][Variant] = true
            end
        end
    end
    local Summary = {"Archive\tBytes\tTocOffset\tTocBytes\tVersion\tEntries\tNamed\tRaw\tLZ2K\tLZHAM\tExtracted"}
    for _, Archive in ipairs(Archives) do
        local Key = ArchiveKey(Archive)
        local Rows = {"Index\tHash\tOffset\tStoredBytes\tUnpackedBytes\tCompression\tResolution\tPath\tStoredHead"}
        local Named, Raw, Lz2k, Lzham = 0, 0, 0, 0
        local Handle = assert(io.open(Archive.Path, "rb"))
        for _, Entry in ipairs(Archive.Entries) do
            if not Entry.Name then
                local Choices = Dictionary[Entry.Hash] or Candidates[Entry.Hash]
                if Choices then
                    local Only, Number = nil, 0
                    for Name in pairs(Choices) do Only, Number = Name, Number + 1 end
                    if Number == 1 then
                        Entry.Name, Entry.Resolution = Only, Dictionary[Entry.Hash] and "console-path-hash" or "transformed-path-hash-candidate"
                    else Entry.Resolution = "ambiguous-hash" end
                end
            end
            if Entry.Name then Named = Named + 1 end
            if Entry.Compression == 0 then Raw = Raw + 1 end
            if Entry.Compression == 2 then Lz2k = Lz2k + 1 end
            if Entry.Compression == 4 then Lzham = Lzham + 1 end
            local Head = ReadAt(Handle, Entry.Offset, math.min(8, Entry.StoredSize), Archive.Path)
            local Hex = ""
            for Index = 1, #Head do Hex = Hex .. string.format("%02X", string.unicode(Head, Index, Index)) end
            Rows[#Rows + 1] = string.format("%d\t%08X\t%.0f\t%d\t%d\t%d\t%s\t%s\t%s", Entry.Index, Entry.Hash, Entry.Offset, Entry.StoredSize, Entry.Size, Entry.Compression, Entry.Resolution, Entry.Name or "", Hex)
        end
        Handle.close()
        sdk.write_file(OutputRoot .. "/" .. Key .. ".tsv", table.concat(Rows, "\n") .. "\n")
        local Extracted = 0
        if DoExtract and (Archive.Kind == "datwin" or Archive.Path:find("/WinSteam/", 1, true)) then
            Extracted = Extract(Archive, OutputRoot .. "/assets/" .. Key, Limit)
        end
        local Line = string.format("%s\t%.0f\t%.0f\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d", Archive.Path:sub(#Game_Root + 2), Archive.Size, Archive.TocOffset, Archive.TocSize, Archive.Version, #Archive.Entries, Named, Raw, Lz2k, Lzham, Extracted)
        Summary[#Summary + 1] = Line
        print(Line)
    end
    sdk.write_file(OutputRoot .. "/archives.tsv", table.concat(Summary, "\n") .. "\n")
    print("Inventory written to " .. OutputRoot)
end

return Research
