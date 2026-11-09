# Limits and next probes

1. **Collection naming:** 9,528 entries remain unnamed in the tested dictionary. Recover additional candidates from executable path strings, structured manifests and nested package names, then verify their TT hashes. Keep transformation candidates separate from original-name evidence and retain unknown hash collisions.
2. **Launcher identifiers:** all 401 zlib streams are extracted, but original filenames and the 32-bit record identifier algorithm are unconfirmed. Investigate launcher lookup code and decompressed headers before assigning names. The eight-byte gap before record 292 also needs an explanation.
3. **Nested packages:** compare the `7A 56 34 12` family across `.pac`, `.pak` and `.fpk`, including nonempty members and multiple platforms. An empty package hash match provides little structural coverage.
4. **Serializer versions:** start with the observed `StreamInfo` carriers and `02UN`/`OFNI` chunk family. Separate common framing from game-specific records, endianness, pointer width and platform payloads. The extracted HP 5–7 Collection `.led` sample still carries inner LZ2K framing.
5. **Textures:** the selected DDS examples are small placeholders. Sample large/non-placeholder `.tex` files, all platform naming variants and nested texture chunks before generalizing.
6. **Media and shaders:** enumerate all media headers, including `.fmv` files excluded by the small-sample cap. Parse the Collection `SBLB` cache separately from Batman `.pc_shaders`; visible DXBC does not establish the entire cache layout or shader semantics.
7. **Engine code:** only one Collection decompression wrapper was rechecked through REA in this pass. No cross-executable function matching, gameplay reconstruction, renderer implementation or broad engine-version taxonomy was performed.
8. **Demo container:** offsets and consecutive-block mapping are scoped to the supplied Experience Disc 5.5 image. General STFS fragmented files, other allocation layouts, signature/hash authentication and other demo-disc versions are unsupported.
9. **Release coverage:** folder labels and shipped build text identify the supplied data. They do not verify store ownership, patch history, unmodified binaries, every region or other TT games. No claims here extend to unlisted games or builds.

For further work, prioritize full nonempty package framing and serializer headers. Those probes can distinguish shared engine infrastructure from reused data without assuming that one parser works across every title.
