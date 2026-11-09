# Archive relationships and Windows extraction

## PakDat: Batman Windows and Harry Potter console originals

Observed in all four Batman 2 Windows `GAME*.DAT` files, 17 requested PS3 Harry Potter volumes, nine Xbox retail volumes, and seven recovered demo volumes. Each supplied volume has an independent TOC and names. This does not imply every TT title uses this layout.

| Absolute header offset | Width | Observed interpretation |
| --- | ---: | --- |
| `0x00` | 4 | Signed little-endian TOC locator. Nonnegative: byte offset. Negative: negate, then multiply by 256. |
| `0x04` | 4 | Little-endian TOC byte length. |
| `0x08` | **49** | `BEGIN_APP_ID_STRINGPakDat v1.01END_APP_ID_STRING` followed by NUL. |

Correction to earlier notes: the complete string including NUL is 49 bytes, so these fields occupy **57 bytes**, through `0x38`. The old 52-byte/44-character description truncated the signature. This does not specify alignment of the first member.

At the TOC: signed version `-4`, 32-bit file count, 16-byte entries, 32-bit name-node count, eight-byte name nodes, 32-bit string-table size, string bytes, one 32-bit hash per entry, and eight trailing bytes. All metadata is little endian. The supplied tables end at archive EOF exactly.

An entry has sector offset at `+0`, stored size at `+4`, unpacked size at `+8`, compression byte at `+12`, two uninterpreted padding bytes, and a sub-sector byte at `+15`. Absolute payload offset is `sector * 256 + sub-sector`. Compression observed: 0 raw, 2 chunked LZ2K.

Name nodes contain signed 16-bit child/file and previous-sibling values, then a 32-bit string offset. For nonroot node `k`, parent is `k-1` when sibling is zero, otherwise the previously reconstructed parent of that sibling. A nonpositive child/file value selects entry `-value`. Reconstructed names are checked against the corresponding stored hash before use.

Each LZ2K chunk starts with ASCII `LZ2K`, 32-bit little-endian unpacked length, and 32-bit stored length. Equal chunk lengths mean raw bytes within the chunk framing. Otherwise QuickBMS's LZ2K decoder decompresses the payload. The Lua operation validates chunk spans against the enclosing member before decoding. Archive offsets and TOC metadata are retained in TSV inventories.

### Batman 2 Windows evidence

Input directory: `Games/Lego_Batman/Source/WinSteam/Batman 2 DC super heroes/`.

| Archive | Bytes | TOC byte offset | TOC bytes | Entries |
| --- | ---: | ---: | ---: | ---: |
| `GAME.DAT` | 1,294,431,115 | 1,294,118,055 | 313,060 | 5,817 |
| `GAME0.DAT` | 1,235,145,401 | 1,234,911,481 | 233,920 | 4,357 |
| `GAME1.DAT` | 1,229,013,641 | 1,228,940,165 | 73,476 | 1,476 |
| `GAME2.DAT` | 251,488,684 | 251,476,788 | 11,896 | 215 |

All 11,865 archive names pass TT hash verification. Example: `stuff\icons\paramedic_nxg.tex` hashes to `00022654`, entry 0 of `GAME.DAT`. `GAMEVERSION.TXT` reports build record 412210, TTBuilder 1.00.51, build date `2012-05-25 14:52:48`, stream `SuperHeroes1-25-05-12-v0.97c_Hotfix`, Accurev transaction 4502005, SVN revision 127098. These are shipped text claims, not an independently authenticated build identity.

## Windows Collection datwin

The 16-byte header contains a positive 64-bit TOC byte offset and 64-bit TOC size. Version is `-1`; TOC length is exactly `8 + 28*N`. After version/count, there are `N` 24-byte records and `N` 32-bit hashes. There is no name tree in these tables.

Record layout: 64-bit payload offset at `+0`, canary `0x12345678` at `+8`, 32-bit stored size at `+12`, unpacked size at `+16`, repeated compression bytes at `+20..23`. Observed flags are zero and `0x04040404`.

