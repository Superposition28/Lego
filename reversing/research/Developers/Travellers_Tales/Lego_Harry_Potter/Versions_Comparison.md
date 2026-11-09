# Version & Platform Comparison: LEGO Harry Potter

## 1. Audited Builds & Provenance

| Build / Edition | Platform | Serial / Title ID | Version / Media ID | Primary Executable | Archive Format | Total Audited Size |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Years 1-4 (EU Retail)** | PS3 | `BLES-00779` | `v01.02` (FW `03.3000`) | `EBOOT.BIN` (`10,223,392` B PPC64 SELF) | `PakDat v1.01` (`GAME.DAT`..`GAME6.DAT`) | `8,652,652,544` B (ISO) |
| **Years 1-4 (EU Rev 2)** | PS3 | `BLES-00779` | `v03.01` (FW `03.3000`) | `EBOOT.BIN` (`11,100,672` B PPC64 SELF) | `PakDat v1.01` (`GAME.DAT`..`GAME6.DAT`) | `8,629,190,656` B (ISO) |
| **Years 5-7 (EU Retail)** | PS3 | `BLES-01297` | `v01.00` (FW `03.7200`) | `EBOOT.BIN` (`13,621,064` B PPC64 SELF) | `PakDat v1.01` (`GAME.DAT`, `GAME0`..`GAME8.DAT`) | `10,068,033,536` B (ISO) |
| **Years 1-4 (US/EU Retail)** | Xbox 360 | `WR-2022` / `0x575207E6` | `v0.0.0.2` / Media `0x3E371834` | `Default.xex` (`6,963,200` B `XEX2` -> `legogame_Final_360.exe`) | `PakDat v1.01` (`GAME.DAT`..`GAME6.DAT`) | `7,838,695,424` B (XGD2 ISO) |
| **Years 5-7 (US Retail)** | Xbox 360 | `WR-2066` / `0x57520812` | `v0.0.0.5` / Media `0x61D8E1DE` | `Default.xex` (`5,189,632` B `XEX2` -> `harry2.master.pe`) | `PakDat v1.01` (`GAME.DAT`, `GAME0.DAT`) | `8,738,846,720` B (XGD3 ISO) |
| **Years 1-4 (Kiosk Demo)** | Xbox 360 | `XK-2123` / `0x575287FF` | Experience Disc v5.5 (2010-08) | `Default.xex` (`6,582,272` B `XEX2`) | `PakDat v1.01` (`GAME.DAT`..`GAME6.DAT` in `PIRS`) | `697,393,152` B (`PIRS` inside `7.83 GB` ISO) |
| **Collection: Years 1-4** | PC (Steam) | Steam App `2950340` | Remastered (`v1.0.0.1`) | `harry1.exe` (`22,630,352` B PE32+) | `.datwin` (`harry1`, `harry1b`, `harry1p`) | `~6.35 GB` |
| **Collection: Years 5-7** | PC (Steam) | Steam App `2950340` | Remastered (`v1.0.0.1`) | `harry2.exe` (`23,604,176` B PE32+) | `.datwin` (`harry2`, `harry2b`, `harry2p`) | `~7.71 GB` |

