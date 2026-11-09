# Common game file families

## Evidence levels

**Observed:** archive names, metadata, decoded bytes, sample SHA-1 digests and counts below. **Inferred:** similar markers suggest related serializers or containers. **Unresolved:** full field semantics, platform variants, compatibility and semantic equivalence. A shared filename or digest of one small sample does not establish a shared renderer, engine version, or universal reader.

The comparison uses eight datasets defined in the [overview](README.md), excluding the duplicate PS3 v01.02 control. Collection extension counts cover only 25,084 hash-matched/candidate names; 9,528 unresolved entries are excluded from extension classification. Console/Batman names come from their own verified archive name trees.

## Extensions present in every dataset

`apj`, `as`, `cd`, `cfg`, `csv`, `dno`, `ft2`, `ghg`, `git`, `giz`, `gsc`, `led`, `pak`, `par`, `ptl`, `sfx`, `tex`, `txt`.

| Family | Decoded sample observation | Starter interpretation / limitation |
| --- | --- | --- |
| `.apj`, `.as`, `.cd` | `StreamInfo` begins at byte 8 in the selected samples from every dataset. | Related structured serialization is supported by bytes. Field/property schemas remain unparsed. |
| `.led` | `StreamInfo` at byte 8 in seven selected samples; the HP 5–7 Collection sample starts `LZ2K`. | A file-level compression wrapper can survive outer datwin decompression. Preserve it; unpacking an archive does not imply decoding every nested format. |
| `.ghg`, `.gsc` | ASCII `02UN` at byte 8 and `OFNI` at byte 16 in all selected samples. | Strong common chunk-family evidence. Header lengths and contents vary; geometry, animation and material layouts remain unresolved. |
| `.ft2` | Selected samples start `00 00 03 02 00 00 00 01 54 4E 46 4E`; `TNFN` is at byte 8. | Font-family candidate. A shared header is insufficient to infer every font version. |
| `.tex` | Smallest selected member in each dataset starts `DDS ` and is 184 bytes. | These selected files are DDS carriers. This deliberately small sample does not classify every platform texture. |
| `.pak` | Selected samples start `7A 56 34 12`; several 24-byte empty/minimal examples are byte-identical across titles. | Related nested-package family. Offsets, relocation data and variant semantics have not been parsed. |
| `.git` | Readable `GitOptions {` and `CameraPos` in every selected sample. | Game configuration data; this extension does not identify a Git repository. |
| `.dno` | Opaque headers in HP; Batman sample contains `SERIALISED` beginning at byte 4. | A visible serializer/version difference despite a shared extension. |
| `.giz` | Mixed opaque structured data and embedded names; Batman/HP 5–7 smallest examples are the same 13 bytes. | Small placeholder equality is a control, not evidence of complete schema equality. |
| `.par`, `.ptl`, `.sfx` | Binary records, sometimes containing labels such as `General` or object/sound names. | Descriptor/parameter family candidates. A `.sfx` name does not itself establish an audio codec. |
| `.cfg`, `.csv`, `.txt` | Selected small samples contain readable text. | Per-title syntax, encoding, line endings and exceptional binary members remain unclassified. |

Sampling chooses the smallest nonempty named member no larger than 8 MiB for each dataset/extension. Exactly **245 samples** were separately decoded and output-size checked. Their archive path, TOC ordinal, path hash, candidate path, size, first 32 bytes and SHA-1 are retained locally in `GameFiles/format-comparison/sample-signatures.tsv`. This is reproducible sampling, not complete validation of every member's internal format.

### Concrete sample locations

Batman paths below are relative to `Source/WinSteam/Batman 2 DC super heroes/GAME.DAT`; byte positions in signatures are relative to the decompressed member.

| TOC ordinal | Stored path hash | Path | Decoded bytes |
| ---: | --- | --- | ---: |
| 5,702 | `FB5ABB8B` | `chars/superheroes1_builder.apj` | 686 |
| 3,962 | `AC30FEC0` | `chars/minifigs/super_characters/phantom_minifig/phantom_minifig_nxg.ghg` | 40,291 |
| 3,003 | `B0AEB2CC` | `levels/story/13gothamchase/13gothamchaseb/13gothamchaseb_cam_nxg.gsc` | 1,362 |
| 2,033 | `56A554F9` | `framework-data/gui/font/buttons_360_nxg.ft2` | 33,714 |
| 102 | `03F0DD22` | `chars/minifigs/super_characters/legs/lego_lightnougat_nxg.tex` | 184 |

