# Game Research: LEGO Dimensions (TT Games)

## 1. Title Overview & Inspected Builds
*LEGO Dimensions* (September 2015) is TT Games' Toys-to-Life crossover title built on the **Era 4a `Cinema` (NXG/DX11)** engine. It integrates a physical 3-zone USB NFC Toy Pad with dynamic portal world streaming across 30+ franchises.

### Locally Inspected Builds & Hardware Artifacts
- **PlayStation 3 Retail Discs (`D:\PS3\Lego Dimensions\`):**
  - **Europe (`BLES02158`):** `LEGO Dimensions (Europe) (En,Fr,De,Nl,Da).iso` (`24,269,553,664` bytes)
  - **USA (`BLUS31456`):** `LEGO Dimensions (USA) (En,Fr,Es).iso` (`24,269,488,128` bytes)
  - **Executable (`PS3_GAME/USRDIR/EBOOT.BIN`):** `32,733,296` bytes (`SCE\0` SELF64 PPU executable).
- **Physical NFC Toy Tag Dumps (`D:\PS3\Lego Dimensions\chars\*.bin`):**
  - **47 NTAG213 NFC tag dumps** (`180` bytes each = 45 pages × 4 bytes/page), covering starter pack characters (`Batman.bin`, `Gandalf`, `Wyldstyle`), vehicles (`BatMobile.bin`, `Tardis.bin`, `Exto-1-Car.bin`, `Gost_Trap.bin`), and Adventure World characters (`The Doctor.bin`, `Peter Venkman.bin`, `Chell`, `Bart Simpson`, `Sonic`, `Supergirl Red Lantern-769.bin`, etc.).

---

## 2. Archive Architecture: Split `.HDR` + `.DAT` (`Version = -7`) & `CMP2` Install Packages

Unlike earlier console titles that only store the TOC at the end of `GAME*.DAT`, *LEGO Dimensions* pairs every archive volume with an external `.HDR` file and splits large `.DAT` volumes across ISO9660 multi-extent records (`1,073,739,776` B per extent):

| Volume Pair | Total `.DAT` Bytes | `.HDR` Bytes | TOC Version | Files (`N`) | 12B Nodes (`M`) | Raw (`0`) | `DFLT` (`3`) | Notes |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | :--- |
| `GAME.DAT` / `.HDR` | `462,531,383` | `1,912,123` | `-7` | `19,000` | `24,085` | `15,105` | `3,895` | Base engine, UI, global `legotpage` |
| `GAME0.DAT` / `.HDR` | `2,136,519,834` | `1,151,902` | `-7` | `12,016` | `13,719` | `9,244` | `2,772` | 2 ISO extents; character icons, audio, `.an4` |
| `GAME1.DAT` / `.HDR` | `2,135,008,960` | `36,804` | `-7` | `373` | `378` | `373` | `0` | 2 ISO extents; cutscene `.msf` audio streams |
| `GAME2.DAT` / `.HDR` | `908,610,307` | `1,893,127` | `-7` | `19,000` | `19,220` | `19,000` | `0` | `18,870` `.cbx` lip-sync/dialogue + `130` `.msf` |
| `GAME3.DAT` / `.HDR` | `1,879,394,319` | `1,809,427` | `-7` | `19,000` | `20,877` | `8,330` | `10,670` | 2 ISO extents; story levels, `.led`, `.gsc`, `.cu3` |
| `GAME4.DAT` / `.HDR` | `2,123,080,398` | `869,074` | `-7` | `8,808` | `9,475` | `3,530` | `5,278` | 2 ISO extents; hubs, `.lxfml`, `.baml`, `trackedfilelist_360.txt` |
| `GAME5.DAT` / `.HDR` | `1,645,124,701` | `78,689` | `-7` | `750` | `1,017` | `548` | `202` | 2 ISO extents; `.png` UI, `.fmv`, `.ft2`, `.tsh` |
| `INSTALL0_.DAT` / `.HDR` | `46,460,636` | `1,980,144` | `-7` | `19,000` | `25,189` | `17,663` | `1,337` | `CMP2CMP2CMP2CMP2` LZMA stream (`179,270,380` B unpacked) |
| `INSTALL0_0.DAT` / `.HDR` | `62,711,782` | `2,009,913` | `-7` | `19,000` | `26,096` | `16,387` | `2,613` | `CMP2CMP2CMP2CMP2` LZMA character/vehicle cache |
| `INSTALL0_1.DAT` / `.HDR` | `59,556,644` | `807,873` | `-7` | `7,769` | `10,506` | `6,185` | `1,584` | `CMP2CMP2CMP2CMP2` LZMA character/vehicle cache |
| **Total (10 volumes)** | **`11,458,998,964`** | **`12,549,076`** | **`-7`** | **`124,716`** | **`150,562`** | **`96,365`** | **`28,351`** | Plus `12.56 GB` `PAD.DAT` zero-fill dummy file |

### Technical Details of TOC `Version = -7`
1. **`.HDR` Mirror:** Each `.HDR` file begins with a 4-byte **big-endian** `uint32_t TocSize` followed by the exact byte-for-byte TOC stored at the end of the corresponding `.DAT` volume (`TocSize == HdrFileSize - 4`).
2. **12-Byte Name Nodes & Non-Sequential `-Child` Indexing:** Each `NameNode` is 12 bytes (`int16_t Child`, `int16_t PrevSibling`, `uint32_t NameOffset`, `uint32_t Metadata`). For every leaf node (`Child <= 0`), `-Child` is the direct `EntryIndex` (`0..Files-1`) in `Entries[]` and `PathHashes[]` (**verified `19,000/19,000` = `100%` exact `TtPathHash` match in `GAME.HDR`**).
3. **Trailing `ROTV` Suffix Tables:** Immediately after `PathHashes[Files]`, TOC `-7` stores a null-terminated root prefix string + 24 zero bytes + two `"ROTV"` (`52 4F 54 56`) blocks, each prefixed by big-endian `uint32_t Files` and followed by `Files * 16` bytes (`32 * Files + 41` bytes total when the root prefix is empty).
4. **Chunked `DFLT` Compression (`CompressionType = 3`):** Compressed entries consist of 12-byte `"DFLT"` chunk headers (`"DFLT"`, `uint32_t CompressedSize`, `uint32_t UncompressedSize` up to `0x8000` = 32 KiB) followed by raw RFC 1951 Deflate payloads.
5. **Whole-Archive `CMP2` LZMA Wrapper (`INSTALL0_*.DAT`):** Starts with 16-byte `"CMP2CMP2CMP2CMP2"`, 16-byte hash, `uint64_t DecompressedSize`, and a 5-byte LZMA properties header (`5D 00 00 00 02`, 32 MiB dictionary) at `0x28`.

---

## 3. NFC Toy Tag Binary Format (`180` Bytes / NTAG213)
- **Pages `0x00..0x02` (Bytes `0x00..0x0B`):** 7-byte NXP NTAG213 hardware UID (`04 ...`) + check bytes (`BCC0`, `BCC1`) and lock bits (`80 00`).
- **Pages `0x24..0x25` (Bytes `0x90..0x97`, Pages 36–37):**
  - **Character Tags:** 8-byte payload encrypted with a 32-round **TEA (Tiny Encryption Algorithm)** cipher using a key derived from the tag's 7-byte UID (`Batman.bin` -> `60 5F 22 CC E7 BE 8E 17`, `The Doctor.bin` -> `10 CD 94 02 AB 1E AC 91`).
  - **Vehicle / Gadget Tags (`Page 0x26 == 0x00010000`):** Unencrypted little-endian 16-bit vehicle ID at `0x90..0x91` (`BatMobile.bin` -> `0x03EE = 1006`, `Tardis.bin` -> `0x0406 = 1030`, `Exto-1-Car.bin` -> `0x0460 = 1120`, `Gost_Trap.bin` -> `0x0463 = 1123`) plus upgrade bitmasks on pages `0x23..0x25`.
- **Page `0x2B` (Bytes `0xAC..0xAF`, Page 43):** 4-byte NTAG213 `PACK`/password authentication key derived from the UID.
