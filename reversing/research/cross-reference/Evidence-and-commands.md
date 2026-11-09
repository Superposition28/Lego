# Evidence, validation and reproduction

## Scope and source identity

Research date: 2026-11-08, Australia/Sydney. All paths below are relative to the LEGO parent unless stated otherwise. Folder region/build labels are user-supplied labels; the shipped Batman build text is separately recorded in [Containers](Containers.md).

* `Games/Lego_Batman/Source/WinSteam/Batman 2 DC super heroes/`: four Windows archives, shipped file table/build text, loose packages and executable.
* `Games/Lego_Harry_Potter/Source/Collection/Main/`: launcher pair and launcher executables.
* `Games/Lego_Harry_Potter/Source/Collection/Years 1-4/` and `Years 5-7/`: three datwin archives each and standalone shader caches.
* `Games/Lego_Harry_Potter/Source/Orginals/PS3/LEGO Harry Potter - Years 1-4 (Europe) (En,Fr,De,Es,It,Da) (v03.01)/PS3_GAME/USRDIR/`: seven PakDat volumes.
* `Games/Lego_Harry_Potter/Source/Orginals/PS3/LEGO Harry Potter - Years 5-7 (Europe) (En,Fr,De,Es,It,Nl,Da)/PS3_GAME/USRDIR/`: ten PakDat volumes.
* `Games/Lego_Harry_Potter/Source/Orginals/PS3/REA/`: existing report/guide and inspector references read for context. Existing Ghidra databases and old generated comparisons were excluded from recursive inventories.
* `Games/Lego_Harry_Potter/Source/Orginals/Xbox_360/LEGO Harry Potter - Years 1-4 (USA, Europe) (En,Fr,De,Es,It,Da)/`: seven retail volumes.
* `Games/Lego_Harry_Potter/Source/Orginals/Xbox_360/LEGO Harry Potter - Years 5-7 (USA) (En,Fr,De,Es,It,Nl,Pt,Da)/`: two retail volumes.
* `Games/Lego_Harry_Potter/Source/Orginals/The Experience Disc Version 5.5 (Xbox 360)/The.Experience.Disc.Version.5.5.iso`: bounded demo-container inspection and seven recovered volumes; see exact offsets in [Containers](Containers.md).

The additional PS3 v01.02 folder was inventoried as a control and excluded from comparison totals. Nonarchive `.DAT` files such as PS3 `LIC.DAT` are outside PakDat inventory selection. No unlisted titles were scanned to infer compatibility.

### Windows input SHA-256 identities

These digests were read directly from the supplied archive files after extraction; they identify the carriers used in the tables and commands.

| Carrier | SHA-256 |
| --- | --- |
| Batman `GAME.DAT` | `F95600D97BFB06F6BC32CCD5130C036E89C1D890F9BB9AC18DA6B83E3A845983` |
| Batman `GAME0.DAT` | `B14914D3AAE81B29F721D8EE4A25B46586B3E5C87E751C51ADF279BF3790D603` |
| Batman `GAME1.DAT` | `A3806AC25C6B3BD0FFAEF846B655EA6199FC0061BE28FAA2512CDD3792DD9EBA` |
| Batman `GAME2.DAT` | `5C8D97A3199D85D9CE41F24E2C215B5487F7C92345C0CBEFA7642A5201183636` |
| Collection `harry1.datwin` | `AC2467B9AF02BE2682BF747D816E9A7612C9D94B88EF76C0EE0AAB177CBC54DE` |
| Collection `harry1b.datwin` | `B11E2B39DACDD4652799A09B3E24442910AC4B144D512059FE5937E4E48CDC61` |
| Collection `harry1p.datwin` | `5668453478B66E2721CFD8FD7D116605F26CBE73D90DBBEC2265A99A8DDAAB84` |
| Collection `harry2.datwin` | `4D4E1CE91D4A05FFDE9CB5230D4962E75B05EB86C59D0AB568F92B28E52D75C3` |
| Collection `harry2b.datwin` | `14DC9D1E72E3CCC251E3DA8297EB0AE89D063066C4B61FABDE03A51075B8CFEA` |
| Collection `harry2p.datwin` | `C3DDAE22E8160677B76E4F327A0EACE249953BFDF6F7EF704A66FFC6A6EDCF58` |
| Launcher `launcher.pkdwin` | `DD92030315323538A7A81A88A81C1108E9ACE8CABB2A1477C726560510304935` |
| Launcher `launcher.pkiwin` | `D35AA6FBDCC09F77A458659C1EDEFA28707AC55A707AA89F502A54857D6DAF33` |