Nested compression counterexample: Collection Years 5–7 `harry2b.datwin`, entry 7,425, hash `A6FF88B4`, candidate path `levels/hogwarts/grounds/8grounds/8grounds.led`. The outer member decompresses to 535 bytes beginning `4C 5A 32 4B 21 05 00 00 0B 02 00 00`: `LZ2K`, advertised inner length 1,313, inner stored length 523. Its file-level wrapper was preserved. SHA-1 of the extracted 535-byte carrier: `c670366f94b24acf029f6ac400b9ae2dbdadf38c`.

## Direct byte-equality controls

These SHA-1 groups compare the separately decoded selected samples, not merely their first 32 bytes:

| SHA-1 | Equal decoded sample group | What it establishes |
| --- | --- | --- |
| `abadef230715aba8211bdcd3507ad92695a9d25c` | Batman `.ft2`; HP 1–4 PS3, Xbox retail, demo and Collection `.ft2` | A 33,714-byte font carrier is reused across these supplied builds. HP 5–7's selected font has a different digest. |
| `6b21781c6a3ca2a0f041c8b131e534d0ebfd653c` | Batman and both HP console originals' `.ats` samples | The selected 175-byte text script is reused across titles/platforms. |
| `6920aaad62e85babecea680f98f01c7b85ecdea8` | Batman and HP 5–7 PS3/Xbox `.lua` samples | The selected 245-byte Lua source member is shared. This does not identify either game's runtime Lua version. |
| `c835b0c6463f9f874460a9e7b196935b531c020f` | Both HP titles, PS3/Xbox/Collection `.cd` samples | One 1,495-byte structured carrier is shared across both games and all three tested platform groups. |
| `59a98b25bcdb8e9daccbd890bde388d0e3be3d25` | Several Batman/HP `.pac` and `.pak` minimal members | `.pac` and `.pak` can share an identical 24-byte minimal carrier; suffixes alone are insufficient identifiers. |

## Named extension census

Counts are archive-entry occurrences, including repeated paths in separate volumes. Zero means no **named occurrence** in the observed tables, not proof that an unresolved Collection entry cannot contain that format. B = Batman Windows; H1/H2 = HP titles; C = Collection; D = HP 1–4 demo.