| File | Bytes | TOC offset | Entries | Exact console-path hash matches | Additional transformed candidates | Unresolved |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `harry1.datwin` | 548,868,301 | 548,740,081 | 4,579 | 2,327 | 290 | 1,962 |
| `harry1b.datwin` | 5,672,667,448 | 5,672,380,832 | 10,236 | 7,352 | 523 | 2,361 |
| `harry1p.datwin` | 42,248,689 | 42,248,289 | 14 | 2 | 0 | 12 |
| `harry2.datwin` | 1,137,016,898 | 1,136,817,166 | 7,133 | 2,832 | 724 | 3,577 |
| `harry2b.datwin` | 6,277,440,474 | 6,277,086,910 | 12,627 | 10,933 | 92 | 1,602 |
| `harry2p.datwin` | 44,174,945 | 44,174,293 | 23 | 9 | 0 | 14 |

The `b` and `p` suffixes are retained as identifiers; their semantic purpose was not established here. A hash match supplies a candidate path, not a recovered original name or proof against an unknown collision. The dictionary uses console names and separately marked transformations `PS3/360 → PS4` and terminal `.msf/.xma → .OGG`. The inventories distinguish these sources and retain TOC ordinals. Candidates are not inferred from payload extension alone.

Extraction writes all 34,612 entries, including **9,528 unresolved names**, to per-archive directories. Unresolved members use `__unresolved/HASH_ORDINAL.bin`; the bytes are decompressed even though the extension is unknown. No data is discarded because its name cannot be recovered. Cross-archive overrides are preserved separately.

Observed compressed members start `0E C6`. QuickBMS LZHAM is configured with dictionary parameters `15 0 5 0 0`: 32 KiB dictionary, default table rate, decompression flags 5. REA/Ghidra analysis of the supplied `harry1.exe`, function VA `0x1405B47B0`, independently shows a 40-byte parameter structure initialized with dictionary log2 15 and flags 5. No game executable code is loaded or called by the new extraction workflow.

## Collection launcher pair

Both files begin with three little-endian 32-bit values: `3`, `0`, `401`. Version and reserved-field interpretations remain provisional. The `.pkiwin` index is **12 + 401*16 + 4 = 6,432 bytes**, not 268 records of 24 bytes.

Each 16-byte record contains unpacked size, stored size, absolute `.pkdwin` offset, and an unknown 32-bit identifier/hash. The index ends with a zero word. All 401 member offsets point to valid RFC 1950 zlib headers (`78 5E` observed); each stream decompresses to its declared size. Extracted total: **183,143,304 bytes**. Original filenames and the final field's hash algorithm remain unknown.

First record: unpacked 16,512, stored 4,636, offset 12, identifier `D0161FE4`. Last record (400): unpacked 8,454,144, stored 830,222, offset 43,474,619, identifier `709CBE87`; its span ends at `.pkdwin` EOF 44,304,841. There is one eight-byte gap before record 292: previous end 15,595,275, next offset 15,595,283. Its purpose is unresolved. The other record spans are contiguous in index order.

## Supplied Xbox demo

Input: `Games/Lego_Harry_Potter/Source/Orginals/The Experience Disc Version 5.5 (Xbox 360)/The.Experience.Disc.Version.5.5.iso`, 7,838,695,424 bytes. The operation checks `MICROSOFT*XBOX*MEDIA` at ISO `0x0FDA0000`, `PIRS` at `0x3EBAD000`, title ID `0x575287FF`, and content type `0x00080000`.

The fixed package extent and block formula come from the existing local demo investigation and are rechecked against these bytes. This is a bounded extractor for this input, not a general XDVDFS/STFS implementation. It handles the consecutive regular files flagged in this file table. STFS hashes/signatures are not authenticated.

| Member | Logical starting block | Bytes | PakDat entries |
| --- | ---: | ---: | ---: |
| `GAME.DAT` | 1,608 | 481,842,593 | 1,851 |
| `GAME1.DAT` | 119,246 | 129,791,211 | 163 |
| `GAME2.DAT` | 150,934 | 104,242 | 67 |
| `GAME3.DAT` | 150,960 | 115,235 | 73 |
| `GAME4.DAT` | 150,989 | 108,270 | 67 |
| `GAME5.DAT` | 151,016 | 33,188,912 | 18 |
| `GAME6.DAT` | 159,119 | 41,482,976 | 8 |

For logical block `b`, physical block is `b + floor(b/170) + floor(b/28900) + [b>=170] + [b>=28900]`; ISO byte offset is `0x3EBAD000 + 0xC000 + 4096*physical`. Recovered volumes are written outside `Source/`, then parsed and name/hash checked as independent PakDat files. The demo inventory also observes `Default.xex` (6,582,272 bytes) and `__DISC__`; these are not required for the archive comparison.