## Tools and executable evidence

* Remake Engine source checkout HEAD at investigation: `43448035446580270be6c54e3e36dbc5560976f3`; existing local modifications were preserved. LEGO parent HEAD: `a992a986effdc8b4286c00f16ba2094d9643b234`.
* .NET SDK `10.0.401`, Release configuration, project `A:/RemakeEngine/Main/EngineNet`, existing MoonSharp package `2.0.0` from the engine project.
* Managed QuickBMS `0.12.0`, installed/confirmed by Harry Potter operation `-1`. The tool was already present, so the downloader skipped acquisition. The scripts resolve its path using `ResolveToolPath` and use sibling `quickbms_4gb_files.exe` for large offsets. SHA-256: `3A248AB5F9F1DAE7B999B4098CB623372AE29EBAEFBB72F8C359CF3B72D2B5A7`.
* QuickBMS's installed `quickbms.txt` documents inline `-s` commands (example near line 4666) and LZHAM dictionary parameters (near line 2233). The upstream [QuickBMS repository](https://github.com/LittleBigBug/QuickBMS) is the tool reference. Runtime extraction uses inline decoder commands passed as process arguments; **all newly created script files are Lua**. No new BMS, Python, PowerShell or C# script files were created for this workflow.
* REA/Ghidra `12.1.4` opened the supplied Collection `harry1.exe`, SHA-256 `8463776bb720fe5ef3040a3dcd5fd23c5e8e1d04501f9975af9d20378ddabcf1`. `open_binary` followed by `analyze_function` for VA `0x1405B47B0` returned observed parameter initialization: struct size `0x28`, dictionary `0xF`, flags `5`; decoder-loop terminal status `3`. Retained evidence ID: `ev_65428357dc749e23ec0eb5c86f5bb195ac1a39a2681e3e315015769078ded61e`. Function body: `0x1405B47B0..0x1405B4905`. Names/signatures are decompiler reconstructions; indirect-call coverage is partial. This static result corroborates decoder settings; it does not constitute a whole-engine analysis.

Two runtime behaviors required explicit handling: binary `io.read` exposes Latin1 codepoints while MoonSharp `string.byte` replaces some values, so the parser uses documented `string.unicode`. MoonSharp `bit32.bxor` also mishandles the tested unsigned value above `INT_MAX`; TT hashing XORs only the low byte and preserves the upper bits arithmetically. Hash checks against every named entry and synthetic high-byte controls validate these choices. The current runtime has no `string.pack`, `string.unpack`, `string.buffer` or global `utf8`; IDE declarations alone are not proof of runtime support.

## Commands actually used

Run from the real engine root. Release was built successfully for initial CLI discovery. Debug rebuilding initially failed because another engine process held its build outputs; that process was left running. Subsequent concurrent research runs used `--no-build` to reuse the verified Release build and avoid build-output locks.

```pwsh
Set-Location -LiteralPath 'A:\RemakeEngine\Main'
$Configuration = 'Release'
$engineProjDir = 'A:\RemakeEngine\Main\EngineNet'
dotnet run -c $Configuration --project "$engineProjDir" -- --list-games
dotnet run -c $Configuration --no-build --project "$engineProjDir" -- --list-ops Lego_Harry_Potter
dotnet run -c $Configuration --no-build --project "$engineProjDir" -- --list-ops Lego_Batman
dotnet run -c $Configuration --project "$engineProjDir" -- --game_module Lego_Harry_Potter --run_op -1
```

Module-name discovery/execution was verified. `--list-ops` with the explicit nested Harry Potter path returned “not found” in this checkout; therefore the commands use the discovered module names. The parent LEGO context was not used to execute either game's operations. Scripts import the shared Lua implementation by an explicit relative path in this co-located checkout; this does not establish automatic inter-module dependency installation.

