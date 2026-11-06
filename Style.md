# Code and Documentation Style

This module follows the parent engine's [Style.md](../../../Style.md), with the module conventions below. The Simpsons module supplies the Lua typing and CLI workflow conventions; its style guidance comes from the parent engine rather than a separate module style file.

## General

- Use four spaces for indentation.
- Prefer PascalCase for new project-defined names, including types, functions, variables, and structured fields. Preserve external API names, serialized keys, and established format terminology.
- Use descriptive names and explicit units, such as `Offset`, `StoredSize`, or `SampleRate`.
- Explain format assumptions, non-obvious offsets, and reasons for heuristics. Keep comments and documentation synchronized with the code.
- Follow existing conventions in a file when editing it; avoid unrelated formatting changes.

## Lua

Define reusable structures with `---@class` and `---@field`. Every function must annotate parameter and return types. Use typed arrays and maps, explicit optional types such as `integer|nil`, and shared class definitions instead of duplicating structures. See [AGENTS.md](AGENTS.md) for an example.

Use `---@cast` only when the value's type is established. Validate untrusted input before treating it as a known structure. Keep extraction logic separate from CLI prompts and presentation where practical.

## C#

For engine integration work, follow the engine style: keyword types (`int`, `string`, `bool`), file-scoped namespaces except where partial-class organization calls for block namespaces, and K&R braces. Always brace control statements and put `else` and `catch` on the same line as the preceding closing brace.

Prefer specific exception handling and follow the engine's diagnostic logging conventions. Read the relevant `.csproj` before changing .NET code and use the engine's .NET 10 configuration and language features.

## Parsers and Extraction Tools

State byte order, field width, offset origin, alignment, and compression assumptions explicitly. Check lengths, counts, and bounds before reading or allocating. Preserve unknown fields as unknown rather than assigning unsupported meanings.

Keep original asset names and source-to-output relationships traceable. Conversion should retain the information needed to reproduce and explain the result. Report unsupported variants and failures with enough input context to investigate them.

## Research and Markdown

Write concise Markdown with relative links to local documents. Clearly label planned capabilities and separate them from implemented and tested behavior.

Research notes should identify their target game and platform, summarize evidence, distinguish hypotheses from conclusions, and include reproduction details where relevant. Document known limitations and unresolved questions. Use small tables for field layouts or comparisons when they make the evidence easier to read.