| Extension | B | H1 PS3 | H1 360 | H1 C | D | H2 PS3 | H2 360 | H2 C |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| aib | 186 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| anm | 0 | 86 | 86 | 86 | 3 | 1 | 1 | 1 |
| apj | 8 | 10 | 10 | 10 | 8 | 9 | 9 | 9 |
| as | 426 | 502 | 502 | 504 | 91 | 578 | 578 | 688 |
| ats | 2 | 2 | 2 | 0 | 0 | 2 | 2 | 0 |
| binary | 4 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| cd | 454 | 632 | 632 | 635 | 76 | 890 | 890 | 1,017 |
| cfg | 12 | 3 | 3 | 3 | 3 | 7 | 7 | 6 |
| cpd | 178 | 0 | 0 | 0 | 0 | 217 | 217 | 217 |
| csv | 119 | 2 | 2 | 3 | 3 | 6 | 6 | 3 |
| cu2 | 0 | 523 | 523 | 523 | 11 | 506 | 505 | 553 |
| cu3 | 206 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| dno | 559 | 354 | 353 | 353 | 28 | 633 | 631 | 635 |
| fmv | 4 | 6 | 6 | 0 | 2 | 4 | 4 | 0 |
| fnt | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| fpk | 1 | 1 | 1 | 0 | 1 | 1 | 1 | 0 |
| ft2 | 7 | 8 | 8 | 9 | 8 | 10 | 10 | 11 |
| ghg | 283 | 303 | 303 | 305 | 61 | 373 | 373 | 470 |
| gil | 0 | 1 | 1 | 1 | 1 | 0 | 0 | 1 |
| gip | 0 | 32 | 32 | 32 | 33 | 0 | 0 | 32 |
| git | 2 | 153 | 153 | 153 | 21 | 19 | 19 | 19 |
| gix | 0 | 5 | 5 | 5 | 5 | 0 | 0 | 5 |
| giz | 401 | 200 | 199 | 199 | 22 | 289 | 289 | 291 |
| gsc | 976 | 1,365 | 1,363 | 1,365 | 123 | 1,494 | 1,452 | 1,515 |
| led | 1,991 | 1,004 | 1,004 | 1,004 | 61 | 2,098 | 2,098 | 2,102 |
| lua | 5 | 0 | 0 | 0 | 0 | 5 | 5 | 0 |
| msf | 0 | 289 | 0 | 0 | 0 | 261 | 0 | 0 |
| ogg | 394 | 0 | 0 | 289 | 0 | 0 | 0 | 261 |
| pac | 362 | 486 | 486 | 0 | 428 | 520 | 518 | 0 |
| pak | 795 | 169 | 169 | 1 | 10 | 145 | 147 | 116 |
| par | 64 | 52 | 52 | 52 | 3 | 99 | 99 | 99 |
| pc_shaders | 715 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| png | 1 | 1 | 1 | 0 | 0 | 1 | 1 | 0 |
| por | 11 | 0 | 0 | 0 | 0 | 23 | 23 | 23 |
| ptl | 35 | 96 | 95 | 95 | 4 | 1 | 1 | 1 |
| raw | 0 | 2 | 2 | 0 | 0 | 1 | 1 | 0 |
| sav | 0 | 20 | 20 | 20 | 0 | 21 | 21 | 21 |
| scp | 0 | 1,833 | 1,832 | 1,832 | 86 | 32 | 32 | 32 |
| sf | 705 | 0 | 0 | 0 | 0 | 1,756 | 1,756 | 1,756 |
| sfx | 5 | 141 | 141 | 141 | 16 | 214 | 214 | 214 |
| spl | 0 | 29 | 29 | 29 | 1 | 0 | 0 | 0 |
| sub | 185 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| tex | 1,099 | 526 | 526 | 525 | 100 | 1,626 | 1,626 | 1,955 |
| txt | 1,669 | 2,322 | 2,319 | 2,320 | 1,025 | 2,422 | 2,424 | 2,537 |
| xma | 0 | 0 | 289 | 0 | 13 | 0 | 261 | 0 |

This is a census of **45 named extensions**, not 45 independently decoded format specifications. `.fmv` had no eligible sample under the 8 MiB limit.

## Platform-dependent carriers and packaging

* PS3 selected music carriers start `MSF` (HP 1–4) / `MSFC` (HP 5–7); Xbox selected `.xma` files are RIFF/WAVE carriers. Windows selected `.ogg` files start `OggS` and contain the Vorbis identification marker. These observations support platform-specific audio packaging, not bit-identical audio.
* Batman has 715 named `.pc_shaders` members; its selected smallest sample contains `CC4HSERHSCB`. Collection instead ships standalone `shaderblob_pc.blob` (61,580,900 bytes) and `harry2_shaderblob_pc.blob` (233,742,016 bytes). Both start `SBLBVERS`, contain `DBUG`, `DATA`, `SENT` in the sampled header and `DXBC` within the first 64 KiB. Cache counts, offsets, shader-stage layouts and complete cache parsing remain unknown.
* Batman's `.cu3` and HP's `.cu2` are distinct named families. No binary conversion or compatibility between them was established.
* `.pac`, `.pak` and `.fpk` share the initial `7A 56 34 12` bytes in the selected samples. Full nested extraction was not performed in this starter pass.

## Path reuse

Case-insensitive path intersections, with slashes normalized, include 145 Batman/HP 1–4 PS3 paths and 260 Batman/HP 5–7 PS3 paths. HP PS3/Xbox retail intersections are 10,333 for Years 1–4 and 13,445 for Years 5–7. The demo shares 2,228 named paths with Years 1–4 Xbox retail, from 2,247 demo entries. These are path intersections, not asset identity or engine-code similarity scores. The full pairwise table is retained locally as `path-overlap.tsv`.