Inventory (read-only input access; writes metadata under the active game's `GameFiles/cross-reference`):

```pwsh
dotnet run -c $Configuration --no-build --project "$engineProjDir" -- --game_module Lego_Batman --run_op 10
dotnet run -c $Configuration --no-build --project "$engineProjDir" -- --game_module Lego_Harry_Potter --run_op 10
```

Full Windows extraction was executed using direct Lua scripts and JSON argument arrays:

```pwsh
dotnet run -c $Configuration --no-build --project "$engineProjDir" -- --game_module Lego_Batman --script_type lua --script '{{Game_Root}}/operations/CrossReference.lua' --args '["--extract","--run=windows-full"]'
dotnet run -c $Configuration --no-build --project "$engineProjDir" -- --game_module Lego_Harry_Potter --script_type lua --script '{{Game_Root}}/operations/CrossReference.lua' --args '["--extract","--run=windows-full"]'
```

First-five-per-archive sample runs used `--limit=5` and fresh run names `sample-check` and `chunk-check`. Full runs have no limit. Do not reuse an existing extraction run name: asset directories are refused rather than overwritten. Use a fresh `--run=NAME` to reproduce extraction. Inventories can be regenerated without extracting.

Launcher/demo extraction and comparison:

```pwsh
dotnet run -c $Configuration --no-build --project "$engineProjDir" -- --game_module Lego_Harry_Potter --script_type lua --script '{{Game_Root}}/operations/InspectContainers.lua' --args '["--extract"]'
dotnet run -c $Configuration --no-build --project "$engineProjDir" -- --game_module Lego_Harry_Potter --run_op 12
dotnet run -c $Configuration --no-build --project "$engineProjDir" -- --game_module Lego_Harry_Potter --script_type lua --script '{{Game_Root}}/operations/CompareFormats.lua'
dotnet run -c $Configuration --no-build --project "$engineProjDir" -- --game_module Lego_Harry_Potter --script_type lua --script '{{Game_Root}}/operations/ValidateArchiveParser.lua'
```

The container extraction command requires absent destinations under `GameFiles/container-research`; operation 12 safely reinspects existing input without extracting. The comparator requires both games' exported inventories and the seven recovered demo archives. It reads Batman's exported metadata and uses its original archive paths for small samples; full Batman extraction remains a Batman-context operation. Existing sample files are size checked and reused when recomputing the report. Do not run inventory/sample extraction against a source archive simultaneously held open by another extraction process.

## Results and local artifacts

| Output | Verified result |
| --- | --- |
| Batman `GameFiles/windows-full/assets/` | 11,865 files, 6,464,138,301 bytes; all output sizes match archive records. |
| Harry Potter `GameFiles/windows-full/assets/` | 34,612 files, 26,950,462,847 bytes; all output sizes match archive records. |
| Harry Potter `GameFiles/container-research/launcher-assets/` | 401 files, 183,143,304 bytes; all zlib streams decoded and output sizes checked. |
| Harry Potter `GameFiles/container-research/demo-archives/` | Seven recovered PakDat archives; all TOCs parsed and named hashes checked. |
| Each game's `GameFiles/cross-reference/` | `archives.tsv` plus per-archive member TSVs: offsets, sizes, hashes, compression, name provenance and stored leading bytes. |
| Harry Potter `GameFiles/format-comparison/` | `extensions.tsv`, `path-overlap.tsv`, `sample-signatures.tsv`, `equal-samples.tsv`; 245 decoded samples with signatures and SHA-1. |
| Harry Potter `GameFiles/container-research/` | Launcher index metadata, demo member/block metadata and bounded shader-header observations. |
| Harry Potter `GameFiles/parser-checks/` | Synthetic fixtures only; 24 parser cases passed, plus TT hash normalization and high-byte controls. |

Parser cases cover valid raw datwin/PakDat, truncated headers/TOCs, invalid counts/canaries/flags, out-of-bounds payloads, raw size inconsistency, offsets beyond exact MoonSharp integer range, invalid signature, invalid sibling/leaf/name offsets, unterminated names and name/hash mismatch. Representative LZ2K and LZHAM extraction samples passed. The shared extractor also rejects invalid chunk spans before decoding. Full Windows extraction is archive unpacking; internal package/model/texture correctness beyond the sampled observations is outside this validation.

Operation manifests expose inventory/extraction as IDs 10/11 in each game; Harry Potter adds container inspection/extraction 12/13, comparison 14 and parser validation 15. Original console operations 1/2 and their existing BMS script are retained. All new game entry scripts live in their respective game modules. No engine source changes, commits, submodule-pointer updates, source-file moves or changes to existing REA databases were made for this task.
