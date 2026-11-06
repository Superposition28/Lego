# TT Games File Formats: LEGO Harry Potter

## 1. The `datwin` Package Format (PC Steam Collection)

The modern PC remaster of LEGO Harry Potter packages its assets inside `.datwin` archives (`harry1.datwin`, `harry1b.datwin`, `harry1p.datwin`, `harry2.datwin`, `harry2b.datwin`, `harry2p.datwin`). Note that inside [`harry1.exe`](file:///a:/RemakeEngine/Main/EngineApps/Games/Lego/Games/Lego_Harry_Potter/Source/Collection/Years%201-4/harry1.exe) at `File 0x935A48` (`RVA 0x937448`), the engine constructs these filenames by appending `"WIN"` (`RVA 0x937474`) to `"HARRY1.DAT"`, `"HARRY1B.DAT"`, and `"HARRY1P.DAT"`.

### 1.1 Header Structure (First 16 Bytes)
At byte offset `0x00`, `.datwin` stores a 16-byte header pointing to a Table of Contents at the **end of the file** (read at `VA 0x14052E0C0` / `File 0x52D4C0` in `harry1.exe`):

```c
// Offset 0x00 from start of file
struct DatwinFileHeader {
    int64_t  TocOffset; // [0x00..0x07] Absolute byte offset where the trailing TOC starts
    uint64_t TocSize;   // [0x08..0x0F] Exact byte length of the trailing TOC block
};
```
*(Note: `VA 0x14052E0D9` also retains the legacy negative sector shift check `if (TocOffset < 0) TocOffset = (-TocOffset) << 8;` from 32-bit `PakDat`, though all PC `.datwin` files store positive 64-bit byte offsets directly.)*

### 1.2 The Integrity & Exact TOC Size Invariants
Every valid `.datwin` archive satisfies two exact mathematical invariants across all six archives:
1. **File Boundary Invariant:**
   $$\text{TocOffset} + \text{TocSize} == \text{TotalFileSize}$$
2. **TOC Size Invariant (`Version = -1`):**
   $$\text{TocSize} == 8 + 24 \times N + 4 \times N == 8 + 28 \times N$$
   where $N$ is `FileCount` (`uint32_t` at `TocOffset + 4`).

Empirical verification across all six PC Collection archives:
| Archive | `TocOffset` | `TocSize` | `TotalFileSize` | `FileCount` ($N$) | LZHAM Compressed | Raw | PS3 Path Match |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `harry1.datwin` | `548,740,081` (`0x20B51BF1`) | `128,220` (`0x1F4DC`) | `548,868,301` | `4,579` | `2,827` | `1,752` | `2,327` (`50.8%`) |
| `harry1b.datwin` | `5,672,380,832` (`0x15219A9A0`) | `286,616` (`0x45F98`) | `5,672,667,448` | `10,236` | `10,236` | `0` | `7,352` (`71.8%`) |
| `harry1p.datwin` | `42,248,289` (`0x284A861`) | `400` (`0x190`) | `42,248,689` | `14` | `10` | `4` | `2` (`14.3%`) |
| `harry2.datwin` | `1,136,817,166` (`0x43C2740E`) | `199,732` (`0x30C34`) | `1,137,016,898` | `7,133` | `5,516` | `1,617` | `2,832` (`39.7%`) |
| `harry2b.datwin` | `6,277,086,910` (`0x17624BEBE`) | `353,564` (`0x5651C`) | `6,277,440,474` | `12,627` | `12,627` | `0` | `10,933` (`86.6%`) |
| `harry2p.datwin` | `44,174,293` (`0x2A20BD5`) | `652` (`0x28C`) | `44,174,945` | `23` | `19` | `4` | `9` (`39.1%`) |

### 1.3 Trailing Table of Contents (TOC) Layout
Decompiled from `NuFileDeviceDat::LoadToc` at `VA 0x14052E240` (`File 0x52D640`) and entry reader at `VA 0x14052D1C0` (`File 0x52C5C0`) in `harry1.exe`:

```c
// At byte position TocOffset:
struct DatwinToc {
    int32_t         Version;            // [0x00..0x03] Always -1 (0xFFFFFFFF) in .datwin
    uint32_t        FileCount;          // [0x04..0x07] Number of files (N)
    DatwinFileEntry Entries[FileCount]; // [0x08 .. 0x08 + 24*N - 1]
    uint32_t        PathHashes[FileCount]; // [0x08 + 24*N .. 0x08 + 28*N - 1]
};

struct DatwinFileEntry { // 24 bytes (0x18)
    uint64_t DataOffset;       // [0x00..0x07] Absolute byte offset in .datwin (Entry[0] starts at 0x10)
    uint32_t Canary;           // [0x08..0x0B] Always 0x12345678 (78 56 34 12 LE)
    uint32_t CompressedSize;   // [0x0C..0x0F] Stored byte length in payload
    uint32_t UncompressedSize; // [0x10..0x13] Decompressed byte length
    uint8_t  CompressionType;  // [0x14] 0x00 = raw, 0x04 = LZHAM (stored as 0x04040404 across [0x14..0x17])
    uint8_t  Pad[2];           // [0x15..0x16] Repeated 0x0404 or 0x0000
    uint8_t  SubSectorOffset;  // [0x17] Used only when Version <= -4; in .datwin repeats CompressionType
};
```
*(Note: Unlike `PakDat v1.01`, `.datwin` omits the `NameNodes` tree and `StringTable`. At load time (`VA 0x14052E400`), the engine selection-sorts `PathHashes[N]` and `Entries[N]` in ascending hash order for binary search lookup.)*

### 1.4 Payload Compression (`CompressionType` Dispatch & `LZHAM`)
In `NuFileStreamDat::Read` (`VA 0x1405367A0` / `File 0x535BA0`), the engine dispatches on `Entry.CompressionType`:
- **`0` (`0x00000000`):** Uncompressed raw stream (`VA 0x140536A60`).
- **`2` (`0x02`):** **LZ2K** chunked compression (`"LZ2K"` magic `0x4B325A4C`, decompressed via `VA 0x1404D4A50`). Used in PS3 and Xbox 360 `PakDat v1.01` archives.
- **`3` (`0x03`):** **Zlib Deflate** (`zlib 1.2.3`, `VA 0x1405B4380`).
- **`4` (`0x04` / `0x04040404`):** **LZHAM** (`VA 0x1405B47B0` -> `lzham_decompress_init` at `VA 0x1405D9410`, `lzham_decompress` at `VA 0x1405D93F0`, `lzham_decompress_deinit` at `VA 0x1405D9400`; built from `E:\BuildAgent\work\a6d6b8eb0767cd34\d11-engine\Inc\lzham\lzhamdecomp\`).
  - Initialized with 40-byte `lzham_decompress_params`:
    - `m_struct_size = 40` (`0x28`)
    - `m_dict_size_log2 = 15` (`0x0F`, 32 KB window)
    - `m_table_update_rate = 0` (default = 8)
    - `m_decompress_flags = 5` (`LZHAM_DECOMP_FLAG_OUTPUT_UNBUFFERED (1) | LZHAM_DECOMP_FLAG_READ_ZLIB_STREAM (4)`)
  - Every compressed stream in `.datwin` starts with the 2-byte LZHAM zlib header **`0E C6`**:
    - `CMF = ((dict_size_log2 - 15) << 4) | LZHAM_Z_LZHAM = (0 << 4) | 14 = 0x0E`
    - `FLG = 0xC6` such that `(0x0E * 256 + 0xC6) = 3782 = 31 * 122` (`0x0EC6 % 31 == 0`)
    - Followed by the LZHAM bitstream and a 4-byte big-endian **Adler32** checksum of the uncompressed payload.

---

## 2. The `PakDat v1.01` Package Format (PS3 & Xbox 360)

Every `GAME*.DAT` volume on PlayStation 3 (`GAME.DAT` through `GAME6.DAT` in Years 1-4; `GAME.DAT` and `GAME0.DAT` through `GAME8.DAT` in Years 5-7) and Xbox 360 (`GAME.DAT` through `GAME6.DAT`) is a **standalone, self-contained `PakDat v1.01` archive** with its own trailing Table of Contents, directory tree, string table, and hash index.

### 2.1 Header Structure (`0x00..0x33`)
```c
struct PakDatHeader {
    int32_t  RawTocOffset; // [0x00..0x03] Signed TOC offset (byte offset if >= 0; negated 256-byte sector index if < 0)
    uint32_t TocSize;      // [0x04..0x07] Exact byte length of trailing TOC block
    char     Signature[44];// [0x08..0x33] "BEGIN_APP_ID_STRINGPakDat v1.01END_APP_ID_STRING\0"
};
```
- **`>= 2 GB` Negative Sector-Shifted Offset Formula (verified at `VA 0x14052E0D9` in `harry1.exe`):**
  - If `RawTocOffset >= 0`: `TocOffset = (uint64_t)(uint32_t)RawTocOffset`.
  - If `RawTocOffset < 0` (used when `TocOffset >= 0x80000000`, e.g. PS3 Years 5-7 `GAME.DAT` where `RawTocOffset = 0xFF41ACA0 = -12,473,184`):
    $$\text{TocOffset} = (-\text{RawTocOffset}) \ll 8$$
    (`12,473,184 * 256 = 3,193,135,104 = 0xBE536000`, plus `TocSize = 338,308 = 0x52984` equals `TotalFileSize = 3,193,473,412` with zero remainder).
- **Universal Integrity Invariant:** `TocOffset + TocSize == TotalFileSize` holds across all 17 PS3 `GAME*.DAT` files and all 7 Xbox 360 Demo `GAME*.DAT` files.

### 2.2 Trailing TOC Layout (`Version = -4`)
Decompiled from `PakArchive::LoadToc` (`VA 0x1404D5D30` / `File 0x4D5130` in `harry1.exe`):

1. **`int32_t Version`:** `-4` (`0xFFFFFFFC`).
2. **`uint32_t FileCount` (`N`):** Number of files in this archive volume.
3. **`PakDatFileEntry Entries[N]` (`16 * N` bytes):**
   ```c
   struct PakDatFileEntry { // 16 bytes (0x10)
       uint32_t OffsetSector;     // [0x00..0x03] Base offset >> 8 (256-byte sector index)
       uint32_t CompressedSize;   // [0x04..0x07] Stored size in bytes
       uint32_t UncompressedSize; // [0x08..0x0B] Decompressed size in bytes
       uint8_t  CompressionType;  // [0x0C] 0 = raw, 2 = LZ2K
       uint16_t UnkPadding;       // [0x0D..0x0E] Uninitialized packer stack padding
       uint8_t  SubSectorOffset;  // [0x0F] Low byte of offset (ByteOffset = (OffsetSector << 8) + SubSectorOffset)
   };
   ```
4. **`uint32_t NameNodeCount` (`M`):** Number of nodes in the directory/filename tree.
5. **`PakDatNameNode Nodes[M]` (`8 * M` bytes):**
   ```c
   struct PakDatNameNode { // 8 bytes (0x08)
       int16_t ChildOrFileId; // [0x00..0x01] > 0: last child node index (directory); <= 0: FileEntryIndex = -ChildOrFileId
       int16_t PrevSibling;   // [0x02..0x03] 0: first child of directory node (k - 1); > 0: sibling in same parent as PrevSibling
       int32_t NameOffset;    // [0x04..0x07] Byte offset of null-terminated component name in StringTable
   };
   ```
   - **Parent Node Reconstruction:** For node $k \ge 1$, if `PrevSibling == 0`, then $\text{Parent}(k) = k - 1$; otherwise $\text{Parent}(k) = \text{Parent}(\text{PrevSibling})$. Walking `Parent` up to root node `0` yields all directory components for every file.
6. **`uint32_t StringTableSize` (`S`):** Size in bytes of the string table (`4`-byte aligned).
7. **`char StringTable[S]`:** Null-terminated ASCII path component strings.
8. **`uint32_t PathHashes[N]` (`4 * N` bytes):** Sorted ascending array of 32-bit `TtPathHash` values (`PathHashes[i]` corresponds 1-to-1 to `Entries[i]`).
9. **`uint64_t TrailingZeroPadding` (`8` bytes):** `0x0000000000000000`.

### 2.3 `LZ2K` Chunked Compression (`CompressionType == 2`)
Entries with `CompressionType == 2` are divided into sequential chunks (up to `32,768` bytes uncompressed per chunk), each prefixed by a 12-byte header (checked at `VA 0x1404D4BB0` and `VA 0x140536870`):
```c
struct Lz2kChunkHeader { // 12 bytes (0x0C)
    char     Magic[4];              // [0x00..0x03] "LZ2K" (4C 5A 32 4B)
    uint32_t UncompressedChunkSize; // [0x04..0x07] Typically 0x00008000 (32 KB) or remaining bytes
    uint32_t CompressedChunkSize;   // [0x08..0x0B] Stored byte length following this 12-byte header
};
```
If `CompressedChunkSize == UncompressedChunkSize`, the chunk payload is stored raw (`memcpy`); otherwise it is decompressed by `LZ2K_Decompress` (`VA 0x1404D4A50`, using `0x2000`-byte internal sub-blocks via `VA 0x140568A40`).

### 2.4 TT Games Path Hash Algorithm (`TtPathHash`)
Decompiled from `VA 0x140208320` (`File 0x207720`) and `PakArchive::FindFileByPath` at `VA 0x1404D4F80` (`File 0x4D4380`) in `harry1.exe`:

```csharp
public static uint ComputeTtPathHash(string PathString) {
    uint Hash = 0x811C9DC5u; // FNV-1 offset basis
    for (int i = 0; i < PathString.Length; i++) {
        char Ch = char.ToUpperInvariant(PathString[i]);
        if (Ch == '/') Ch = '\\';
        Hash = (Hash ^ (byte)Ch) * 0x00199933u; // TT Games custom prime 0x00199933
    }
    return Hash;
}
```
- **Verification:** `100.0%` match across all `11,158` files in PS3 Years 1-4 (`v01.02` and `v03.01`), all `14,264` files in PS3 Years 5-7, and all `67` files in Xbox 360 Demo `GAME2.DAT` (`23,254` unique path strings total).

---

## 3. Xbox 360 Kiosk Demo Container (`XDVDFS` + `PIRS` STFS)

In `Source/Orginals/The Experience Disc Version 5.5 (Xbox 360)/The.Experience.Disc.Version.5.5.iso` (`7,838,695,424` bytes, Serial `XK-2123`):
- **XDVDFS Game Partition:** Starts at byte offset `0x0FD90000` (`MICROSOFT*XBOX*MEDIA` signature at sector 32 = `0x0FDA0000`, Root Directory at sector `1,782,011` = `0xE960D800`).
- **LEGO Harry Potter: Years 1-4 Demo (`PIRS` STFS Package):**
  - Path: `content/0000000000000000/575287FF/00080000/F016B45400D379BBC11F7A9E621771400E2A3A9057` (accompanied by `575287FF_LegoHP.txt`).
  - Location: XDVDFS sector `0x05DC3A` -> ISO byte offset **`0x3EBAD000`**, length **`697,393,152` bytes** (`0x29916000`).
  - Metadata: Title ID `0x575287FF` (Warner Bros.), Media ID `0x05E535C2`, Content Type `0x00080000` (Game Demo).
  - STFS Block-to-ISO Offset Mapping (`Base = 0x3EBAD000 + 0xC000`):
    $$\text{PhysBlock}(b) = b + \lfloor b / 170 \rfloor + \lfloor b / 28900 \rfloor + [b \ge 170] + [b \ge 28900]$$
    $$\text{IsoOffset}(b) = \text{0x3EBB9000} + \text{PhysBlock}(b) \times \text{0x1000}$$

---

## 4. The Launcher Package Format (`.pkiwin` + `.pkdwin`)

In `Source/Collection/Main`, the launcher application uses a paired index/data packaging system:
- **`launcher.pkiwin` (Package Index):** `6,432` bytes (`268` records of `24` bytes).
- **`launcher.pkdwin` (Package Data):** `44,304,841` bytes containing sequential RFC 1950 zlib streams (`0x785E` header).

---

## 5. Shader Bytecode Blobs (`.blob`)

- `Source/Collection/Years 1-4/shaderblob_pc.blob` (`61,580,900` bytes)
- `Source/Collection/Years 5-7/harry2_shaderblob_pc.blob` (`233,742,016` bytes)
- Format: Consolidated Direct3D 11 shader cache (`4x` larger in Years 5-7 due to deferred lighting and particle shaders).
