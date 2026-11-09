# Supplied TT builds: starter cross-reference

Research date: 2026-11-08. Scope: archive extraction and initial file-family comparison of the supplied Batman 2 Windows build, Harry Potter Years 1–4 and Years 5–7 PS3/Xbox 360 originals, Windows Collection, and the Years 1–4 Xbox demo. This establishes a starting point for later engine research; it does not establish a universal TT parser or implement gameplay.

## Findings

* Batman 2 Windows already has four standalone `GAME*.DAT` archives. There is no prerequisite executable unpacking step for these files.
* The Collection's six standalone `.datwin` files are its game archives. They are related to console PakDat but have different headers, records, compression, and name storage. Renaming them to `.DAT` does not convert them.
* Batman Windows and both Harry Potter console originals share the observed PakDat `-4` container, little-endian metadata, TT path hash, and LZ2K framing. Console executable byte order must not be applied to archive metadata.
* The Collection launcher has a separate `.pkiwin`/`.pkdwin` pair: 401 indexed zlib streams. It is not a container for the six game archives.
* Eighteen named extensions occur in all eight game datasets. The 245 decoded samples support several shared file-family signatures; matching extensions alone do not prove compatible internal schemas.

| Dataset | Archive volumes | Entries | Raw | LZ2K | LZHAM |
| --- | ---: | ---: | ---: | ---: | ---: |
| Batman 2 Windows | 4 | 11,865 | 6,161 | 5,704 | 0 |
| HP 1–4 PS3, supplied v03.01 folder | 7 | 11,158 | 6,876 | 4,282 | 0 |
| HP 1–4 Xbox 360 retail | 7 | 11,149 | 6,870 | 4,279 | 0 |
| HP 1–4 Xbox demo | 7 | 2,247 | 1,814 | 433 | 0 |
| HP 1–4 Windows Collection | 3 | 14,829 | 1,756 | 0 | 13,073 |
| HP 5–7 PS3 | 10 | 14,264 | 7,388 | 6,876 | 0 |
| HP 5–7 Xbox 360 retail | 2 | 14,221 | 7,388 | 6,833 | 0 |
| HP 5–7 Windows Collection | 3 | 19,783 | 1,621 | 0 | 18,162 |

The existing v01.02 PS3 Years 1–4 directory was also inventoried as a control. It is excluded from the eight-dataset comparison to avoid counting the title twice. Matching counts are not a claim that every byte in its archives matches v03.01.

## Reading order

* [Containers and extraction](Containers.md): exact layouts, archive evidence, name recovery and launcher correction.
* [Common file families](Formats.md): observed extensions, signatures, byte-identical controls and platform differences.
* [Evidence and reproduction](Evidence-and-commands.md): source identities, engine commands, outputs, tools and validation.
* [Open questions](Open-questions.md): uncertainties and useful next probes.

Generated inventories, extracted assets and analysis samples remain under each module's ignored `GameFiles/` directory. Documentation contains metadata and observations only. Source game files were read without modification.