### Local ISO & Extracted Source Locations
- **PS3 Retail ISOs & Extracted Trees:**
  - `B:\Dev_Data\ISO.Dev.Games\PS3\LEGO Harry Potter\` and `D:\PS3\LEGO Harry Potter\` (`v01.02`: `8,652,652,544` bytes; `v03.01`: `8,629,190,656` bytes; `Years 5-7`: `10,068,033,536` bytes).
  - Extracted `PS3_GAME` trees reside under `Games/Lego_Harry_Potter/Source/Orginals/PS3/`.
- **Xbox 360 Retail ISOs & Extracted Trees:**
  - `Games/Lego_Harry_Potter/Source/Orginals/Xbox_360/LEGO Harry Potter - Years 1-4 (USA, Europe) (En,Fr,De,Es,It,Da).iso` (`7,838,695,424` bytes, XGD2 partition at `0x0FD90000`). Extracted to `Games/Lego_Harry_Potter/Source/Orginals/Xbox_360/LEGO Harry Potter - Years 1-4 (USA, Europe) (En,Fr,De,Es,It,Da)/` (`12` files + unpacked `Default_unpacked.xex`, `Default.pe`, `Default.idc`).
  - `Games/Lego_Harry_Potter/Source/Orginals/Xbox_360/LEGO Harry Potter - Years 5-7 (USA) (En,Fr,De,Es,It,Nl,Pt,Da).iso` (`8,738,846,720` bytes, XGD3 partition at `0x02080000`). Extracted to `Games/Lego_Harry_Potter/Source/Orginals/Xbox_360/LEGO Harry Potter - Years 5-7 (USA) (En,Fr,De,Es,It,Nl,Pt,Da)/` (`37` files + unpacked `Default_unpacked.xex`, `Default.pe`, `Default.idc`).
- **Xbox 360 Kiosk Demo ISO (`The Experience Disc Version 5.5`):**
  - `Games/Lego_Harry_Potter/Source/Orginals/The Experience Disc Version 5.5 (Xbox 360)/The.Experience.Disc.Version.5.5.iso` (`7,838,695,424` bytes, MD5 `fb357ef6a1cd4496545fdd896792b835`, SHA-1 `373651f01dbb710da45115faf9d7845d8725b89d`).
  - Contains `content/0000000000000000/575287FF/00080000/F016B45400D379BBC11F7A9E621771400E2A3A9057` (`PIRS` STFS container at ISO offset `0x3EBAD000`, `697,393,152` bytes, Media ID `0x05E535C2`, Title ID `0x575287FF`).

---

## 2. Years 1-4 Archive Volume Comparison (PS3 vs. Xbox 360 Retail vs. Xbox 360 Demo vs. PC)

Both PS3 (`BLES-00779`) and Xbox 360 (`Title ID 0x575207E6`) were built from the **exact same SCM stream and transaction** (`Changelog for stream Harry_DISCBUILD at transaction 2811590`, verified via `builds\ps3\changelog_release.txt` and `builds\360\changelog_release.txt`, both `654,134` bytes / `6,683` lines) and report `Current version: 38.2` in `framework-data\frameworkdataversion.txt`.

| Volume | PS3 Retail (`v01.02` & `v03.01`) | Xbox 360 Retail (`0x575207E6`) | Xbox 360 Demo (`0x575287FF`) | Role & Cross-Platform Differences |
| :--- | :--- | :--- | :--- | :--- |
| `GAME.DAT` | `1,222,811,541` B (`5,607` files) | `1,222,842,833` B (`5,608` files) | `481,842,593` B (`2,519` files) | Core engine, UI, characters, Year 1 hub/shared assets |
| `GAME1.DAT` | `886,649,775` B (`1,180` files) | `856,397,803` B (`1,170` files) | `129,791,211` B (`226` files) | Year 1 levels (`+10` PS3 files in `y1darkarts`) |
| `GAME2.DAT` | `1,052,633,420` B (`1,119` files) | `1,052,633,420` B (`1,119` files) | `104,242` B (`67` files) | Year 2 levels — **exact same byte size, `TocOffset`, `TocSize`, and `DataOffset`s on PS3 & Xbox 360!** (`30` `ai.pak` entries differ by `< 10` compressed bytes within the 256-byte sector alignment quantum) |
| `GAME3.DAT` | `1,231,650,067` B (`1,351` files) | `1,231,650,067` B (`1,351` files) | `115,235` B (`74` files) | Year 3 levels — **exact same byte size, `TocOffset`, `TocSize`, and `DataOffset`s on PS3 & Xbox 360!** (`42` `ai.pak` entries differ by `< 10` compressed bytes within sector alignment) |
| `GAME4.DAT` | `925,178,675` B (`1,069` files) | `925,179,187` B (`1,087` files) | `108,270` B (`68` files) | Year 4 levels |
| `GAME5.DAT` | `268,948,592` B (`445` files) | `471,363,140` B (`668` files) | `33,188,912` B (`43` files) | Cutscenes & hub assets (`_ps3.cu2` vs `_360.cu2`, `.msf` vs `.xma`) |
| `GAME6.DAT` | `368,266,248` B (`387` files) | `975,116,892` B (`146` files) | `41,482,976` B (`15` files) | Streamed music/cutscene audio (`0` compressed in Xbox 360 `GAME6.DAT`: raw `.xma` streams) |
| **Total** | **`5,956,138,318` B (`11,158` files)** | **`6,735,183,342` B (`11,149` files)** | **`686,633,439` B (`3,012` files)** | PC uses `harry1.datwin` (`4,579`), `harry1b.datwin` (`10,236`), `harry1p.datwin` (`14`) = `14,819` unique hashes |

---

## 3. Years 5-7 Archive Volume Comparison (PS3 vs. Xbox 360 Retail vs. PC)

In *Years 5-7*, PS3 splits game data across 10 `PakDat v1.01` files (`GAME.DAT` + `GAME0.DAT`..`GAME8.DAT`), whereas **Xbox 360 consolidates all `14,221` files into just 2 large (`~4 GB`) `PakDat v1.01` files (`GAME.DAT` and `GAME0.DAT`)**, both using negative 256-byte sector-shifted TOC offsets (`TocOffset = (-RawTocOffset) << 8`), plus 34 external `*.bik` (`BIKi`) Bink video files in `videos/`:

| Platform | Archives | Total Archive Size | Total Files | Compressed Files (`LZ2K` / `LZHAM`) | External Videos |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **PS3 (`BLES-01297`)** | `GAME.DAT` (`3.20 GB`, `4,650`) + `GAME0..GAME8.DAT` (`9,614`) | `8,452,071,599` B | `14,264` | `6,869` (`LZ2K`) | `34` `.PAM` in `VIDEOS/` |
| **Xbox 360 (`0x57520812`)** | `GAME.DAT` (`4,138,952,216` B, `5,264`) + `GAME0.DAT` (`3,983,439,336` B, `8,957`) | `8,122,391,552` B | `14,221` | `6,833` (`LZ2K`) | `34` `.bik` in `videos/` |
| **PC Steam (`Collection`)** | `harry2.datwin` (`7,133`) + `harry2b.datwin` (`12,627`) + `harry2p.datwin` (`23`) | `7,458,632,317` B | `19,783` (`19,764` unique) | `18,162` (`LZHAM`) | `34` `.bik` in `videos/` |

---

## 4. Quantitative 3-Way File & Asset Comparison (`ComparePlatforms.ps1`)

Running [`ComparePlatforms.ps1`](file:///a:/RemakeEngine/Main/EngineApps/Games/Lego/Games/Lego_Harry_Potter/reversing/tools/ComparePlatforms.ps1) across all six builds establishes the exact cross-platform asset relationships:

| Metric | LEGO Harry Potter: Years 1-4 | LEGO Harry Potter: Years 5-7 | Architectural Explanation |
| :--- | :--- | :--- | :--- |
| **Total Unique Archive Files** | PS3: `11,158` \| X360: `11,149` \| PC: `14,819` | PS3: `14,264` \| X360: `14,221` \| PC: `19,764` | PC unpacks individual `.wav` SFX & adds `_an3_ps4.pak` / `_cbs_ps4.pak` / `.cpd` |
| **PS3 <-> Xbox 360 Shared Paths** | **`10,333`** (`92.7%` of Xbox 360) | **`13,445`** (`94.5%` of Xbox 360) | Identical directory hierarchy and `_nxg` asset naming |
| **PS3 <-> Xbox 360 Same `UncompSize`** | **`10,329 / 10,333` (`99.96%`)** | **`13,445 / 13,445` (`100.00%`)** | Both Cell PPU (PS3) and Xenon (Xbox 360) are 64-bit Big-Endian PowerPC sharing identical `_nxg.gsc`, `_nxg.ghg`, `_nxg.tex` binaries |
| **PS3 <-> Xbox 360 Same `CompSize`** | **`10,187 / 10,333` (`98.59%`)** | **`13,424 / 13,445` (`99.84%`)** | Identical `LZ2K` compressed streams across nearly all shared files |
| **Cutscene Counterparts (`.cu2`)** | `523` `*_ps3.cu2` <-> `523` `*_360.cu2` <-> `523` `*_ps4.cu2` (PC) | `506` `*_ps3.cu2` <-> `505` `*_360.cu2` <-> `506` `*_ps4.cu2` (PC) | PC Steam Collection retains the **PS4 remaster** (`_ps4.cu2`) cutscene naming! |
| **Streamed Audio Counterparts** | `289` `.msf` (PS3) <-> `289` `.xma` (X360) <-> `289` `.ogg` (PC) | `261` `.msf` (PS3) <-> `261` `.xma` (X360) <-> `261` `.ogg` (PC) | Exact 1-to-1 track parity across Sony `.msf`, Xbox `.xma`, and PC Vorbis `.ogg` |
| **SoundFX Storage** | Packed in `audio\level_sfx\*.bsa` / `*.cbx` | Packed in `audio\level_sfx\*.bsa` / `*.cbx` | PC unpacks `~1,750` individual `RIFF WAVE` (`Audio\_SoundFX\**\*.wav`) files into `harry1.datwin` / `harry2.datwin` |
| **PC Remaster Companion Files** | `_an3_ps4.pak`, `_cbs_ps4.pak`, `_cbs.pak`, `.cpd`, `GNF ` & `DDS ` CJK fonts | `_an3_ps4.pak`, `_cbs_ps4.pak`, `_cbs.pak`, `.cpd`, `GNF ` & `DDS ` CJK fonts | Double Eleven's 2016 PS4 remaster pipeline (`_ps4.pak`, Sony `GNF ` textures in `harry*p.datwin`) was carried directly into the PC Steam port |
| **Console vs. PC Script Preprocessor** | Console `.txt`/`.cfg` stripped of comments (`levels.txt`: `61,643` B) | Console `.txt`/`.cfg` stripped of comments (`levels.txt`: `104,872` B) | PC `.datwin` preserves **unstripped developer comments** (`//`, `;`) and original indentation (`levels.txt`: `75,594` B / `134,409` B), whereas `stuff\game.txt` is 100% SHA-256 identical across all 3 platforms |
| **Total Resolved PC `.datwin` Paths** | **`12,975 / 14,829` (`87.5%`)** | **`16,568 / 19,783` (`83.7%`)** | Resolved via Console `PakDat` string tables + remaster rules + `.txt`/`.cfg`/`.cd`/`.as` string harvesting |

---

## 5. Architectural Evolution: `PakDat v1.01` vs. `datwin`

| Feature | `PakDat v1.01` (PS3 / Xbox 360) | `datwin` (PC Steam Collection) |
| :--- | :--- | :--- |
| **Header Size** | `52` bytes (`int32 RawTocOffset`, `uint32 TocSize`, 44-byte signature) | `16` bytes (`int64 TocOffset`, `uint64 TocSize`) |
| **TOC Placement** | Trailing (at end of each `.DAT`: `TocOffset + TocSize == FileSize`) | Trailing (at end of each `.datwin`: `TocOffset + TocSize == FileSize`) |
| **`>= 2 GB` Offset Handling** | Negative 256-byte sector index: `TocOffset = (-RawTocOffset) << 8` | Native 64-bit byte offset (`int64_t`) |
| **TOC Version Marker** | `-4` (`0xFFFFFFFC`) | `-1` (`0xFFFFFFFF`) |
| **File Entry Record** | `16` bytes (`OffsetSector`, `CompSize`, `UncompSize`, `Type`, `SubSec`) | `24` bytes (`uint64 Offset`, `0x12345678`, `CompSize`, `UncompSize`, `Flags`) |
| **Directory & String Table** | Embedded (`8`-byte `PakDatNameNode[M]` + ASCII `StringTable[S]`) | Stripped (uses `uint32 PathHashes[N]` only) |
| **Path Hash Algorithm** | `TtPathHash` (`seed 0x811C9DC5`, `prime 0x00199933`) | Identical `TtPathHash` (`seed 0x811C9DC5`, `prime 0x00199933`) |
| **Primary Compression** | `CompressionType = 2` (`LZ2K` 32 KB chunked compression) | `CompressionType = 4` (`LZHAM`, `0E C6` header, 32 KB window, Adler32) |
| **Volume Slicing** | `GAME.DAT` + `GAME1..6.DAT` (Y1-4) or `GAME.DAT` + `GAME0.DAT` (X360 Y5-7) / `GAME0..8.DAT` (PS3 Y5-7) | Base (`harry1`/`2`), Bulk (`harry1b`/`2b`), Patch (`harry1p`/`2p`) |
