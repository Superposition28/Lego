# generate_docs.ps1
param(
    [string]$RootPath = "a:\RemakeEngine\Main\EngineApps\Games\Lego",
    [string]$SimpsonsCssPath = "a:\RemakeEngine\Main\EngineApps\Games\TheSimpsonsGame-PS3\reversing\docs\style\main.css"
)

$ErrorActionPreference = "Stop"

$CssContent = Get-Content -LiteralPath $SimpsonsCssPath -Raw -Encoding utf8
$CssContent += @"

/* LEGO Multi-Column Specification & Census Table Fixes */
.format-counts th,
.format-counts td {
    overflow-wrap: normal;
    word-break: normal;
    vertical-align: top;
}
.format-counts tr > th:nth-child(n+3):last-child,
.format-counts tr > td:nth-child(n+3):last-child {
    text-align: left;
    white-space: normal;
}
"@

function Ensure-Dir([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Write-HtmlFile([string]$FilePath, [string]$Content) {
    Ensure-Dir (Split-Path -Parent $FilePath)
    [System.IO.File]::WriteAllText($FilePath, $Content, [System.Text.Encoding]::UTF8)
}

function Get-HtmlPage([string]$Title, [string]$BreadcrumbsHtml, [string]$BodyHtml, [string]$CssRelPath = "../../style/main.css") {
    return @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>$Title</title>
    <link rel="stylesheet" href="$CssRelPath">
</head>
<body class="doc-page">
    <nav class="breadcrumbs" aria-label="Breadcrumb">
        $BreadcrumbsHtml
    </nav>
    $BodyHtml
</body>
</html>
"@
}

# --------------------------------------------------------------------------------------------------
# FORMAT DEFINITIONS DICTIONARY (Cross-Game & Era/Game-Specific TT Games Formats)
# --------------------------------------------------------------------------------------------------
$DatFormats = [ordered]@{
    "gsc" = @{
        Name = ".gsc / .nux / .nx2 / .nus (NuScene Compiled Scene Geometry)"
        Ext = ".gsc"
        Magic = "NU20 (0x3032554E) / .CC4+HSER+02UN / GSC0"
        Category = "3D Graphics & Scene"
        Scope = "Universal (All TT Engine Generations 2005–2024; .nux/.nus in LSW1 Xbox, .nx2 in LSW2 Xbox)"
        Desc = "Compiled static scene geometry, room meshes, material graphs, portal bounds, and camera splines across Classic Nu2 (.nup/.nux/.nx2) and Next-Gen NXG/DX11 (_nxg.gsc, _dx11.gsc)."
        Details = @"
<h2>Overview &amp; Engine Evolution</h2>
<p>The <code>.gsc</code> (Game Scene / NuScene) family is the primary static environment and background geometry container across Traveller's Tales LEGO titles:</p>
<ul>
    <li><strong>Era 1 (LSW1 2005):</strong> Stored as <code>.gsc</code> on PS2 (wrapped in <code>RNC\x02</code> compression), <code>.nux</code> / <code>.nus</code> on Original Xbox (raw <code>GSC0</code> + <code>VERS</code> chunks), and <code>.nup</code> on PC/GameCube.</li>
    <li><strong>Era 2 (LSW2 2006 – Indy 1 2008):</strong> Stored as <code>.gsc</code> on PS2/PC/Xbox 360 and <code>.nx2</code> on Original Xbox. Begins with little-endian <code>NU20</code> or big-endian <code>02UN</code> chunk streams (<code>INFO</code>, <code>NTBL</code>, <code>TST0</code>, <code>MSH0</code>, <code>MTL0</code>, <code>SPEC</code>).</li>
    <li><strong>Era 3–4 (NXG &amp; DX11, 2008–2019):</strong> Stored with platform suffixes (<code>_nxg.gsc</code>, <code>_wii.gsc</code>, <code>_dx11.gsc</code>). Wrapped in a FourCC resource container (<code>.CC4</code> / <code>4CC.</code> + <code>HSER</code> / <code>RESH</code>) embedding an inner <code>NU20</code> / <code>02UN</code> scene payload and followed by an out-of-band <code>StreamInfo</code> display-list and vertex/index buffer stream.</li>
</ul>
<h2>Binary Structure (Era 3–4 NXG / DX11 Container)</h2>
<div class="table-scroll"><table class="format-counts">
<thead><tr><th>Offset</th><th>Size</th><th>Type</th><th>Field</th><th>Description</th></tr></thead>
<tbody>
<tr><td>0x00</td><td>4</td><td>UInt32</td><td>HeaderSize</td><td>Size of outer resource wrapper before inner <code>NU20</code> stream.</td></tr>
<tr><td>0x04</td><td>4</td><td>UInt32</td><td>Version</td><td>Container version indicator (typically <code>1</code>).</td></tr>
<tr><td>0x08</td><td>4</td><td>Char[4]</td><td>Magic</td><td><code>02UN</code> (BE on PS3/X360) or <code>NU20</code> (LE on PC).</td></tr>
<tr><td>0x0C</td><td>4</td><td>Int32</td><td>Nu20Version</td><td>Engine serialization version (e.g. <code>0x46</code>..<code>0x59</code>).</td></tr>
</tbody>
</table></div>
"@
    }
    "ghg" = @{
        Name = ".ghg / .hgx / .hx2 / .hgp (Game Hierarchical Geometry / Skeletal Model)"
        Ext = ".ghg"
        Magic = "NU20 (0x3032554E) / .CC4+HSER+02UN"
        Category = "Characters & Models"
        Scope = "Universal (All TT Engine Generations 2005–2024; .hgx in LSW1 Xbox, .hx2 in LSW2 Xbox, .hgp in LSW1 PC/GCN)"
        Desc = "Skeletal character, minifigure, creature, and vehicle mesh container storing bone hierarchies, inverse bind matrices, skinning weights, LODs, and embedded or referenced textures."
        Details = @"
<h2>Overview &amp; Platform Variants</h2>
<p><code>.ghg</code> (Game Hierarchical Geometry) defines articulated characters, minifigures, creatures, and multi-part props:</p>
<ul>
    <li><strong>LSW1 (2005):</strong> <code>.ghg</code> on PS2 (<code>RNC\x02</code> compressed), <code>.hgx</code> on Original Xbox (uncompressed <code>NU20</code> v<code>0x25</code> with inline DXT <code>.dds</code> textures and <code>C:\Perforce\LSW\...</code> paths), and <code>.hgp</code> on PC/GameCube.</li>
    <li><strong>LSW2 (2006):</strong> <code>.ghg</code> on PS2/Xbox 360/PC and <code>.hx2</code> on Original Xbox (accompanied by debug <code>.hx2.htm</code> Perforce export logs on the Xbox retail disc).</li>
    <li><strong>NXG &amp; DX11 (HP 1–4, HP 5–7, Batman 2, Dimensions):</strong> Platform-suffixed <code>_nxg.ghg</code> / <code>_dx11.ghg</code> combining an inner <code>NU20</code> hierarchy (<code>HGOL</code> / <code>LOGH</code> layer lists, joints, locators) with GPU vertex/index streams.</li>
</ul>
<h2>Internal Chunks</h2>
<ul>
    <li><code>NTBL</code> / <code>LBTN</code>: Null-terminated string table holding joint names (<code>head</code>, <code>neck</code>, <code>torso</code>, <code>arm_L</code>, <code>hand_L</code>, <code>hips</code>, <code>leg_L</code>) and material identifiers.</li>
    <li><code>TST0</code> / <code>0TST</code>: Texture set table (inline textures in Era 1–2; external <code>.tex</code> / <code>.nxg_textures</code> references in Era 3–4).</li>
    <li><code>MSH0</code> / <code>0HSM</code>: Skinned mesh primitives and bone weight palette indices.</li>
</ul>
"@
    }
    "tex" = @{
        Name = ".tex / .nxg_textures (DirectDraw Surface & Texture Dictionary)"
        Ext = ".tex"
        Magic = "DDS (0x20534444) / .CC4+HSER+02UN"
        Category = "Textures & Materials"
        Scope = "Era 3–4 (2008–2024 Console & PC Titles; inline in .ghg/.gsc in Era 1–2)"
        Desc = "Standalone DirectDraw Surface (DDS) textures (.tex) and multi-texture dictionary containers (.nxg_textures / .dx11_textures) storing DXT1/DXT5/BC1–BC7 mipmapped surfaces."
        Details = @"
<h2>Overview</h2>
<p>In Era 1–2 (<em>LSW1</em>, <em>LSW2</em>), level and character textures are embedded directly inside <code>.gsc</code>/<code>.nux</code>/<code>.nx2</code> and <code>.ghg</code>/<code>.hgx</code>/<code>.hx2</code> files. Starting with Era 3 (<em>NXG</em>), textures are split into standalone <code>.tex</code> files (raw <code>DDS </code> surfaces with 124-byte headers) or bundled into <code>.nxg_textures</code> dictionaries containing a <code>NU20</code> metadata table followed by concatenated DDS streams.</p>
"@
    }
    "tsh" = @{
        Name = ".tsh (NuTextureSheet / Texture Share Atlas Lookup Table)"
        Ext = ".tsh"
        Magic = "4CC.TXSH / 02UN / NU20 (TSHR / RHST)"
        Category = "Textures & Materials"
        Scope = "Era 3–4 (HP 1–4, HP 5–7, Batman 2, Dimensions)"
        Desc = "NuTextureSheet and texture sharing container (4CC.TXSH / TSHR / RHST) mapping FNV1UPPER hashes and UV sub-rectangles to shared minifigure decals and texture atlases."
        Details = @"
<h2>Overview &amp; Structure (<code>NuTextureSheet</code> / <code>TSH.cs</code>)</h2>
<p><code>.tsh</code> files appear in two closely related forms across Era 3–4:</p>
<ul>
    <li><strong><code>NU20</code> / <code>02UN</code> <code>TSHR</code> (LE) / <code>RHST</code> (BE):</strong> Aliases shared textures across character packages.</li>
    <li><strong><code>4CC.TXSH</code> (<code>NuTextureSheet</code>):</strong> Contains a <code>NU20</code> header followed by an array of texture sheet entries mapping <code>FNV1UPPER</code> (offset basis <code>0x811C9DC5</code>, prime <code>0x199933</code>) hashes or relative <code>.tex</code> paths to UV sprite sub-rectangles for UI icons and minifigure decals.</li>
</ul>
"@
    }
    "an3" = @{
        Name = ".an3 / .ca3 / .ani / .anm (Skeletal Animation Clip)"
        Ext = ".an3"
        Magic = "AN3! / 6INA / 8INA / ANM"
        Category = "Animation"
        Scope = "Universal (.ani in LSW1; .an3 in LSW2–Dimensions; .ca3 on LSW2 X360; .anm in HP/Batman 2)"
        Desc = "Compressed keyframe skeletal animation tracks storing bone rotation quaternions, translation vectors, and scale curves over time."
        Details = @"
<h2>Evolution Across TT Games</h2>
<ul>
    <li><code>.ani</code> (<strong>LSW1 2005</strong>): <code>ANI4</code> / <code>ANI6</code> keyframe curves; verified byte-identical between PS2 (<code>GAME.DAT</code>) and Original Xbox (<code>chars\amidala\explode.ani</code> = 11,922 B).</li>
    <li><code>.an3</code> (<strong>LSW2 2006 – LEGO Dimensions 2015</strong>): Introduced in <em>LSW2</em> (`2,440` files in PS2 `GAME.DAT` and Xbox XISO) and retained through <em>Dimensions</em> (`19,580` files) and the 2024 <em>Harry Potter Collection</em> (bundled inside <code>_an3_ps4.pak</code>). Uses <code>6INA</code> / <code>8INA</code> / <code>AN3!</code> headers with quantized curve evaluation.</li>
    <li><code>.ca3</code> (<strong>LSW2 Xbox 360</strong>): Big-endian Xbox 360 animation counterpart mapped in <code>360_exlist</code> (`an3 -> ca3`).</li>
    <li><code>.anm</code> (<strong>HP 1–4, HP 5–7, Batman 2</strong>): High-precision animation clips used alongside <code>.an3</code> for complex character and creature rigs.</li>
</ul>
"@
    }
    "bsa" = @{
        Name = ".bsa / .anl (Blend Shape / Lip-Sync & Animation List)"
        Ext = ".bsa"
        Magic = "Binary Keyframe / ANL"
        Category = "Animation"
        Scope = "Era 1–2 Specific (LSW1 & LSW2: 679 .bsa in LSW1, 1,999 .bsa + 184 .anl in LSW2)"
        Desc = "Early Nu2 morph-target / blend-shape animation (.bsa) paired 1-to-1 with skeletal clips (.ani/.an3) and animation list manifests (.anl)."
        Details = @"
<h2>Overview</h2>
<p>In <em>LEGO Star Wars: The Video Game</em> (2005) and <em>LEGO Star Wars II</em> (2006), almost every character <code>.ani</code> or <code>.an3</code> file is accompanied by a small <code>.bsa</code> file (typically 50–400 bytes, e.g. <code>chars\amidala\explode.bsa</code> = 82 B, byte-identical between PS2 and Xbox). <em>LSW2</em> also introduces <code>.anl</code> (Animation List, 184 files) grouping character animation sets prior to the adoption of <code>StreamInfo</code> <code>.as</code> files in Era 3.</p>
"@
    }
    "cd" = @{
        Name = ".cd (Character Definition — EdFile StreamInfo)"
        Ext = ".cd"
        Magic = "StreamInfo (0x0A len + 'StreamInfo')"
        Category = "Characters & Models"
        Scope = "Era 3–4 (HP 1–4, HP 5–7, Batman 2, Dimensions; preceded by CHARSTXT.TXT in Era 1–2)"
        Desc = "Reflected EdFile serializer container defining modular minifigure parts, meshes (.ghg), textures (.tex), physics (.cpd), and animation sets (.as)."
        Details = @"
<h2>Overview &amp; EdFile StreamInfo Format</h2>
<p>Starting in Era 3 (NXG), character definitions moved from plaintext scripts to TT Games' reflected binary serializer (<code>EdFile</code> / <code>NuSerializer</code>). Every <code>.cd</code>, <code>.cpd</code>, <code>.as</code>, <code>.apj</code>, and <code>.led</code> file begins with a 4-byte version/type tag, a 4-byte string length (<code>0x0A</code> = 10), and the ASCII string <code>StreamInfo</code> at offset <code>0x08</code>, followed by reflected tables:</p>
<ul>
    <li><code>TypeList</code>: Primitive and composite data types (<code>int</code>, <code>float</code>, <code>CharString</code>, <code>NuVec</code>).</li>
    <li><code>ClassList</code>: C++ class schemas with member names and type indices.</li>
    <li><code>OLST</code> (Object List) &amp; <code>MOBJ</code> (Main Object): Serialized object instances.</li>
</ul>
"@
    }
    "cpd" = @{
        Name = ".cpd (Character Physics Descriptor — EdFile StreamInfo)"
        Ext = ".cpd"
        Magic = "StreamInfo (EdFile Serializer)"
        Category = "Characters & Models"
        Scope = "Era 3–4 (HP 1–4, HP 5–7, Batman 2, Dimensions)"
        Desc = "Reflected EdFile serializer container defining character collision capsules, mass distribution, and ragdoll physics constraints."
        Details = @"
<h2>Overview</h2>
<p>Serialized with the <code>StreamInfo</code> reflection header. Configures collision shapes and physical reaction parameters for characters and vehicles.</p>
"@
    }
    "as" = @{
        Name = ".as (Action Script / Animation Set — EdFile StreamInfo)"
        Ext = ".as"
        Magic = "StreamInfo (EdFile Serializer)"
        Category = "Animation"
        Scope = "Era 3–4 (HP 1–4, HP 5–7, Batman 2, Dimensions)"
        Desc = "Reflected EdFile state-machine container binding character actions, locomotion states, combos, and spells to animation clips (.an3/.anm) and sound triggers."
        Details = @"
<h2>Overview</h2>
<p>Uses the <code>StreamInfo</code> reflection schema (<code>TypeList</code>, <code>ClassList</code>, <code>OLST</code>, <code>MOBJ</code>) to map gameplay state transitions and input events to skeletal animation clips.</p>
"@
    }
    "apj" = @{
        Name = ".apj (Animation Project Container — EdFile StreamInfo)"
        Ext = ".apj"
        Magic = "StreamInfo (EdFile Serializer)"
        Category = "Animation"
        Scope = "Era 3–4 (HP 1–4, HP 5–7, Batman 2, Dimensions: 2,520 files in Dimensions)"
        Desc = "Reflected EdFile animation project linking multiple animation sets (.as), rig layers, and additive blend trees."
        Details = @"
<h2>Overview</h2>
<p>Grows significantly in <em>LEGO Batman 2</em> (`244` files) and <em>LEGO Dimensions</em> (`2,520` files) to orchestrate multi-layered facial, gadget, and vehicle animations.</p>
"@
    }
    "led" = @{
        Name = ".led (Level Entity Definition — EdFile StreamInfo)"
        Ext = ".led"
        Magic = "StreamInfo (EdFile Serializer)"
        Category = "Level Design & AI"
        Scope = "Era 3–4 (HP 1–4, HP 5–7, Batman 2, Dimensions: 2,616 files in Dimensions)"
        Desc = "Reflected EdFile level entity placement container defining spawners, interactive LEGO builds, triggers, and object instances."
        Details = @"
<h2>Overview</h2>
<p>Serialized via <code>StreamInfo</code>. Places dynamic gameplay objects, stud paths, and interactive gizmo hooks into level sub-areas.</p>
"@
    }
    "ter" = @{
        Name = ".ter / .ctr (Terrain & Collision Octree Mesh)"
        Ext = ".ter"
        Magic = "Binary Octree / Collision Hull"
        Category = "Level Design & AI"
        Scope = "Universal Across Era 1–4 (LSW1, LSW2, HP 1–4, HP 5–7, Batman 2, Dimensions; .ctr on LSW2 X360)"
        Desc = "Spatial octree collision mesh and surface material flag database used for ground raycasting, footstep audio material lookup, and physics collision."
        Details = @"
<h2>Overview</h2>
<p>Present in every inspected TT Games title from <em>LEGO Star Wars</em> (2005, 149 files) through <em>LEGO Dimensions</em> (2015, 1,148 files). On <em>LSW2</em> Xbox 360, <code>360_exlist</code> maps <code>ter -> ctr</code> (179 files) for big-endian console collision octrees.</p>
"@
    }
    "rtl" = @{
        Name = ".rtl (Runtime Point & Directional Light List)"
        Ext = ".rtl"
        Magic = "Binary Light Array"
        Category = "3D Graphics & Scene"
        Scope = "Universal Across Era 1–4 (LSW1, LSW2, HP 1–4, HP 5–7, Batman 2, Dimensions)"
        Desc = "Per-room runtime lighting table defining point lights, directional suns, ambient spherical harmonics, and shadow caster flags."
        Details = @"
<h2>Overview</h2>
<p>Appears alongside every level's <code>.gsc</code> and <code>.ter</code> from <em>LSW1</em> (163 files) through <em>LEGO Dimensions</em> (1,123 files).</p>
"@
    }
    "ai2" = @{
        Name = ".ai2 / .aib (AI Navigation Waypoint & Pathfinding Mesh)"
        Ext = ".ai2"
        Magic = "Binary NavGraph"
        Category = "Level Design & AI"
        Scope = "Universal (.ai2 in LSW1, LSW2, HP 1–4, HP 5–7, Batman 2; .aib in Batman 2 & Dimensions)"
        Desc = "AI navigation graph and pathfinding mesh nodes controlling NPC movement, companion following, and enemy patrol bounds."
        Details = @"
<h2>Overview</h2>
<p><code>.ai2</code> defines navigation polygons and link edges from <em>LSW1</em> (120 files) through <em>Batman 2</em> (85 files). In <em>Batman 2</em> (284 <code>.aib</code> files) and <em>LEGO Dimensions</em> (856 <code>.aib</code> files), AI navmeshes transition to the updated <code>.aib</code> (AI Binary) format.</p>
"@
    }
    "for" = @{
        Name = ".for / .cns / .bur (Era 1–2 Force, Constraint & Build Rules)"
        Ext = ".for"
        Magic = "Plaintext / Binary Level Rules"
        Category = "Level Design & AI"
        Scope = "Era 1–2 Specific (LSW1 & LSW2)"
        Desc = "Early Star Wars level interaction formats defining Force-manipulable object rules (.for), physics constraints (.cns), and LEGO build/burst assembly scripts (.bur)."
        Details = @"
<h2>Overview</h2>
<p>Specific to the early <em>LEGO Star Wars</em> engine before the unified <code>.giz</code> / <code>.led</code> / <code>.dno</code> system:</p>
<ul>
    <li><code>.for</code>: 86 files in <em>LSW1</em>, 27 in <em>LSW2</em> — defines objects interactive with Jedi/Sith Force powers.</li>
    <li><code>.cns</code>: 72 files in <em>LSW1</em>, 20 in <em>LSW2</em> — mechanical and spatial constraints.</li>
    <li><code>.bur</code>: 52 files in <em>LSW2</em> — burst/breakable multi-brick object descriptors.</li>
</ul>
"@
    }
    "scp" = @{
        Name = ".scp (State-Machine AI & Mission Script)"
        Ext = ".scp"
        Magic = "state Base (Plaintext / Tokenized)"
        Category = "Gameplay & AI"
        Scope = "Era 1–3 (LSW1, LSW2, Indy, Batman 1, HP 1–4, HP 5–7, Batman 2)"
        Desc = "Hierarchical state-machine script controlling NPC behaviors, boss phases, and level triggers using State / Conditions / Actions blocks."
        Details = @"
<h2>Overview</h2>
<p>Heavily used in <em>LSW1</em> (500 files), <em>LSW2</em> (525 files), and <em>HP 1–4</em> (1,405 files). Gradually superseded by <code>.sf</code> (Script Functions) in <em>HP 5–7</em> and <em>Batman 2</em>, and by compiled Lua 5.1 (<code>.lua</code>) in <em>LEGO Dimensions</em>.</p>
"@
    }
    "sf" = @{
        Name = ".sf / .isf (Script Function / Imperative Event Script)"
        Ext = ".sf"
        Magic = "Plaintext / Tokenized Script Function"
        Category = "Gameplay & AI"
        Scope = "Era 3–4 (HP 1–4: 677, HP 5–7: 4,296, Batman 2: 5,274, Dimensions: 222)"
        Desc = "Imperative event and puzzle scripting language used extensively in Creator/Builder/Gotham NXG titles before the Lua 5.1 transition."
        Details = @"
<h2>Overview</h2>
<p>Peaks in <em>LEGO Harry Potter: Years 5–7</em> (4,296 files) and <em>LEGO Batman 2</em> (5,274 files), controlling hub events, puzzle logic, and boss encounters.</p>
"@
    }
    "lua" = @{
        Name = ".lua (Compiled Lua 5.1 Bytecode & Gameplay Scripts)"
        Ext = ".lua"
        Magic = "\x1BLuaQ (0x1B 0x4C 0x75 0x61 0x51)"
        Category = "Gameplay & AI"
        Scope = "Era 4–5 (LEGO Dimensions: 9,858 files, LEGO Worlds, Skywalker Saga)"
        Desc = "Compiled Lua 5.1 bytecode (and plaintext Lua scripts) replacing legacy .scp/.sf state machines for gameplay, UI, and portal logic in Era 4+ titles."
        Details = @"
<h2>Overview</h2>
<p>In <em>LEGO Dimensions</em>, <code>.lua</code> becomes the single largest script type in the archive (`9,858` files across `GAME*.DAT` and `INSTALL0_*.DAT`), replacing almost all legacy <code>.scp</code> and <code>.sf</code> scripts.</p>
"@
    }
    "cu2" = @{
        Name = ".cut / .cu2 / .cc2 / .cu3 (Cutscene Choreography Timeline)"
        Ext = ".cu2"
        Magic = "0x0000020D / 0x0000020E / RNC\x02"
        Category = "Cinematics"
        Scope = "Universal (.cut in LSW1; .cu2 in LSW2–Batman 2; .cc2 on LSW2 X360; .cu3 in Dimensions)"
        Desc = "In-engine cinematic timeline synchronizing camera cuts, character skeletal/facial animations, lighting changes, and audio tracks."
        Details = @"
<h2>Evolution</h2>
<ul>
    <li><code>.cut</code> (<strong>LSW1 2005</strong>): 184 files in PS2/Xbox archives (<code>RNC\x02</code> compressed on PS2).</li>
    <li><code>.cu2</code> / <code>.cc2</code> (<strong>LSW2 2006 – Batman 2 2012</strong>): 76 files in <em>LSW2</em> (mapped to <code>.cc2</code> on Xbox 360 in <code>360_exlist</code>), 401 files in <em>HP 1–4</em>, 250 in <em>HP 5–7</em>, and 245 in <em>Batman 2</em>. Uses platform suffixes (<code>_ps3.cu2</code>, <code>_360.cu2</code>, <code>_ps4.cu2</code>).</li>
    <li><code>.cu3</code> (<strong>LEGO Dimensions 2015</strong>): 190 files upgraded to the v3 cutscene timeline format.</li>
</ul>
"@
    }
    "giz" = @{
        Name = ".giz (Gizmo & Interactive Obstacle Placement)"
        Ext = ".giz"
        Magic = "GizObstacle (0x0B000000)"
        Category = "Level Design & AI"
        Scope = "Era 3–4 (HP 1–4, HP 5–7, Batman 2, Dimensions: 2,520 files in Dimensions)"
        Desc = "Interactive level gizmo container storing GizObstacle, GizBuildit, GizForce, Blowup, GizmoPickup, Lever, ZipUp, HatMachine, Plug, Tube, and Turret records."
        Details = @"
<h2>Overview &amp; Sub-Chunk Schema</h2>
<p>Binary container storing interactive level gizmos per level sub-area. Each section is prefixed by a length-prefixed ASCII type identifier followed by structured placement records:</p>
<ul>
    <li><code>GizObstacle</code>: Interactive obstacles, gates, and hazard volumes.</li>
    <li><code>GizBuildit</code>: Multi-brick bouncing LEGO build-it assembly spots.</li>
    <li><code>GizForce</code>: Jedi Force / Harry Potter Wingardium Leviosa telekinesis targets.</li>
    <li><code>Blowup</code>: Silver/Gold LEGO destructible props and stud drop tables.</li>
    <li><code>GizmoPickup</code>, <code>Lever</code>, <code>ZipUp</code> (grapple points), <code>HatMachine</code>, <code>Plug</code>, <code>Tube</code>, and <code>Turret</code>.</li>
</ul>
"@
    }
    "git" = @{
        Name = ".git (GitOptions Camera & Sector Environment Settings)"
        Ext = ".git"
        Magic = "GitOptions { (ASCII)"
        Category = "Level Design & AI"
        Scope = "Era 3–4 (HP 1–4, HP 5–7, Batman 2, Dimensions)"
        Desc = "Structured ASCII block configuring per-sector camera framing, split-screen merge thresholds, fog, bloom, and post-processing."
        Details = @"
<h2>Overview</h2>
<p>Starts with <code>GitOptions {</code> in plaintext ASCII and configures level zone rendering and camera constraints.</p>
"@
    }
    "dno" = @{
        Name = ".dno (Pinner Dynamics Object — Physics & Collision Container)"
        Ext = ".dno"
        Magic = "SERIALISED (v20) / 0x00000013 / 0x00B40001"
        Category = "3D Graphics & Scene"
        Scope = "Era 3–4 (HP 1–4: 6,858, HP 5–7: 5,204, Batman 2: 3,240, Dimensions: 17,672)"
        Desc = "PinnerDynamicsObj physics, collision hull, joint constraint, convex mesh, and KD-terrain descriptor container for dynamic and breakable LEGO world objects."
        Details = @"
<h2>Overview &amp; 12-Section Structure (<code>PinnerDynamicsObj.cs</code>)</h2>
<p>Verified against <code>TTGamesExplorerRebirthLib/Formats/PinnerDynamicsObj.cs</code>: <code>.dno</code> stands for <strong>Pinner Dynamics Object</strong> (named after TT Games' internal <em>Pinner</em> physics/dynamics subsystem). Version 20 files begin with the 10-byte ASCII magic <code>SERIALISED</code> + <code>uint32 Version (20)</code> followed by 12 sequential sections:</p>
<ol>
    <li><code>PinnerString</code> (string table)</li>
    <li><code>PinnerMatrix</code> (4×4 transform matrices)</li>
    <li><code>PinnerEntity</code> (dynamic rigid-body entities)</li>
    <li><code>PinnerMesh</code> (collision triangle meshes)</li>
    <li><code>PinnerJoint</code> (hinge/ball/slider constraints)</li>
    <li><code>PinnerGeom</code> (primitive collision shapes)</li>
    <li><code>PinnerSpline</code> (path constraints)</li>
    <li><code>PinnerController</code> (kinematic controllers)</li>
    <li><code>PinnerTileMap</code> (grid collision tiles)</li>
    <li><code>PinnerConvexMesh</code> (convex hull polytopes)</li>
    <li><code>KdTerrainDescriptor</code> (KD-tree spatial terrain)</li>
    <li>Secondary <code>PinnerMesh</code> section</li>
</ol>
"@
    }
    "pak" = @{
        Name = ".pak / .pac / .fpk (Flat Resource Sub-Archive)"
        Ext = ".pak"
        Magic = "0x1234567A / 0x12345678 / RFPK"
        Category = "Archives & Containers"
        Scope = "Universal (.fpk RFPK in LSW2; .pak/.pac 0x1234567A in HP 1–4, HP 5–7, Batman 2, Dimensions)"
        Desc = "Flat sub-archive bundling small related files (textures, AI scripts, animation caches) with a 20-byte entry table and additive 0x12345678 filename checksums."
        Details = @"
<h2>Binary Structure (<code>0x1234567A</code> / <code>0x12345678</code>)</h2>
<p>Verified directly against <code>ICONS_TEX.PAK</code> (2,361,498 B, 136 files) in <em>LEGO Batman 2</em> and <code>ai.pak</code> / <code>_an3_ps4.pak</code> in <em>LEGO Harry Potter</em>:</p>
<div class="table-scroll"><table class="format-counts">
<thead><tr><th>Offset</th><th>Size</th><th>Type</th><th>Field</th><th>Description</th></tr></thead>
<tbody>
<tr><td>0x00</td><td>4</td><td>UInt32</td><td>VersionMagic</td><td><code>0x1234567A</code> (LE) or <code>0x7A563412</code> (BE).</td></tr>
<tr><td>0x04</td><td>4</td><td>UInt32</td><td>FileCount</td><td>Number of packed sub-files (`N`).</td></tr>
<tr><td>0x08</td><td>4</td><td>UInt32</td><td>TotalSize</td><td>Total archive size in bytes.</td></tr>
<tr><td>0x0C</td><td>20*N</td><td>Struct[]</td><td>Entries</td><td>Five <code>uint32</code> fields per entry: <code>NameOffset</code> (relative to string table), <code>DataOffset</code>, <code>DataSize</code>, <code>Zero</code>, and <code>NameChecksum</code>.</td></tr>
</tbody>
</table></div>
<p><strong>Additive Checksum Invariant:</strong> <code>NameChecksum = 0x12345678 + sum((byte)toupper(c))</code> over all characters in the entry filename. In <em>LSW2</em> (2006), the predecessor format is <code>.fpk</code> (`137` files on Xbox, `141` on Xbox 360) with magic <code>RFPK</code>.</p>
"@
    }
    "cbx" = @{
        Name = ".cbx / .cbs (ChatterBoX Voice/SFX Audio & Lip-Sync Stream)"
        Ext = ".cbx"
        Magic = "!B0X (0x58304221)"
        Category = "Audio"
        Scope = "Era 3–4 (HP 1–4, HP 5–7, Batman 2, Dimensions: 9,899 .cbx and 5,976 .cbs in Dimensions)"
        Desc = "Proprietary 'ChatterBoX' (!B0X) EA MicroTalk-variant compressed speech/SFX audio container (.cbx, 0x1B0-sample frames) and companion phoneme/lip-sync curves (.cbs)."
        Details = @"
<h2>Overview &amp; Binary Structure (<code>CBX.cs</code> / <code>CBXDecoder</code>)</h2>
<p>Verified against <code>TTGamesExplorerRebirthLib/Formats/CBX.cs</code> and <code>TTModding-Docs/src/fileformats/cbx.md</code>: <code>.cbx</code> stands for <strong>ChatterBoX</strong>, a custom speech and sound-effect compression format derived from Electronic Arts' 10:1 MicroTalk codec:</p>
<div class="table-scroll"><table class="format-counts">
<thead><tr><th>Offset</th><th>Size</th><th>Type</th><th>Field</th><th>Description</th></tr></thead>
<tbody>
<tr><td>0x00</td><td>4</td><td>Char[4]</td><td>Magic</td><td><code>!B0X</code> (<code>0x58304221</code>).</td></tr>
<tr><td>0x04</td><td>4</td><td>Int32</td><td>Version</td><td>Format version (<code>-2</code> or <code>-3</code>).</td></tr>
<tr><td>0x08</td><td>4</td><td>UInt32</td><td>SampleRate</td><td>Output PCM sample rate in Hz (e.g. <code>24000</code> or <code>32000</code> Hz).</td></tr>
<tr><td>0x0C</td><td>4</td><td>UInt32</td><td>SampleCount</td><td>Total decoded 16-bit mono PCM samples (decoded in <code>0x1B0</code> = 432-sample frames via <code>SoundExpander16</code>).</td></tr>
</tbody>
</table></div>
<p>Companion <code>.cbs</code> files (and <code>_cbs_ps4.pak</code> in the 2024 PC remaster) store synchronized lip-sync phoneme weights and event triggers.</p>
"@
    }
    "res" = @{
        Name = ".res (Resource Manifest & Asset Dependency List)"
        Ext = ".res"
        Magic = "Plaintext / Structured Resource List"
        Category = "Configuration & Metadata"
        Scope = "Era 3–4 (Batman 2: 2,340 files, Dimensions: 9,854 files)"
        Desc = "Per-level and per-character resource manifest enumerating dependent meshes, textures, animations, and sound banks for streaming."
        Details = @"
<h2>Overview</h2>
<p>Introduced at scale in <em>LEGO Batman 2</em> (`2,340` files) and expanded in <em>LEGO Dimensions</em> (`9,854` files) to drive asynchronous background asset streaming.</p>
"@
    }
    "sub" = @{
        Name = ".sub (Localized Subtitle & Lip-Sync Timing Stream)"
        Ext = ".sub"
        Magic = "Binary Subtitle Stream"
        Category = "UI & Localization"
        Scope = "Era 3c–5 (Batman 2: 2,408 files, Dimensions: 15,826 files)"
        Desc = "Time-coded localized subtitle and phoneme trigger stream introduced when TT Games transitioned from mimed grunts to full voice acting in LEGO Batman 2 (2012)."
        Details = @"
<h2>Overview</h2>
<p>Absent in <em>LSW1</em>, <em>LSW2</em>, and <em>HP 1–4</em>/<em>5–7</em> (which used pantomime/mumble audio), <code>.sub</code> appears with `2,408` files in <em>LEGO Batman 2</em> (the first fully voiced TT LEGO title) and grows to `15,826` files in <em>LEGO Dimensions</em>.</p>
"@
    }
    "shaders" = @{
        Name = ".pc_shaders / .ps3_shaders / .fpo / .vpo / .blob (Compiled GPU Shaders)"
        Ext = ".pc_shaders"
        Magic = "DXBC / DXIL / NV40 RSX / .CC4"
        Category = "3D Graphics & Scene"
        Scope = "Universal (Era 2 .vpo/.fpo on PS3; Era 3–4 .pc_shaders/.ps3_shaders; Remaster shaderblob_pc.blob)"
        Desc = "Precompiled platform GPU vertex and pixel/fragment shader libraries for Direct3D 9, Direct3D 11, Xbox 360 Xenos, and PS3 RSX."
        Details = @"
<h2>Overview</h2>
<ul>
    <li><strong>PS3:</strong> Uses <code>.ps3_shaders</code> (<code>1,354</code> files in <em>Dimensions</em>) and NVIDIA Cg RSX <code>.vpo</code> / <code>.fpo</code> programs.</li>
    <li><strong>Windows PC (32-bit DX9/DX11):</strong> Uses <code>.pc_shaders</code> (<code>681</code> files in <em>Batman 2</em>).</li>
    <li><strong>2024 PC Remaster:</strong> Consolidates all D3D11 shaders into <code>shaderblob_pc.blob</code> (`13.86 MB`).</li>
</ul>
"@
    }
    "audio_streams" = @{
        Name = ".vag / .wavx / .wavm / .msf / .xma / .ogg (Platform Audio Streams)"
        Ext = ".msf / .xma / .ogg / .vag"
        Magic = "VAGp / RIFF / MSF\x01 / XMA2 / OggS"
        Category = "Audio"
        Scope = "Universal (Platform-Specific Codecs per Console/PC Target)"
        Desc = "Streaming music, ambience, and dialogue audio containers tailored to each target platform's hardware decoder."
        Details = @"
<h2>Cross-Platform Audio Codec Matrix</h2>
<div class="table-scroll"><table class="format-counts">
<thead><tr><th>Platform</th><th>Extension</th><th>Header Magic</th><th>Codec &amp; Observed Examples</th></tr></thead>
<tbody>
<tr><td>PS2</td><td><code>.vag</code> / <code>.mib</code></td><td><code>VAGp</code></td><td>Sony PS2 SPU2 ADPCM (`1,037` <code>.vag</code> files in <em>LSW2</em> PS2 <code>GAME.DAT</code> + 170 MB <code>IOP/MODULES/SOUND/</code> streams).</td></tr>
<tr><td>Original Xbox</td><td><code>.wavx</code> / <code>.wavm</code> / <code>.wma</code></td><td><code>RIFF</code> / <code>ASF</code></td><td>Xbox ADPCM &amp; WMA streams (`124` <code>.wavx</code> in <em>LSW1</em> Xbox; `149` <code>.wavm</code> in <em>LSW2</em> Xbox).</td></tr>
<tr><td>PS3</td><td><code>.msf</code></td><td><code>MSF\x01</code> (<code>0x4D534601</code>)</td><td>Sony CellOS ATRAC3plus / PCM (`493` files in <em>HP 1–4</em> PS3).</td></tr>
<tr><td>Xbox 360</td><td><code>.xma</code></td><td><code>RIFF</code> (<code>XMA2</code>)</td><td>Microsoft XMA2 hardware audio (`149` in <em>LSW2</em> X360; `492` in <em>HP 1–4</em> X360).</td></tr>
<tr><td>Windows PC</td><td><code>.ogg</code> / <code>.wav</code></td><td><code>OggS</code> / <code>RIFF WAVE</code></td><td>Ogg Vorbis streaming tracks and uncompressed RIFF WAVE sound effects (`Audio\_SoundFX\`).</td></tr>
</tbody>
</table></div>
"@
    }
    "cfg" = @{
        Name = ".cfg / .sfx (Audio Bus & Sound Effect Event Mapping)"
        Ext = ".cfg"
        Magic = "Audio 1.00 (Plaintext) / 0x05000000 (.sfx)"
        Category = "Audio"
        Scope = "Universal (All TT Engine Generations 2005–2024)"
        Desc = "Plaintext audio mix bus configurations (.cfg) and binary/scripted sound event trigger maps (.sfx)."
        Details = @"
<h2>Overview</h2>
<p><code>.cfg</code> files configure master audio buses, attenuation distances, and sample rates, while <code>.sfx</code> files (`72` in <em>LSW2</em>, `424` in <em>HP 1–4</em>) map gameplay events to sound bank sample IDs.</p>
"@
    }
    "ptl" = @{
        Name = ".ptl / .par (Particle System & Emitter Keyframe Curves)"
        Ext = ".ptl"
        Magic = "0x32000000 (.ptl) / PART_key (.par)"
        Category = "VFX & Particles"
        Scope = "Universal (LSW1 2005 through LEGO Dimensions 2015)"
        Desc = "Particle emitter system descriptors (.ptl) and keyframe parameter curves (.par) for sparks, magic spells, fire, smoke, and stud bursts."
        Details = @"
<h2>Overview</h2>
<p>Present across all generations from <em>LSW1</em> (`104` <code>.ptl</code> files) through <em>HP 1–4</em> (`410` <code>.ptl</code>, `2,140` <code>.par</code>) and <em>LEGO Dimensions</em> (`2,653` <code>.ptl</code> files).</p>
"@
    }
    "spl" = @{
        Name = ".spl / .fsp (EDSPLINE 3D Curve & Rail Paths)"
        Ext = ".spl"
        Magic = "EDSPLINE v. 03"
        Category = "Level Design & AI"
        Scope = "Universal (LSW1 2005 through LEGO Dimensions 2015)"
        Desc = "3D Bezier/Catmull-Rom spline curves (EDSPLINE v. 03) used for camera rails, coaster tracks, vehicle paths, and stud trails."
        Details = @"
<h2>Overview</h2>
<p>Begins with ASCII <code>EDSPLINE v. 03</code> followed by control point coordinates and tangents.</p>
"@
    }
    "ft2" = @{
        Name = ".ft2 / .fnt (Bitmap Font Texture & Glyph Metric Atlas)"
        Ext = ".ft2"
        Magic = "TNFN (0x4E464E54) / FNT"
        Category = "UI & Localization"
        Scope = "Universal (.fnt in LSW1; .ft2 in LSW2–Dimensions)"
        Desc = "Bitmap font glyph metric table and kerning dictionary paired with controller button icon atlases."
        Details = @"
<h2>Overview</h2>
<p>Uses magic <code>TNFN</code> (<code>NFNT</code>) to define glyph UV rectangles, baseline offsets, and kerning pairs for HUD text and localized subtitles.</p>
"@
    }
    "gip" = @{
        Name = ".gip / .gix / .gil (GUI Page, Index & Library Containers)"
        Ext = ".gip"
        Magic = "GUI Binary / XML Layout"
        Category = "UI & Localization"
        Scope = "Era 3–4 (HP 1–4, HP 5–7, Batman 2, Dimensions)"
        Desc = "Menu layout pages (.gip), widget indices (.gix), and shared UI element libraries (.gil) inside framework-data/ and gui/."
        Details = @"
<h2>Overview</h2>
<p>Drives front-end menus, character selection wheels, pause screens, and HUD overlays in NXG and DX11 titles.</p>
"@
    }
    "fmv" = @{
        Name = ".fmv / .bik / .pam / .pss / .xmv / .sfd (Full Motion Video)"
        Ext = ".fmv"
        Magic = "FMV! / BIKi / KB2 / PAM / XMV"
        Category = "Cinematics"
        Scope = "Universal (Platform-Specific Video Containers)"
        Desc = "Pre-rendered video streams used for publisher/developer logos, attract mode reels, and pre-rendered cutscenes."
        Details = @"
<h2>Platform Video Formats</h2>
<ul>
    <li><strong>PS2:</strong> <code>.pss</code> (MPEG-2 PlayStation Stream).</li>
    <li><strong>Original Xbox:</strong> <code>.xmv</code> (Microsoft Xbox Media Video) &amp; <code>.wmv</code>.</li>
    <li><strong>GameCube:</strong> <code>.sfd</code> (Sofdec MPEG-1) / <code>.thp</code>.</li>
    <li><strong>PS3 / Xbox 360 / PC:</strong> RAD Game Tools Bink Video (<code>.fmv</code> with <code>FMV!</code> wrapper, <code>.bik</code> with <code>BIKi</code>/<code>KB2</code>, and Sony <code>.pam</code>).</li>
</ul>
"@
    }
    "txt" = @{
        Name = ".txt / .csv (Plaintext Engine Configuration & Localization Tables)"
        Ext = ".txt"
        Magic = "Plaintext ASCII / UTF-8"
        Category = "Configuration & Metadata"
        Scope = "Universal (All TT Engine Generations 2005–2024)"
        Desc = "Master game configuration scripts (GAME.TXT, LEVELS.TXT, CHARS.TXT, COLLECTION.TXT, 360_exlist, FILETABLE.TXT) and multilingual localization tables (text.csv)."
        Details = @"
<h2>Key Configuration Files</h2>
<ul>
    <li><code>STUFF/GAME.TXT</code> &amp; <code>LEVELS.TXT</code>: Master campaign flow, hub links, and gameplay constants.</li>
    <li><code>360_exlist</code> (<em>LSW2</em> Xbox 360): 42-line extension translation map converting legacy PS2/Xbox extensions (<code>ghg</code>, <code>gsc</code>, <code>ter</code>, <code>cu2</code>, <code>an3</code>, <code>vag</code>) into Xbox 360 equivalents (<code>ctr</code>, <code>cc2</code>, <code>ca3</code>, <code>xma</code>).</li>
    <li><code>FILETABLE.TXT</code> &amp; <code>TRACKEDFILELIST360.TXT</code> (<em>Batman 2</em> PC): Developer build manifests revealing <code>__dlc1__</code>, <code>__dlc2__</code>, and <code>wii\</code> asset trees.</li>
    <li><code>text.csv</code>: Multilingual string table indexed by <code>LABEL</code> across English, French, German, Spanish, Italian, Danish, Dutch, etc.</li>
</ul>
"@
    }
    "dimensions_toytag" = @{
        Name = ".bin / .por / .ats (LEGO Dimensions NFC Toy Tag & Portal Formats)"
        Ext = ".bin / .por / .ats"
        Magic = "NTAG213 (0x04 UID) / Portal Descriptor"
        Category = "Title-Specific (LEGO Dimensions)"
        Scope = "LEGO Dimensions Exclusive (2015)"
        Desc = "180-byte NXP NTAG213 NFC Toy Tag dumps (.bin) encrypted with TEA (0xAA55 seed) alongside in-archive portal (.por) and ability/tag script (.ats) files."
        Details = @"
<h2>1. NTAG213 Physical NFC Toy Tag Dump (<code>.bin</code>, 180 Bytes)</h2>
<p>Verified against 47 Toy Tag dumps in <code>D:\PS3\Lego Dimensions\chars\</code> (every file is <strong>180 bytes</strong> = 45 pages × 4 bytes):</p>
<div class="table-scroll"><table class="format-counts">
<thead><tr><th>Pages</th><th>Byte Range</th><th>Field</th><th>Description</th></tr></thead>
<tbody>
<tr><td>0–2</td><td><code>0x00..0x0B</code></td><td>UID &amp; BCC</td><td>7-byte NXP hardware UID (<code>uid[0] = 0x04</code>) used to derive the per-tag 128-bit TEA key via seed <code>0xAA55</code>.</td></tr>
<tr><td>3</td><td><code>0x0C..0x0F</code></td><td>Capability Container</td><td><code>E1 10 12 00</code> (NFC Forum Type 2 Tag, NTAG213 144-byte user area).</td></tr>
<tr><td>36–37</td><td><code>0x90..0x97</code></td><td>Encrypted ID Block</td><td>8-byte 2-round TEA encrypted payload holding the 16-bit Character ID (Pages 36==37) or Vehicle ID + upgrades.</td></tr>
<tr><td>38</td><td><code>0x98..0x9B</code></td><td>Tag Type Marker</td><td><code>00 00 00 00</code> for Character Minifigures; <code>00 01 00 00</code> (BE <code>0x00010000</code>) for Vehicles / Gadgets.</td></tr>
<tr><td>43</td><td><code>0xAC..0xAF</code></td><td>PWD</td><td>32-bit password derived from UID.</td></tr>
</tbody>
</table></div>
<h2>2. Archive Portal &amp; Tag Formats (<code>.por</code>, <code>.ats</code>)</h2>
<p>Inside <em>LEGO Dimensions</em> <code>GAME*.DAT</code> and <code>INSTALL0_*.DAT</code>, <code>.por</code> (`644` files) and <code>.ats</code> (`1,497` files) configure Toy Pad portal vortex rendering, light-ring color protocols, and character/vehicle tag unlock scripts.</p>
"@
    }
    "worlds_formats" = @{
        Name = ".lxfml / .g1m / .g1t / .chunk (LEGO Worlds & NTT Voxel / Brick Formats)"
        Ext = ".lxfml"
        Magic = "<?xml (LXFML) / G1M / G1T"
        Category = "Title-Specific (LEGO Worlds)"
        Scope = "LEGO Worlds (2017) & Brick-Building Titles"
        Desc = "LEGO Digital Designer (LDD) XML brick assembly blueprints (.lxfml), procedural voxel terrain chunks, and brick stud connectivity graphs."
        Details = @"
<h2>Overview</h2>
<p>Uniquely among TT Games titles, <em>LEGO Worlds</em> (2017) replaces pre-modeled static <code>.gsc</code> levels with a real-time procedural voxel terrain generator and allows importing/exporting standard <strong>LEGO Digital Designer</strong> (<code>.lxfml</code> / <code>.lxf</code>) brick blueprints alongside <code>.CC40TAD</code> (TOC v-10/-11) archives.</p>
"@
    }
}

Write-Host "Format definitions dictionary loaded ($($DatFormats.Count) formats)." -ForegroundColor Green

# --------------------------------------------------------------------------------------------------
# ROOT FORMAT GENERATORS (xex, bin, exe, dat)
# --------------------------------------------------------------------------------------------------

function Build-RootFormats([string]$DocsDir, [string]$ProjectTitle, [string]$BackUpLink) {
    $FormatsDir = Join-Path $DocsDir "Formats"
    Ensure-Dir $FormatsDir

    # --- xex ---
    $XexDir = Join-Path $FormatsDir "xex"
    Ensure-Dir $XexDir
    $xexContent = @"
<h1>Xbox &amp; Xbox 360 Executables (.xex / .xbe)</h1>
<aside class="source-notice"><p><strong>Platforms:</strong> Microsoft Xbox 360 (<code>XEX2</code> Xenon PPC64 BE) &amp; Original Xbox (<code>XBEH</code> x86 LE)</p></aside>
<section class="format-summary">
    <p class="eyebrow">Executable Containers · Retail Discs, Demos &amp; STFS Packages</p>
    <p>Microsoft console executable containers: Original Xbox <code>default.xbe</code> (32-bit x86 image at base <code>0x00010000</code>) for Era 1–2 and Xbox 360 <code>Default.xex</code> (64-bit Big-Endian PowerPC PE image at base <code>0x82000000</code>) for Era 2–4.</p>
    <dl>
        <dt>Container Signatures</dt><dd><code>XEX2</code> (<code>0x58455832</code>, Xbox 360) · <code>XBEH</code> (<code>0x48454258</code>, Original Xbox)</dd>
        <dt>Inspected Titles</dt><dd><em>LSW1</em> Xbox (<code>default.xbe</code>, 2.74 MB), <em>LSW2</em> Xbox (<code>default.xbe</code>, 3.66 MB), <em>LSW2</em> X360 (<code>default.xex</code>, 6.29 MB), <em>HP 1–4</em> X360 (<code>Default.xex</code>, Title ID <code>0x575207E6</code>), <em>HP 5–7</em> X360 (<code>Default.xex</code>, Title ID <code>0x57520812</code>)</dd>
        <dt>Decryption Tooling</dt><dd><code>XexTool v7.0</code> (<code>-u -o Default_unpacked.xex -d . -i Default.idc Default.xex</code>)</dd>
    </dl>
</section>
<h2>Inspected Xbox &amp; Xbox 360 Executables</h2>
<div class="table-scroll"><table class="format-counts">
<thead><tr><th>Title &amp; Platform</th><th>Executable</th><th>Size</th><th>Internal PE / Details</th></tr></thead>
<tbody>
<tr><td><em>LEGO Star Wars: The Video Game</em> (Xbox USA)</td><td><code>default.xbe</code></td><td><code>2,740,224</code> B</td><td><code>XBEH</code> x86 image reading loose <code>.nux</code>, <code>.hgx</code>, <code>.ani</code>, <code>.bsa</code>, <code>.wavx</code> files from XDVDFS.</td></tr>
<tr><td><em>LEGO Star Wars II: The Original Trilogy</em> (Xbox)</td><td><code>default.xbe</code></td><td><code>3,661,824</code> B</td><td><code>XBEH</code> x86 image reading loose <code>.nx2</code>, <code>.hx2</code>, <code>.an3</code>, <code>.fpk</code> files.</td></tr>
<tr><td><em>LEGO Star Wars II: The Original Trilogy</em> (Xbox 360)</td><td><code>default.xex</code></td><td><code>6,287,360</code> B</td><td><code>XEX2</code> Xenon PPC64 executable reading loose XDVDFS assets via <code>360_exlist</code>.</td></tr>
<tr><td><em>LEGO Harry Potter: Years 1–4</em> (Xbox 360)</td><td><code>Default.xex</code></td><td><code>9,838,592</code> B</td><td>Unpacks to <code>legogame_Final_360.exe</code> (25.3 MB, Title ID <code>0x575207E6</code>, Media ID <code>0x3E371834</code>).</td></tr>
<tr><td><em>LEGO Harry Potter: Years 5–7</em> (Xbox 360)</td><td><code>Default.xex</code></td><td><code>11,640,832</code> B</td><td>Unpacks to <code>harry2.master.pe</code> (13.7 MB, Title ID <code>0x57520812</code>, Media ID <code>0x61D8E1DE</code>).</td></tr>
</tbody>
</table></div>
"@
    Write-HtmlFile (Join-Path $XexDir "index.html") (Get-HtmlPage "Xbox & Xbox 360 Executables (.xex / .xbe)" "<a href='../../index.html#home' target='_parent'>Documentation</a><span>/</span><a href='../../index.html#Formats-dat' target='_parent'>Formats</a><span>/</span>.xex" $xexContent "../../style/main.css")

    # --- bin ---
    $BinDir = Join-Path $FormatsDir "bin"
    Ensure-Dir $BinDir
    $binContent = @"
<h1>PlayStation Executables (.BIN / EBOOT.BIN &amp; PS2 ELF)</h1>
<aside class="source-notice"><p><strong>Platforms:</strong> Sony PlayStation 3 (<code>SCE\0</code> SELF PPU ELF64 BE) &amp; PlayStation 2 (MIPS R5900 ELF32 LE)</p></aside>
<section class="format-summary">
    <p class="eyebrow">PlayStation Executable Containers · PS2 IOP/EE &amp; PS3 CellOS</p>
    <p>Sony PlayStation executables across generations: PS2 Emotion Engine 32-bit MIPS ELF binaries (<code>SLUS_*</code> / <code>SLES_*</code>) and PS3 signed 64-bit Cell PPU SELF executables (<code>PS3_GAME/USRDIR/EBOOT.BIN</code>).</p>
    <dl>
        <dt>Header Signatures</dt><dd><code>SCE\0</code> + <code>\x7FELF</code> at <code>0x90</code> (PS3 SELF) · <code>\x7FELF</code> (PS2 MIPS R5900 LE)</dd>
        <dt>Inspected PS2 Builds</dt><dd><em>LSW1</em> (<code>SLUS_210.83</code>, 3.16 MB), <em>LSW2</em> (<code>SLUS_214.09</code>, <code>SLES_542.21</code>, <code>SLED_543.15</code>, <code>SLPM_665.72</code>, 3.63 MB)</dd>
        <dt>Inspected PS3 Builds</dt><dd><em>HP 1–4</em> (<code>BLES00752</code> v01.02 &amp; v03.01), <em>HP 5–7</em> (<code>BLES01297</code>), <em>LEGO Dimensions</em> (<code>BLES02158</code> &amp; <code>BLUS31456</code>, 15.86 MB)</dd>
    </dl>
</section>
<h2>Inspected PlayStation Executables</h2>
<div class="table-scroll"><table class="format-counts">
<thead><tr><th>Title &amp; Disc ID</th><th>Executable</th><th>Size</th><th>Architecture &amp; Archive Role</th></tr></thead>
<tbody>
<tr><td><em>LEGO Star Wars: The Video Game</em> (PS2 USA v2.00)</td><td><code>SLUS_210.83</code></td><td><code>3,163,692</code> B</td><td>MIPS R5900 ELF32; mounts <code>GAME.DAT</code> (TOC <code>v-1</code>) and decompresses <code>RNC\x02</code> streams.</td></tr>
<tr><td><em>LEGO Star Wars II</em> (PS2 USA / EU / Demo / JP)</td><td><code>SLUS_214.09</code></td><td><code>3,630,368</code> B</td><td>MIPS R5900 ELF32; mounts 1.74 GB <code>GAME.DAT</code> (TOC <code>v-1</code>, 8,600 files).</td></tr>
<tr><td><em>LEGO Harry Potter: Years 1–4</em> (PS3 EU)</td><td><code>EBOOT.BIN</code></td><td><code>8,809,856</code> B</td><td>Cell PPU ELF64; mounts <code>GAME.DAT</code> + <code>GAME1.DAT</code>..<code>GAME4.DAT</code> (<code>PakDat v1.01</code> TOC <code>v-4</code>, <code>LZ2K</code>).</td></tr>
<tr><td><em>LEGO Harry Potter: Years 5–7</em> (PS3 EU)</td><td><code>EBOOT.BIN</code></td><td><code>6,708,864</code> B</td><td>Cell PPU ELF64; mounts <code>GAME0.DAT</code>..<code>GAME3.DAT</code> (<code>PakDat v1.01</code> TOC <code>v-4</code>, <code>LZ2K</code>).</td></tr>
<tr><td><em>LEGO Dimensions</em> (PS3 EU <code>BLES02158</code> / US <code>BLUS31456</code>)</td><td><code>EBOOT.BIN</code></td><td><code>15,857,088</code> B</td><td>Cell PPU ELF64; mounts <code>GAME*.HDR</code>/<code>.DAT</code> (TOC <code>v-7</code>, <code>DFLT</code>) + <code>CMP2</code> LZMA <code>INSTALL0_*.DAT</code> and USB Toy Pad hid driver.</td></tr>
</tbody>
</table></div>
"@
    Write-HtmlFile (Join-Path $BinDir "index.html") (Get-HtmlPage "PlayStation Executables (.BIN / ELF)" "<a href='../../index.html#home' target='_parent'>Documentation</a><span>/</span><a href='../../index.html#Formats-dat' target='_parent'>Formats</a><span>/</span>.bin" $binContent "../../style/main.css")

    # --- exe ---
    $ExeDir = Join-Path $FormatsDir "exe"
    Ensure-Dir $ExeDir
    $exeContent = @"
<h1>PC Windows Executables (.exe — PE32 x86 &amp; PE32+ AMD64)</h1>
<aside class="source-notice"><p><strong>Platform:</strong> Microsoft Windows (Retail Disc &amp; Steam) · 32-bit x86 (<code>PE32</code>) &amp; 64-bit AMD64 (<code>PE32+</code>)</p></aside>
<section class="format-summary">
    <p class="eyebrow">Windows Portable Executables · Direct3D 9 &amp; Direct3D 11</p>
    <p>Native Windows executables spanning Era 2 (<code>LEGOSTA2.EXE</code>), Era 3c (<code>LEGOBatman2.exe</code>), and the 2024 Double Eleven 64-bit remasters (<code>harry1.exe</code>, <code>harry2.exe</code>).</p>
    <dl>
        <dt>Header Magic</dt><dd><code>MZ</code> (<code>0x5A4D</code>), <code>PE\0\0</code> (<code>0x00004550</code>)</dd>
        <dt>Inspected Executables</dt><dd><code>LEGOSTA2.EXE</code> (2006 x86), <code>LEGOBatman2.exe</code> (2012 x86), <code>harry1.exe</code> &amp; <code>harry2.exe</code> (2024 AMD64)</dd>
    </dl>
</section>
<h2>Inspected Windows Executables</h2>
<div class="table-scroll"><table class="format-counts">
<thead><tr><th>Title</th><th>Executable</th><th>Size &amp; Arch</th><th>Compiler / PDB &amp; Embedded Signatures</th></tr></thead>
<tbody>
<tr><td><em>LEGO Star Wars II</em> (2006 PC ISO)</td><td><code>LEGOSTA2.EXE</code></td><td><code>7,493,144</code> B (<code>PE32</code> x86)</td><td>Timestamp <code>2006-09-26 17:21:58 UTC</code>; PDB: <code>c:\projects\starwars\Release_2K\starwars_pc.pdb</code>; mounts <code>GAME.DAT</code>, <code>PATCH.DAT</code>, <code>STARTUP.DAT</code>; SecuROM v7 <code>.securom</code> section.</td></tr>
<tr><td><em>LEGO Batman 2: DC Super Heroes</em> (2012 Steam)</td><td><code>LEGOBatman2.exe</code></td><td><code>18,690,560</code> B (<code>PE32</code> x86)</td><td>Timestamp <code>2012-05-25 13:57:20 UTC</code>; mounts <code>GAME0.DAT</code>..<code>GAME6.DAT</code> (<code>PakDat v1.01</code> TOC <code>v-4</code>); contains <code>LZ2K</code>, <code>DXBC</code>, <code>FMOD</code>, and <code>StreamInfo</code> reflection tables.</td></tr>
<tr><td><em>LEGO Harry Potter Collection</em> (2024 Steam)</td><td><code>harry1.exe</code> / <code>harry2.exe</code></td><td><code>13.09 MB</code> / <code>14.43 MB</code> (<code>PE32+</code> AMD64)</td><td><code>x64FinalD11Static</code>; mounts <code>.datwin</code> (TOC <code>v-1</code> with <code>0x12345678</code> canary and <code>LZHAM</code>) and <code>.pkiwin</code>/<code>.pkdwin</code> (zlib).</td></tr>
</tbody>
</table></div>
"@
    Write-HtmlFile (Join-Path $ExeDir "index.html") (Get-HtmlPage "Windows Executables (.exe)" "<a href='../../index.html#home' target='_parent'>Documentation</a><span>/</span><a href='../../index.html#Formats-dat' target='_parent'>Formats</a><span>/</span>.exe" $exeContent "../../style/main.css")

    # --- dat (Container format) ---
    $DatDir = Join-Path $FormatsDir "dat"
    Ensure-Dir $DatDir
    $datContent = @"
<h1>TT Games Archive Package Formats (.DAT, PakDat, .HDR, CMP2 &amp; .datwin)</h1>
<aside class="source-notice"><p><strong>Primary Archive Containers Across All Generations:</strong> <code>GAME*.DAT</code>, <code>GAME*.HDR</code>, <code>INSTALL*.DAT</code>, <code>*.datwin</code>, and <code>*.pkiwin/*.pkdwin</code></p></aside>
<section class="format-summary">
    <p class="eyebrow">Container Format Specification · TOC Versions -1 through -12 (2005–2024)</p>
    <p>Every Traveller's Tales archive volume stores packed asset payloads followed by a trailing Table of Contents (TOC) at the end of the file (or mirrored in a companion <code>.HDR</code> file in Era 4+).</p>
    <dl>
        <dt>Era 1–2 Header (8 B, TOC v-1)</dt><dd><code>int32 TocOffset</code>, <code>uint32 TocSize</code> (direct byte offsets; no trailing hash array)</dd>
        <dt>Era 3 Header (57 B, TOC v-4)</dt><dd><code>int32 RawTocOffset</code>, <code>uint32 TocSize</code>, 49-byte <code>BEGIN_APP_ID_STRINGPakDat v1.01END_APP_ID_STRING\0</code></dd>
        <dt>Era 4 Header (TOC v-7 + .HDR)</dt><dd>4-byte BE <code>TocSize</code> + TOC in <code>.HDR</code>; 12-byte <code>NameNodes</code>; <code>ROTV</code> tables; <code>CMP2</code> LZMA wrapper on <code>INSTALL*.DAT</code></dd>
        <dt>PC Remaster Header (16 B)</dt><dd><code>int64 TocOffset</code>, <code>uint64 TocSize</code> (24-byte entries with <code>0x12345678</code> canary + <code>LZHAM</code>)</dd>
    </dl>
</section>

<h2>1. Complete .DAT TOC Version Evolution (2005–2024)</h2>
<div class="table-scroll"><table class="format-counts">
<thead><tr><th>TOC Version</th><th>Header Signature</th><th>Entry &amp; Node Sizes</th><th>Compression Codecs</th><th>Representative Titles (Inspected in Bold)</th></tr></thead>
<tbody>
<tr><td><code>-1</code> (<code>0xFFFFFFFF</code>)</td><td>8-byte <code>[TocOffset, TocSize]</code></td><td>16B Entry (direct offset), 8B Node, <strong>No Hash Array</strong></td><td>Raw (<code>0</code>) + inner <code>RNC\x02</code> on PS2</td><td><strong>LSW1 (2005 PS2)</strong>, <strong>LSW2 (2006 PS2)</strong></td></tr>
<tr><td><code>-2</code> / <code>-3</code></td><td>8B or <code>PakDat</code></td><td>16B Entry (256B sector shift), 8B Node, <code>TtPathHash[N]</code></td><td>Raw (<code>0</code>), <code>RFPK</code> / early <code>LZ2K</code></td><td><strong>LSW2 (2006 PC)</strong>, <em>TCS</em> (2007), <em>Indy 1</em> (2008), <em>Batman 1</em> (2008)</td></tr>
<tr><td><code>-4</code> (<code>0xFFFFFFFC</code>)</td><td><strong>57-byte</strong> <code>PakDat v1.01</code></td><td>16B Entry, 8B Node (<code>-Child = 0..N-1</code>), <code>TtPathHash[N]</code>, 8B Footer</td><td>Raw (<code>0</code>), <code>LZ2K</code> (<code>2</code>)</td><td><em>Indy 2</em> (2009), <strong>HP 1–4 (2010)</strong>, <em>Clone Wars</em> (2011), <em>PotC</em> (2011), <strong>HP 5–7 (2011)</strong>, <strong>Batman 2 (2012)</strong></td></tr>
<tr><td><code>-5</code> (<code>0xFFFFFFFB</code>)</td><td>57-byte <code>PakDat v1.02</code></td><td>16B Entry, 8B/12B Node, <code>TtPathHash[N]</code></td><td>Raw (<code>0</code>), <code>LZ2K</code> (<code>2</code>), <code>DFLT</code> (<code>3</code>)</td><td><em>LOTR</em> (2012), <em>City Undercover</em> (2013), <em>Marvel 1</em> (2013), <em>LEGO Movie</em> (2014), <em>Hobbit</em> (2014)</td></tr>
<tr><td><code>-6</code> / <code>-7</code> (<code>0xFFFFFFF9</code>)</td><td>57-byte <code>PakDat</code> + companion <code>.HDR</code></td><td>16B Entry, <strong>12B Node</strong> (non-seq <code>-Child = EntryIdx</code>), <code>TtPathHash[N]</code>, <code>ROTV</code>×2</td><td>Raw (<code>0</code>), <code>LZ2K</code> (<code>2</code>), <code>DFLT</code> (<code>3</code>), outer <code>CMP2</code> LZMA</td><td><em>Batman 3</em> (2014), <em>Jurassic World</em> (2015), <strong>LEGO Dimensions (2015 PS3)</strong>, <em>Avengers</em> (2016)</td></tr>
<tr><td><code>-8</code> .. <code>-12</code></td><td><code>.CC40TAD</code> / <code>DAT04CC.</code></td><td>16B/20B Entry, 12B Node, 32-bit or 64-bit FNV-1a Hashes</td><td>Raw, <code>LZ2K</code>, <code>DFLT</code>, <code>ZIPX</code> (RC4+Deflate), <code>OODL</code> (Oodle)</td><td><em>Star Wars TFA</em> (2016), <em>LEGO Worlds</em> (2017), <em>Marvel 2</em> (2017), <em>DC Super-Villains</em> (2018), <em>Skywalker Saga</em> (2022)</td></tr>
<tr><td>Remaster <code>-1</code></td><td>16-byte <code>[int64 TocOffset, uint64 TocSize]</code></td><td><strong>24B Entry</strong> (<code>0x12345678</code> canary), No Name Tree, <code>TtPathHash[N]</code></td><td>Raw, <code>LZ2K</code>, <code>Zlib</code>, <code>LZHAM</code> (<code>0x04040404</code>)</td><td><strong>LEGO Harry Potter Collection (2024 PC .datwin)</strong></td></tr>
</tbody>
</table></div>

<h2>2. Detailed Layout by Generation</h2>

<h3>2.1 Era 1–2: TOC <code>Version = -1</code> (LSW1 &amp; LSW2 PS2 <code>GAME.DAT</code>)</h3>
<p>Verified on <em>LSW1</em> PS2 (<code>615,527,160</code> B, <code>4,223</code> files) and <em>LSW2</em> PS2 (<code>1,739,697,816</code> B, <code>8,600</code> files):</p>
<ul>
    <li><strong>Header (8 Bytes at <code>0x00</code>):</strong> <code>int32 TocOffset</code> (direct positive byte offset) and <code>uint32 TocSize</code>.</li>
    <li><strong>TOC Block (at <code>TocOffset</code>):</strong> <code>int32 Version = -1</code>, <code>uint32 FileCount</code>, <code>16 * FileCount</code> bytes of entries (direct 32-bit <code>ByteOffset</code>, <code>CompressedSize</code>, <code>UncompressedSize</code>, <code>Flags</code>), <code>uint32 NameNodeCount</code>, <code>8 * NameNodeCount</code> bytes of <code>NameNodes</code>, <code>uint32 StringTableSize</code>, and <code>char StringTable[StringTableSize]</code>. Ends immediately at EOF (<code>RemainderBytes = 0</code>; no hash table).</li>
</ul>

<h3>2.2 Era 3: <code>PakDat v1.01</code> TOC <code>Version = -4</code> (HP 1–4, HP 5–7, Batman 2)</h3>
<div class="table-scroll"><table class="format-counts">
<thead><tr><th>Offset</th><th>Size</th><th>Type</th><th>Field</th><th>Description</th></tr></thead>
<tbody>
<tr><td>0x00</td><td>4</td><td>Int32</td><td>RawTocOffset</td><td>If negative: <code>TocOffset = ((uint)(-RawTocOffset) &lt;&lt; 8)</code>. If positive: direct byte offset (until file exceeds ~2 GiB).</td></tr>
<tr><td>0x04</td><td>4</td><td>UInt32</td><td>TocSize</td><td>Exact byte length of the trailing Table of Contents block (`TocOffset + TocSize == FileSize`).</td></tr>
<tr><td>0x08</td><td>49</td><td>Char[49]</td><td>Signature</td><td><code>BEGIN_APP_ID_STRINGPakDat v1.01END_APP_ID_STRING\0</code> (total header size = <strong>57 bytes</strong>, <code>0x00..0x38</code>).</td></tr>
</tbody>
</table></div>
<p>Each 16-byte <code>PakDatFileEntry</code> computes its exact byte offset via <code>ByteOffset = (OffsetSector &lt;&lt; 8) + SubSectorOffset</code>. Leaf <code>NameNodes</code> (<code>Child &lt; 0</code>) assign <code>EntryIndex</code> sequentially (`0 .. FileCount - 1`), and the TOC finishes with <code>uint32 TtPathHash[FileCount]</code> plus an 8-byte footer.</p>

<h3>2.3 Era 4: TOC <code>Version = -7</code>, Split <code>.HDR</code> &amp; <code>CMP2</code> LZMA (LEGO Dimensions PS3)</h3>
<p>Verified across all 10 <code>.HDR</code>/<code>.DAT</code> pairs in <em>LEGO Dimensions</em> PS3 (<code>124,716</code> total files):</p>
<ul>
    <li><strong>Companion <code>.HDR</code> File:</strong> 4-byte Big-Endian <code>uint32 TocSize</code> followed by the exact `TocSize`-byte TOC mirrored from the end of <code>.DAT</code>.</li>
    <li><strong>12-Byte <code>NameNodes</code> (Non-Sequential Leaf Indexing):</strong> <code>int32 Next</code>, <code>int32 Child</code>, <code>uint32 NameOffsetAndFlags</code>. When <code>Child &lt; 0</code>, the entry index is directly <code>EntryIndex = -Child</code> (non-sequential; verified <code>19,000 / 19,000</code> = <code>100.0%</code> <code>TtPathHash</code> match in <code>GAME.HDR</code>).</li>
    <li><strong>Trailing <code>ROTV</code> Metadata:</strong> After <code>uint32 TtPathHash[N]</code>, the TOC contains a null-terminated <code>RootPrefix</code> string (e.g. <code>C:\projects\lego_dimensions\data</code> in <code>GAME0.HDR</code>), 24 zero bytes, and two <code>"ROTV"</code> (<code>52 4F 54 56</code>) blocks of <code>4 + 16 * N</code> bytes each.</li>
    <li><strong><code>DFLT</code> Chunked Deflate (Compression Type <code>3</code>):</strong> 12-byte chunk header (<code>"DFLT"</code>, <code>uint32 CompSize</code>, <code>uint32 UncompSize</code> up to <code>32,768</code> B) followed by raw RFC 1951 Deflate.</li>
    <li><strong><code>CMP2</code> Outer Archive Compression (<code>INSTALL0_*.DAT</code>):</strong> 16-byte magic <code>CMP2CMP2CMP2CMP2</code> + 16-byte hash + 8-byte BE <code>uint64 UncompressedArchiveSize</code> + 5-byte LZMA properties (<code>5D 00 00 00 02</code>, 32 MB dictionary) + LZMA stream.</li>
</ul>

<h2>3. TT Games Path Hashing Algorithm (<code>TtPathHash</code>)</h2>
<pre><code>public static uint ComputeTtPathHash(string path) {
    uint hash = 0x811C9DC5u; // FNV-1 offset basis
    foreach (char c in path) {
        char ch = char.ToUpperInvariant(c);
        if (ch == '/') ch = '\\';
        hash = (hash ^ (byte)ch) * 0x00199933u; // TT Games custom prime (1,677,619)
    }
    return hash;
}
</code></pre>
"@
    Write-HtmlFile (Join-Path $DatDir "dat.html") (Get-HtmlPage "TT Games Archive Formats (.DAT / .HDR / CMP2 / .datwin)" "<a href='../../index.html#home' target='_parent'>Documentation</a><span>/</span><a href='../../index.html#Formats-dat' target='_parent'>Formats</a><span>/</span>.dat" $datContent "../../style/main.css")

    # --- datFormats child pages ---
    $DatFormatsDir = Join-Path $DatDir "datFormats"
    Ensure-Dir $DatFormatsDir

    foreach ($fmtKey in $DatFormats.Keys) {
        $fmt = $DatFormats[$fmtKey]
        $pageHtml = @"
<h1>$($fmt.Name)</h1>
<aside class="source-notice"><p><strong>Category:</strong> $($fmt.Category) · <strong>Scope:</strong> $($fmt.Scope)</p></aside>
<section class="format-summary">
    <p class="eyebrow">Format Specification · TT Games Engine</p>
    <p>$($fmt.Desc)</p>
    <dl>
        <dt>File Extension</dt><dd><code>$($fmt.Ext)</code></dd>
        <dt>Header Signature / Magic</dt><dd><code>$($fmt.Magic)</code></dd>
        <dt>Subsystem</dt><dd>$($fmt.Category)</dd>
        <dt>Cross-Game Scope</dt><dd>$($fmt.Scope)</dd>
    </dl>
</section>
$($fmt.Details)
"@
        Write-HtmlFile (Join-Path $DatFormatsDir "$fmtKey.html") (Get-HtmlPage $fmt.Name "<a href='../../../index.html#home' target='_parent'>Documentation</a><span>/</span><a href='../../../index.html#Formats-dat' target='_parent'>Formats</a><span>/</span><a href='../../../index.html#Formats-dat' target='_parent'>.dat</a><span>/</span>$($fmt.Ext)" $pageHtml "../../../style/main.css")
    }
}

# --------------------------------------------------------------------------------------------------
# FILES SECTION GENERATORS (Per-Project & Cross-Game Combined Filesystem)
# --------------------------------------------------------------------------------------------------

function Build-FilesSection([string]$DocsDir, [string]$ProjectKey, [string]$ProjectTitle, [string]$BackUpLink) {
    $FilesDir = Join-Path $DocsDir "Files"
    Ensure-Dir $FilesDir

    $customOverviewHtml = ""
    switch ($ProjectKey) {
        "Travellers_Tales" {
            $customOverviewHtml = @"
    <h2>1. Traveller's Tales Engine Architecture Evolution (2005–2024)</h2>
    <div class="table-scroll"><table class="format-counts">
    <thead><tr><th>Generation</th><th>Engine Codename</th><th>Years</th><th>Titles</th><th>Key Container &amp; Format Signatures</th></tr></thead>
    <tbody>
    <tr><td><strong>Era 1</strong></td><td>Nu2 / <code>NUP</code> Engine</td><td>2005</td><td><em>LEGO Star Wars: The Video Game</em></td><td><code>GAME.DAT</code> TOC <code>v-1</code> (PS2 <code>RNC\x02</code>); loose <code>.nux</code>/<code>.hgx</code>/<code>.ani</code>/<code>.bsa</code> on Xbox; <code>.nup</code>/<code>.hgp</code> on PC/GCN.</td></tr>
    <tr><td><strong>Era 2</strong></td><td>Nu2 / <code>PC.GHG</code> Classic</td><td>2006–2008</td><td><em>LSW2</em>, <em>TCS</em>, <em>Indiana Jones 1</em>, <em>Batman 1</em></td><td><code>GAME.DAT</code> TOC <code>v-1</code>..<code>v-3</code>; <code>.gsc</code>/<code>.ghg</code> (<code>NU20</code> v<code>0x28</code>..<code>0x40</code>), <code>.an3</code>, <code>.cu2</code>, <code>.fpk</code> (<code>RFPK</code>); <code>360_exlist</code> on Xbox 360.</td></tr>
    <tr><td><strong>Era 3a–3c</strong></td><td>NXG Engine (<em>Creator</em> / <em>Builder</em> / <em>Gotham</em>)</td><td>2009–2014</td><td><em>Indy 2</em>, <em>HP 1–4</em>, <em>Clone Wars</em>, <em>PotC</em>, <em>HP 5–7</em>, <em>Batman 2</em>, <em>LOTR</em>, <em>Marvel 1</em>, <em>Hobbit</em></td><td>57-byte <code>PakDat v1.01</code>/<code>v1.02</code> (TOC <code>v-4</code>/<code>v-5</code>, <code>LZ2K</code>); <code>.CC4</code>+<code>HSER</code>+<code>02UN</code> resources; <code>StreamInfo</code> <code>.cd</code>/<code>.cpd</code>/<code>.as</code>/<code>.apj</code>/<code>.led</code>; <code>.dno</code>, <code>.giz</code>, <code>.sf</code>, <code>.sub</code> (from <em>Batman 2</em>).</td></tr>
    <tr><td><strong>Era 4a–4b</strong></td><td>DX11 / <em>Cinema</em> / <em>TFA</em> Engine</td><td>2014–2019</td><td><em>Batman 3</em>, <em>Jurassic World</em>, <em>LEGO Dimensions</em>, <em>Avengers</em>, <em>TFA</em>, <em>LEGO Worlds</em>, <em>Marvel 2</em>, <em>DC Super-Villains</em></td><td>Split <code>.HDR</code> + <code>.DAT</code> (TOC <code>v-6</code>..<code>v-12</code>, 12B <code>NameNodes</code>, <code>DFLT</code>, <code>CMP2</code> LZMA, <code>.CC40TAD</code>); compiled Lua 5.1 (<code>.lua</code>); <code>.cu3</code>; NFC <code>.bin</code>/<code>.por</code>/<code>.ats</code> in <em>Dimensions</em>; <code>.lxfml</code> in <em>Worlds</em>.</td></tr>
    <tr><td><strong>Era 5</strong></td><td>NTT Engine</td><td>2022</td><td><em>LEGO Star Wars: The Skywalker Saga</em></td><td><code>.CC40TAD</code> TOC <code>v-12</code> with 64-bit FNV-1a hashes and Oodle Mermaid (<code>OODL</code>) compression.</td></tr>
    <tr><td><strong>Remaster</strong></td><td>Double Eleven DX11 x64</td><td>2016–2024</td><td><em>LEGO Harry Potter Collection</em> (PS4 / Switch / PC Steam)</td><td><code>.datwin</code> (TOC <code>v-1</code> with 24B entries, <code>0x12345678</code> canary, <code>LZHAM</code>) + <code>.pkiwin</code>/<code>.pkdwin</code> (zlib).</td></tr>
    </tbody>
    </table></div>

    <h2>2. Cross-Game Format Census Across Inspected Archives</h2>
    <p>Empirical file counts measured directly from extracted TOCs and disc images across six inspected titles:</p>
    <div class="table-scroll"><table class="format-counts">
    <thead><tr><th>Format / Extension</th><th>Subsystem</th><th>LSW1 (2005 Xbox/PS2)</th><th>LSW2 (2006 PS2/Xbox/X360)</th><th>HP 1–4 (2010 PS3/X360/PC)</th><th>HP 5–7 (2011 PS3/X360/PC)</th><th>Batman 2 (2012 WinSteam)</th><th>Dimensions (2015 PS3)</th></tr></thead>
    <tbody>
    <tr><td><code>.gsc</code> / <code>.nux</code> / <code>.nx2</code></td><td>Scene Geometry</td><td>259 (<code>.nux</code>) + 18 (<code>.nus</code>)</td><td>448 (PS2) / 474 (<code>.nx2</code>) / 500 (X360)</td><td>610</td><td>436</td><td>816</td><td>1,445</td></tr>
    <tr><td><code>.ghg</code> / <code>.hgx</code> / <code>.hx2</code></td><td>Skeletal Models</td><td>163 (<code>.hgx</code>)</td><td>255 (PS2) / 261 (<code>.hx2</code>) / 254 (X360)</td><td>1,455</td><td>1,246</td><td>2,265</td><td>7,414</td></tr>
    <tr><td><code>.tex</code> / <code>.nxg_textures</code></td><td>Standalone Textures</td><td>Inline in <code>.nux</code>/<code>.hgx</code></td><td>Inline in <code>.gsc</code>/<code>.ghg</code></td><td>4,487</td><td>3,395</td><td>4,715</td><td>14,209</td></tr>
    <tr><td><code>.an3</code> / <code>.ca3</code> / <code>.ani</code> / <code>.anm</code></td><td>Animations</td><td>973 (<code>.ani</code>)</td><td>2,440 (<code>.an3</code>) / 26 (<code>.ca3</code>)</td><td>1,612 (<code>.anm</code>/<code>.an3</code>)</td><td>2,180</td><td>213 (<code>.anm</code>)</td><td>19,580 (<code>.an3</code>)</td></tr>
    <tr><td><code>.bsa</code> / <code>.anl</code></td><td>Era 1–2 Blend / Lists</td><td>679 (<code>.bsa</code>)</td><td>1,999 (<code>.bsa</code>) + 184 (<code>.anl</code>)</td><td>—</td><td>—</td><td>—</td><td>—</td></tr>
    <tr><td><code>.cd</code> / <code>.cpd</code> / <code>.as</code> / <code>.apj</code></td><td><code>StreamInfo</code> Character</td><td>—</td><td>—</td><td>1,120+</td><td>1,340+</td><td>1,671</td><td>7,068</td></tr>
    <tr><td><code>.led</code></td><td><code>StreamInfo</code> Level Entities</td><td>—</td><td>—</td><td>890</td><td>740</td><td>564</td><td>2,616</td></tr>
    <tr><td><code>.dno</code></td><td>Dynamic Brick Objects</td><td>—</td><td>—</td><td>6,858</td><td>5,204</td><td>3,240</td><td>17,672</td></tr>
    <tr><td><code>.giz</code> / <code>.git</code></td><td>Gizmos &amp; Camera Options</td><td>—</td><td>—</td><td>1,210</td><td>980</td><td>1,012</td><td>3,643</td></tr>
    <tr><td><code>.ter</code> / <code>.ctr</code></td><td>Terrain Collision Octree</td><td>149</td><td>140 (<code>.ter</code>) / 179 (<code>.ctr</code>)</td><td>312</td><td>245</td><td>564</td><td>1,148</td></tr>
    <tr><td><code>.rtl</code></td><td>Runtime Light Lists</td><td>163</td><td>156 (PS2) / 178 (X360)</td><td>305</td><td>240</td><td>524</td><td>1,123</td></tr>
    <tr><td><code>.ai2</code> / <code>.aib</code></td><td>AI Navigation Mesh</td><td>120 (<code>.ai2</code>)</td><td>45 (<code>.ai2</code>)</td><td>195 (<code>.ai2</code>)</td><td>160 (<code>.ai2</code>)</td><td>85 (<code>.ai2</code>) + 284 (<code>.aib</code>)</td><td>856 (<code>.aib</code>)</td></tr>
    <tr><td><code>.scp</code> / <code>.sf</code> / <code>.lua</code></td><td>Gameplay Scripts</td><td>500 (<code>.scp</code>)</td><td>525 (<code>.scp</code>)</td><td>1,405 (<code>.scp</code>) + 677 (<code>.sf</code>)</td><td>412 (<code>.scp</code>) + 4,296 (<code>.sf</code>)</td><td>324 (<code>.scp</code>) + 5,274 (<code>.sf</code>)</td><td>9,858 (<code>.lua</code>) + 222 (<code>.sf</code>)</td></tr>
    <tr><td><code>.cut</code> / <code>.cu2</code> / <code>.cc2</code> / <code>.cu3</code></td><td>Cutscene Timelines</td><td>184 (<code>.cut</code>)</td><td>76 (<code>.cu2</code> / <code>.cc2</code>)</td><td>401 (<code>.cu2</code>)</td><td>250 (<code>.cu2</code>)</td><td>245 (<code>.cu2</code>)</td><td>190 (<code>.cu3</code>)</td></tr>
    <tr><td><code>.sub</code></td><td>Voice Subtitles</td><td>—</td><td>—</td><td>—</td><td>—</td><td>2,408</td><td>15,826</td></tr>
    <tr><td><code>.por</code> / <code>.ats</code> / NFC <code>.bin</code></td><td>Dimensions Toy Pad</td><td>—</td><td>—</td><td>—</td><td>—</td><td>—</td><td>644 (<code>.por</code>) + 1,497 (<code>.ats</code>) + 47 (<code>.bin</code>)</td></tr>
    </tbody>
    </table></div>
"@
        }
        "Lego_Star_Wars" {
            $customOverviewHtml = @"
    <h2>Inspected LEGO Star Wars Releases &amp; Archive Summary</h2>
    <div class="table-scroll"><table class="format-counts">
    <thead><tr><th>Title &amp; Platform</th><th>Source Image / Build</th><th>Archive / Container Layout</th><th>Verified File Count &amp; Highlights</th></tr></thead>
    <tbody>
    <tr><td><strong>LSW1 (2005) — PS2 USA v2.00</strong></td><td><code>SLUS_210.83</code> (<code>1,869,316,096</code> B ISO)</td><td><code>GAME.DAT</code> (<code>615,527,160</code> B, TOC <code>v-1</code> at <code>615,355,768</code>)</td><td><code>4,223</code> files (4,564 nodes, <code>RemainderBytes = 0</code>); <code>.gsc</code>, <code>.ghg</code>, <code>.cut</code> compressed with <code>RNC\x02</code>.</td></tr>
    <tr><td><strong>LSW1 (2005) — Original Xbox USA</strong></td><td><code>default.xbe</code> (<code>1,607,401,472</code> B XISO)</td><td>Unpacked directly in XDVDFS (no <code>.DAT</code>)</td><td><code>4,721</code> files across 42 extensions (<code>.ani: 973</code>, <code>.txt: 874</code>, <code>.bsa: 679</code>, <code>.scp: 500</code>, <code>.nux: 259</code>, <code>.cut: 184</code>, <code>.hgx: 163</code>).</td></tr>
    <tr><td><strong>LSW1 (2005) — GameCube USA/EU</strong></td><td><code>G5LEWR</code> / <code>G5LPWR</code> (<code>.rvz</code>)</td><td><code>RVZ\x01</code> compressed GameCube discs</td><td>GameCube <code>.nup</code> / <code>.hgp</code> / <code>.sfd</code> layout.</td></tr>
    <tr><td><strong>LSW2 (2006) — PS2 USA/EU/Demo/JP</strong></td><td><code>SLUS_214.09</code>, <code>SLES_542.21</code>, <code>SLED_543.15</code>, <code>SLPM_665.72</code></td><td><code>GAME.DAT</code> (<code>1,739,697,816</code> B, TOC <code>v-1</code> at <code>1,739,348,648</code>)</td><td><code>8,600</code> files across 48 extensions (<code>.an3: 2440</code>, <code>.bsa: 1999</code>, <code>.vag: 1037</code>, <code>.txt: 628</code>, <code>.scp: 525</code>, <code>.gsc: 448</code>, <code>.ghg: 255</code>, <code>.cu2: 76</code>).</td></tr>
    <tr><td><strong>LSW2 (2006) — Original Xbox USA/EU</strong></td><td><code>default.xbe</code> (<code>1,700,003,840</code> B XISO)</td><td>Unpacked directly in XDVDFS</td><td><code>8,329</code> files across 60 extensions (<code>.nx2: 474</code>, <code>.hx2: 261</code>, <code>.htm: 334</code> Perforce export logs, <code>.fpk: 137</code>).</td></tr>
    <tr><td><strong>LSW2 (2006) — Xbox 360 USA + DLC</strong></td><td><code>default.xex</code> (<code>7,834,892,288</code> B XGD2 ISO) + <code>LIVE</code> DLC</td><td>Unpacked in XDVDFS at <code>0x0FD90000</code> + <code>360_exlist</code></td><td><code>3,973</code> files across 58 extensions (<code>.gsc: 500</code>, <code>.ghg: 254</code>, <code>.ctr: 179</code>, <code>.xma: 149</code>, <code>.cc2: 76</code>, <code>.ca3: 26</code>) + STFS DLC (<code>USEOLDCHARACTERS.TXT</code>).</td></tr>
    <tr><td><strong>LSW2 (2006) — Windows PC</strong></td><td><code>LEGOSTA2.EXE</code> (<code>616,714,240</code> B ISO)</td><td><code>Data2.cab</code> -> <code>GAME.DAT</code>, <code>PATCH.DAT</code>, <code>STARTUP.DAT</code></td><td><code>PE32</code> x86 (<code>2006-09-26</code>), PDB: <code>c:\projects\starwars\Release_2K\starwars_pc.pdb</code>.</td></tr>
    </tbody>
    </table></div>
"@
        }
        "Lego_Harry_Potter" {
            $customOverviewHtml = @"
    <h2>Inspected LEGO Harry Potter Releases &amp; Archive Summary</h2>
    <div class="table-scroll"><table class="format-counts">
    <thead><tr><th>Title &amp; Platform</th><th>Build / ID</th><th>Archives</th><th>Verified File Count &amp; Highlights</th></tr></thead>
    <tbody>
    <tr><td><strong>Years 1–4 (2010) — PS3 EU</strong></td><td><code>BLES00752</code> (v01.02 &amp; v03.01)</td><td><code>GAME.DAT</code> + <code>GAME1.DAT</code>..<code>GAME4.DAT</code></td><td><code>19,383</code> files (<code>PakDat v1.01</code> TOC <code>v-4</code>, <code>LZ2K</code>); v01.02 and v03.01 <code>GAME*.DAT</code> are 100% SHA-256 identical.</td></tr>
    <tr><td><strong>Years 1–4 (2010) — Xbox 360 + Demo</strong></td><td><code>0x575207E6</code></td><td><code>GAME.DAT</code> + <code>GAME1.DAT</code>..<code>GAME4.DAT</code></td><td><code>10,641</code> files; 99.6% structural parity with PS3 on <code>GAME1</code>–<code>GAME4</code>; Kiosk Demo <code>GAME.DAT</code> has <code>7,274</code> entries.</td></tr>
    <tr><td><strong>Years 5–7 (2011) — PS3 EU</strong></td><td><code>BLES01297</code></td><td><code>GAME0.DAT</code>..<code>GAME3.DAT</code></td><td><code>17,197</code> files (<code>PakDat v1.01</code> TOC <code>v-4</code>, <code>LZ2K</code>).</td></tr>
    <tr><td><strong>Years 5–7 (2011) — Xbox 360 + Demo</strong></td><td><code>0x57520812</code></td><td><code>GAME0.DAT</code>..<code>GAME3.DAT</code></td><td><code>14,729</code> files; Kiosk Demo <code>GAME0.DAT</code> + <code>GAME1.DAT</code> holds <code>2,906</code> entries.</td></tr>
    <tr><td><strong>Collection (2024) — PC Steam</strong></td><td><code>harry1.exe</code> / <code>harry2.exe</code> (AMD64)</td><td><code>harry1/1b.datwin</code>, <code>harry2/2b.datwin</code></td><td><code>41,389</code> entries across 4 <code>.datwin</code> volumes (TOC <code>v-1</code>, 24B entries with <code>0x12345678</code> canary and <code>LZHAM</code>) + <code>launcher.pkiwin</code>/<code>.pkdwin</code>.</td></tr>
    </tbody>
    </table></div>
"@
        }
        "Lego_Batman" {
            $customOverviewHtml = @"
    <h2>Inspected LEGO Batman 2: DC Super Heroes (2012 Windows Steam) Summary</h2>
    <div class="table-scroll"><table class="format-counts">
    <thead><tr><th>Archive / File</th><th>Size (Bytes)</th><th>TOC Version &amp; Offset</th><th>Entries</th><th>Raw / LZ2K</th><th>Notes</th></tr></thead>
    <tbody>
    <tr><td><code>LEGOBatman2.exe</code></td><td><code>18,690,560</code></td><td><code>PE32</code> x86 (<code>2012-05-25</code>)</td><td>—</td><td>—</td><td>32-bit Windows executable with <code>LZ2K</code>, <code>StreamInfo</code>, and FMOD.</td></tr>
    <tr><td><code>GAME0.DAT</code></td><td><code>521,796,176</code></td><td><code>v-4</code> at <code>521,049,088</code></td><td><code>14,507</code></td><td><code>6,281</code> / <code>8,226</code></td><td>Core chars, stuff, gui, cutscenes, scripts (<code>100%</code> <code>TtPathHash</code> verified).</td></tr>
    <tr><td><code>GAME1.DAT</code></td><td><code>465,112,692</code></td><td><code>v-4</code> at <code>464,741,632</code></td><td><code>7,531</code></td><td><code>3,914</code> / <code>3,617</code></td><td>Story levels &amp; Gotham hub sectors.</td></tr>
    <tr><td><code>GAME2.DAT</code>..<code>GAME6.DAT</code></td><td><code>2,102,430,204</code></td><td><code>v-4</code> (<code>PakDat v1.01</code>)</td><td><code>5,443</code></td><td><code>2,980</code> / <code>2,463</code></td><td>Additional Gotham hub sectors, audio, and localized voice streams.</td></tr>
    <tr><td><code>ICONS_TEX.PAK</code></td><td><code>2,361,498</code></td><td><code>0x1234567A</code> (<code>.PAK</code>)</td><td><code>136</code></td><td>Raw DDS</td><td>136 icon DDS textures with verified additive <code>0x12345678</code> name checksums.</td></tr>
    <tr><td><code>FILETABLE.TXT</code></td><td><code>2,616,964</code></td><td>Plaintext Manifest</td><td><code>18,915</code> lines</td><td>—</td><td>Includes unreleased/platform paths (<code>__dlc1__</code>, <code>__dlc2__</code>, <code>wii\</code>).</td></tr>
    </tbody>
    </table></div>
"@
        }
        "Lego_Dimensions" {
            $customOverviewHtml = @"
    <h2>Inspected LEGO Dimensions (2015 PS3 EU <code>BLES02158</code> &amp; USA <code>BLUS31456</code> + 47 NFC Toy Tags)</h2>
    <div class="table-scroll"><table class="format-counts">
    <thead><tr><th>Volume Pair (<code>USRDIR/</code>)</th><th><code>.DAT</code> Size (Bytes)</th><th>TOC Version</th><th>Files</th><th>Raw / DFLT</th><th>Container Structure</th></tr></thead>
    <tbody>
    <tr><td><code>GAME.HDR</code> / <code>GAME.DAT</code></td><td><code>512,598,016</code></td><td><code>v-7</code></td><td><code>19,000</code></td><td><code>14,043</code> / <code>4,957</code></td><td><code>PakDat</code> + 12B non-seq <code>NameNodes</code> + <code>ROTV</code>×2 (`100%` <code>TtPathHash</code> match).</td></tr>
    <tr><td><code>GAME0.HDR</code>..<code>GAME5.HDR</code> / <code>.DAT</code></td><td><code>2,068,536,832</code></td><td><code>v-7</code></td><td><code>31,599</code></td><td><code>24,495</code> / <code>7,104</code></td><td>Root prefix <code>C:\projects\lego_dimensions\data</code>.</td></tr>
    <tr><td><code>INSTALL0_.HDR</code> / <code>.DAT</code></td><td><code>7,824,877,502</code></td><td><code>v-7</code> + <code>CMP2</code></td><td><code>30,906</code></td><td><code>24,132</code> / <code>6,774</code></td><td>Outer <code>CMP2CMP2CMP2CMP2</code> LZMA (<code>5D 00 00 00 02</code>) -> <code>8,365,672,188</code> B.</td></tr>
    <tr><td><code>INSTALL0_0.HDR</code> / <code>.DAT</code></td><td><code>7,908,009,327</code></td><td><code>v-7</code> + <code>CMP2</code></td><td><code>31,575</code></td><td><code>23,808</code> / <code>7,767</code></td><td>Outer <code>CMP2</code> LZMA -> <code>8,447,484,092</code> B.</td></tr>
    <tr><td><code>INSTALL0_1.HDR</code> / <code>.DAT</code></td><td><code>2,616,959,233</code></td><td><code>v-7</code> + <code>CMP2</code></td><td><code>11,636</code></td><td><code>9,887</code> / <code>1,749</code></td><td>Outer <code>CMP2</code> LZMA -> <code>2,765,025,228</code> B.</td></tr>
    <tr><td><strong>Total (All 10 Volumes)</strong></td><td><strong>20,930,980,910</strong></td><td><strong>TOC v-7</strong></td><td><strong>124,716</strong></td><td><strong>96,365 / 28,351</strong></td><td>Plus 47 NTAG213 180-byte NFC Toy Tag dumps in <code>D:\PS3\Lego Dimensions\chars\</code>.</td></tr>
    </tbody>
    </table></div>
"@
        }
        default {
            $customOverviewHtml = @"
    <h2>Project Scope &amp; Shared TT Engine Architecture</h2>
    <p>This documentation module covers <strong>$ProjectTitle</strong> within the Traveller's Tales (TT Games) reverse-engineering suite. Refer to the cross-game format specifications in <code>Formats/</code> and the unified virtual directory hierarchy below.</p>
"@
        }
    }

    # --- Files/index.html ---
    $filesOverview = @"
<h1>$ProjectTitle — Game Files &amp; Combined Directory Architecture</h1>
<aside class="source-notice"><p><strong>Architecture Concept:</strong> Unified representation of Source and Extracted Archive Data</p></aside>
<section class="doc-overview">
    <h2>The Combined Virtual Filesystem Concept</h2>
    <p>In retail distributions of TT Games titles, game assets are packed inside monolithic or multi-slice archive volumes (<code>GAME*.DAT</code>, <code>INSTALL*.DAT</code>, or <code>*.datwin</code>) or stored directly in the Xbox XDVDFS partition (in <em>LSW1</em> and <em>LSW2</em> Xbox/Xbox 360). This documentation presents the game's file structure using a <strong>combined virtual filesystem</strong> where archive packages are transparently replaced by their extracted directory trees.</p>
$customOverviewHtml
    <h2>Core Subsystem Directory Tree</h2>
    <div class="table-scroll"><table class="format-counts">
    <thead><tr><th>Virtual Directory</th><th>Subsystem Role</th><th>Primary File Types</th></tr></thead>
    <tbody>
    <tr><td><code>audio/</code> / <code>IOP/</code></td><td>Voice streams, soundtrack music, sound effect dictionaries, and audio bus curves.</td><td><code>.msf</code>, <code>.xma</code>, <code>.ogg</code>, <code>.vag</code>, <code>.wavx</code>, <code>.cfg</code>, <code>.sfx</code></td></tr>
    <tr><td><code>chars/</code></td><td>Minifigures, creatures, vehicles, character definitions, and animations.</td><td><code>.ghg</code>/<code>.hgx</code>/<code>.hx2</code>, <code>.cd</code>, <code>.cpd</code>, <code>.as</code>, <code>.an3</code>/<code>.ani</code>/<code>.anm</code>, <code>.bsa</code>, <code>.tex</code></td></tr>
    <tr><td><code>levels/</code></td><td>Story chapters, hub worlds, collision octrees, runtime lights, and level scripts.</td><td><code>.gsc</code>/<code>.nux</code>/<code>.nx2</code>, <code>.ter</code>/<code>.ctr</code>, <code>.rtl</code>, <code>.dno</code>, <code>.led</code>, <code>.giz</code>, <code>.git</code>, <code>.scp</code>, <code>.sf</code>, <code>.lua</code></td></tr>
    <tr><td><code>cut/</code></td><td>In-engine cutscene choreography, actor staging, camera switching, and subtitle timings.</td><td><code>.cut</code>, <code>.cu2</code>/<code>.cc2</code>, <code>.cu3</code>, <code>.sub</code></td></tr>
    <tr><td><code>gui/</code> / <code>framework-data/</code></td><td>Menu pages, pause screens, HUD stud counters, button prompts, and font sheets.</td><td><code>.ft2</code>, <code>.gip</code>, <code>.gix</code>, <code>.gil</code>, <code>.tex</code></td></tr>
    <tr><td><code>stuff/</code></td><td>Global configuration, gameplay constants, particle templates, splines, and localization tables.</td><td><code>text.csv</code>, <code>game.txt</code>, <code>levels.txt</code>, <code>.ptl</code>, <code>.par</code>, <code>.spl</code></td></tr>
    <tr><td><code>scripts/</code> / <code>ai/</code></td><td>Global mission scripting, AI navigation graphs, and Lua bytecode packages.</td><td><code>.ai2</code>, <code>.aib</code>, <code>.scp</code>, <code>.sf</code>, <code>.lua</code>, <code>ai.pak</code></td></tr>
    <tr><td><code>movies/</code> / <code>FMV/</code></td><td>Pre-rendered FMVs, company logos, attract mode gameplay reels, and end credits.</td><td><code>.fmv</code>, <code>.bik</code>, <code>.pam</code>, <code>.pss</code>, <code>.xmv</code></td></tr>
    </tbody>
    </table></div>
</section>
<h2>Platform Implementations</h2>
<ul>
    <li><a href="../index.html#Files-PS3" target="_parent">PlayStation (PS2 &amp; PS3) Combined Filesystem</a></li>
    <li><a href="../index.html#Files-Xbox360" target="_parent">Xbox (Original Xbox &amp; Xbox 360) Combined Filesystem</a></li>
    <li><a href="../index.html#Files-PC" target="_parent">PC (Windows Retail &amp; Steam Remaster) Combined Filesystem</a></li>
</ul>
"@
    Write-HtmlFile (Join-Path $FilesDir "index.html") (Get-HtmlPage "$ProjectTitle - Combined Files Architecture" "<a href='../index.html#home' target='_parent'>Documentation</a><span>/</span>Files" $filesOverview "../style/main.css")

    # --- Files/PS3/index.html ---
    $Ps3Dir = Join-Path $FilesDir "PS3"
    Ensure-Dir $Ps3Dir
    $ps3Content = @"
<h1>PlayStation (PS2 &amp; PS3): Combined File &amp; Directory Layout</h1>
<aside class="source-notice"><p><strong>Platforms:</strong> Sony PlayStation 2 (ISO-9660 DVD-ROM) &amp; PlayStation 3 (BLES/BLUS Blu-ray Disc)</p></aside>
<section class="doc-overview">
    <h2>1. PlayStation 2 Disc Layout (Era 1–2: LSW1 &amp; LSW2)</h2>
    <ul>
        <li><code>SYSTEM.CNF</code> &amp; <code>SLUS_210.83</code> / <code>SLUS_214.09</code>: Boot configuration and MIPS R5900 ELF executable.</li>
        <li><code>GAME.DAT</code>: Single archive with TOC <code>Version = -1</code> (`4,223` files in <em>LSW1</em> with <code>RNC\x02</code> compressed scenes/models; `8,600` files in <em>LSW2</em>).</li>
        <li><code>IOP/MODULES/</code> &amp; <code>FMV/</code>: IOP hardware drivers (<code>.IRX</code>), streaming SPU2 ADPCM audio banks (<code>.MIB</code>/<code>.MIH</code>), and MPEG-2 <code>.PSS</code> movies.</li>
    </ul>
    <h2>2. PlayStation 3 Blu-ray Layout (Era 3–4: HP 1–4, HP 5–7, LEGO Dimensions)</h2>
    <ul>
        <li><code>PS3_DISC.SFB</code> &amp; <code>PS3_GAME/PARAM.SFO</code>: Blu-ray disc metadata and Title ID configuration.</li>
        <li><code>PS3_GAME/USRDIR/EBOOT.BIN</code>: Signed 64-bit Cell PPU SELF executable.</li>
        <li><code>PS3_GAME/USRDIR/GAME*.DAT</code> (and <code>.HDR</code> + <code>INSTALL0_*.DAT</code> in <em>Dimensions</em>): Multi-slice archives (`57-byte` <code>PakDat v1.01</code> TOC <code>v-4</code> with <code>LZ2K</code> in <em>HP</em>; TOC <code>v-7</code> with <code>DFLT</code> and <code>CMP2</code> LZMA in <em>Dimensions</em>).</li>
    </ul>
    <h2>Combined USRDIR Hierarchy</h2>
    <div class="file-list-container">
        <h3>Directory Structure (Combined)</h3>
        <ul class="file-list-scroll">
            <li><code>USRDIR/EBOOT.BIN</code> (Primary 64-bit PPU executable)</li>
            <li><code>USRDIR/audio/</code> (ATRAC3plus <code>.msf</code> music &amp; cutscene tracks; <code>level_sfx</code> banks)</li>
            <li><code>USRDIR/chars/</code> (character <code>.cd</code> definitions, <code>.ghg</code> models, <code>.an3</code>/<code>.anm</code> animations)</li>
            <li><code>USRDIR/cut/</code> (in-game cutscenes: camera choreography <code>*_ps3.cu2</code> / <code>.cu3</code>)</li>
            <li><code>USRDIR/framework-data/</code> &amp; <code>gui/</code> (core engine GUI definitions, <code>.ft2</code> font atlases)</li>
            <li><code>USRDIR/levels/</code> (story levels and hubs: <code>_nxg.gsc</code> geometry, <code>.dno</code> objects, <code>.led</code> entities, <code>.ter</code> collision)</li>
            <li><code>USRDIR/movies/</code> (high-definition <code>.fmv</code> / <code>.pam</code> Bink cutscenes)</li>
            <li><code>USRDIR/shaders/</code> (compiled RSX <code>.ps3_shaders</code> programs)</li>
            <li><code>USRDIR/stuff/</code> (<code>game.txt</code> parameters, <code>text.csv</code> multilingual dialogue)</li>
        </ul>
    </div>
</section>
"@
    Write-HtmlFile (Join-Path $Ps3Dir "index.html") (Get-HtmlPage "PlayStation Combined Filesystem" "<a href='../../index.html#home' target='_parent'>Documentation</a><span>/</span><a href='../../index.html#Files' target='_parent'>Files</a><span>/</span>PS3" $ps3Content "../../style/main.css")

    # --- Files/Xbox_360/index.html ---
    $X360Dir = Join-Path $FilesDir "Xbox_360"
    Ensure-Dir $X360Dir
    $x360Content = @"
<h1>Xbox &amp; Xbox 360: Combined File &amp; Directory Layout</h1>
<aside class="source-notice"><p><strong>Platforms:</strong> Original Xbox (XISO XDVDFS at <code>0x10000</code>) &amp; Xbox 360 (XGD2 XDVDFS at <code>0x0FD90000</code> + STFS)</p></aside>
<section class="doc-overview">
    <h2>1. Original Xbox &amp; Early Xbox 360 Loose XDVDFS Layout (LSW1 &amp; LSW2)</h2>
    <p>Uniquely, <em>LEGO Star Wars</em> (2005 Xbox) and <em>LEGO Star Wars II</em> (2006 Xbox &amp; Xbox 360) do <strong>not</strong> pack their assets into <code>GAME.DAT</code>. All files sit directly inside the XDVDFS partition:</p>
    <ul>
        <li><strong>LSW1 Xbox (`4,721` loose files):</strong> <code>default.xbe</code>, <code>chars/</code> (<code>.hgx</code>, <code>.ani</code>, <code>.bsa</code>), <code>levels/</code> (<code>.nux</code>, <code>.ter</code>, <code>.rtl</code>, <code>.ai2</code>), <code>cut/</code> (<code>.cut</code>), <code>sound/</code> (<code>.wavx</code>).</li>
        <li><strong>LSW2 Xbox (`8,329` loose files):</strong> <code>default.xbe</code>, <code>.nx2</code> scenes, <code>.hx2</code> models + <code>.hx2.htm</code> Perforce export logs, <code>.an3</code> animations, <code>.fpk</code> packages.</li>
        <li><strong>LSW2 Xbox 360 (`3,973` loose files + `LIVE` DLC):</strong> <code>default.xex</code>, <code>360_exlist</code> extension remapping table (<code>ter -> ctr</code>, <code>cu2 -> cc2</code>, <code>an3 -> ca3</code>, <code>vag -> xma</code>), and 57 KB STFS DLC package enabling <em>LSW1</em> save characters.</li>
    </ul>
    <h2>2. Xbox 360 PakDat v1.01 Layout (Era 3–4: HP 1–4, HP 5–7, Batman 2)</h2>
    <ul>
        <li><code>Default.xex</code>: XEX2 Xenon executable container (Title IDs <code>0x575207E6</code>, <code>0x57520812</code>, <code>0x57520817</code>).</li>
        <li><code>GAME*.DAT</code>: 57-byte <code>PakDat v1.01</code> archives storing big-endian PowerPC assets and XMA2 (<code>.xma</code>) audio streams.</li>
    </ul>
</section>
"@
    Write-HtmlFile (Join-Path $X360Dir "index.html") (Get-HtmlPage "Xbox & Xbox 360 Combined Filesystem" "<a href='../../index.html#home' target='_parent'>Documentation</a><span>/</span><a href='../../index.html#Files' target='_parent'>Files</a><span>/</span>Xbox_360" $x360Content "../../style/main.css")

    # --- Files/PC/index.html ---
    $PcDir = Join-Path $FilesDir "PC"
    Ensure-Dir $PcDir
    $pcContent = @"
<h1>PC (Windows Retail &amp; Steam): Combined File &amp; Directory Layout</h1>
<aside class="source-notice"><p><strong>Platform:</strong> Microsoft Windows (32-bit <code>PE32</code> Retail/Steam &amp; 64-bit <code>PE32+</code> AMD64 Remaster)</p></aside>
<section class="doc-overview">
    <h2>1. Classic &amp; NXG 32-bit Windows Layout (LSW2 PC &amp; LEGO Batman 2 Steam)</h2>
    <ul>
        <li><strong>LEGO Star Wars II (2006 PC ISO):</strong> <code>LEGOSTA2.EXE</code> (7.49 MB, PDB <code>c:\projects\starwars\Release_2K\starwars_pc.pdb</code>) mounting <code>GAME.DAT</code>, <code>PATCH.DAT</code>, and <code>STARTUP.DAT</code>.</li>
        <li><strong>LEGO Batman 2 (2012 Steam):</strong> <code>LEGOBatman2.exe</code> (18.69 MB) mounting <code>GAME0.DAT</code>..<code>GAME6.DAT</code> (`27,481` entries, <code>PakDat v1.01</code> TOC <code>v-4</code>), alongside loose <code>FILETABLE.TXT</code> (`18,915` lines), <code>TRACKEDFILELIST360.TXT</code>, <code>ICONS_TEX.PAK</code> (`136` files), and <code>Audio/</code> Ogg/WAV streams.</li>
    </ul>
    <h2>2. 64-bit Direct3D 11 Remaster Layout (2024 LEGO Harry Potter Collection)</h2>
    <ul>
        <li><code>harry1.exe</code> / <code>harry2.exe</code>: 64-bit AMD64 executables with <code>shaderblob_pc.blob</code> (`13.86 MB`) and <code>launcher.pkiwin</code>/<code>.pkdwin</code>.</li>
        <li><code>harry1.datwin</code>, <code>harry1b.datwin</code>, <code>harry2.datwin</code>, <code>harry2b.datwin</code>: 64-bit archives (`41,389` total files, TOC <code>v-1</code> with 24-byte entries, <code>0x12345678</code> canary, and <code>LZHAM</code> compression).</li>
    </ul>
</section>
"@
    Write-HtmlFile (Join-Path $PcDir "index.html") (Get-HtmlPage "PC Combined Filesystem" "<a href='../../index.html#home' target='_parent'>Documentation</a><span>/</span><a href='../../index.html#Files' target='_parent'>Files</a><span>/</span>PC" $pcContent "../../style/main.css")
}

Write-Host "Files section generators loaded." -ForegroundColor Green

# --------------------------------------------------------------------------------------------------
# SHELL & DOCS GUIDE GENERATOR
# --------------------------------------------------------------------------------------------------

function Build-DocsProject([string]$DocsDir, [string]$ProjectKey, [string]$ProjectTitle, [string]$ProjectSubtitle, [string]$BackUpLink) {
    Ensure-Dir $DocsDir

    # 1. Write CSS
    Ensure-Dir (Join-Path $DocsDir "style")
    Write-HtmlFile (Join-Path $DocsDir "style\main.css") $CssContent

    # 2. Build Formats Tree (xex, bin, exe, dat + datFormats)
    Build-RootFormats -DocsDir $DocsDir -ProjectTitle $ProjectTitle -BackUpLink $BackUpLink

    # 3. Build Files Tree (PS3, Xbox 360, PC)
    Build-FilesSection -DocsDir $DocsDir -ProjectKey $ProjectKey -ProjectTitle $ProjectTitle -BackUpLink $BackUpLink

    # 4. Build docs.html (Documentation Guide)
    $docsGuideHtml = @"
<h1>Documentation Guide &amp; Format Analysis Conventions</h1>
<aside class="source-notice"><p><strong>Project:</strong> $ProjectTitle Reversing &amp; Format Documentation</p></aside>
<section class="doc-overview">
    <h2>Project Mission &amp; Architectural Principles</h2>
    <p>This technical reference documents binary file formats, proprietary archive packaging, compression algorithms, and filesystem structures for <strong>$ProjectTitle</strong> within the RemakeEngine ecosystem. It follows the reverse-engineering documentation standards established across the LEGO and Simpsons documentation repositories.</p>
    <h2>Two Complementary Documentation Trees</h2>
    <ol>
        <li><strong>Format Analysis (<code>Formats/</code>):</strong> Follows binary format origins: root executable and container formats (<code>.xex</code>/<code>.xbe</code>, <code>.bin</code>/<code>ELF</code>, <code>.exe</code>, <code>.dat</code>/<code>.hdr</code>/<code>.datwin</code>) followed by formats extracted from within archives (<code>datFormats/</code>), explicitly noting which formats are universal across TT Games and which are specific to certain eras or titles.</li>
        <li><strong>Game Files &amp; Asset Use (<code>Files/</code>):</strong> Documents directory hierarchies, cross-game format censuses, sound banks, character definitions, mission scripts, and in-game usage through a <em>combined virtual filesystem</em>.</li>
    </ol>
</section>
"@
    Write-HtmlFile (Join-Path $DocsDir "docs.html") (Get-HtmlPage "$ProjectTitle - Documentation Guide" "<a href='index.html#home' target='_parent'>Documentation</a><span>/</span>Guide" $docsGuideHtml "style/main.css")

    # 5. Build index.html (Interactive Shell & Single-Page Application Router)
    $formatEntriesHtml = ""
    $formatMapLeavesHtml = ""
    $iframesHtml = ""

    # Root Formats in Coverage List
    $rootFormatList = @(
        @{ Route = "Formats-dat"; Ext = ".DAT / .HDR / CMP2 / .datwin"; Status = "TOC v-1..v-12 & extraction verified"; Color = "green"; Detail = "TOC v-1 (LSW1/LSW2), 57B PakDat v1.01 v-4 (HP/Batman 2), v-7 .HDR + CMP2 LZMA (Dimensions), and .datwin LZHAM (PC) verified." },
        @{ Route = "Formats-bin"; Ext = ".BIN / PS2 ELF (PlayStation)"; Status = "PS2 MIPS ELF & PS3 SELF PPU analyzed"; Color = "blue"; Detail = "SLUS_210.83, SLUS_214.09 (PS2) and EBOOT.BIN (PS3 HP 1-4, HP 5-7, Dimensions) analyzed." },
        @{ Route = "Formats-xex"; Ext = ".xex / .xbe (Xbox & Xbox 360)"; Status = "XBEH & XEX2 containers analyzed"; Color = "blue"; Detail = "LSW1/LSW2 default.xbe, LSW2 default.xex (360_exlist), and HP 1-4/5-7 Default.xex decrypted." },
        @{ Route = "Formats-exe"; Ext = ".exe (Windows PE32 & PE32+)"; Status = "x86 & AMD64 binaries analyzed"; Color = "green"; Detail = "LEGOSTA2.EXE (2006), LEGOBatman2.exe (2012), and harry1.exe/harry2.exe (2024) analyzed." }
    )

    foreach ($rf in $rootFormatList) {
        $formatEntriesHtml += @"
        <li class="format-coverage-item" data-format-route="$($rf.Route)" data-coverage-status="$($rf.Color)">
            <span class="coverage-icon coverage-$($rf.Color)" role="img" aria-label="$($rf.Status)"></span>
            <div><strong><a href="#$($rf.Route)">$($rf.Ext)</a></strong> <span class="coverage-status">$($rf.Status)</span><span class="coverage-detail">$($rf.Detail)</span></div>
        </li>
"@
        $formatMapLeavesHtml += "<li><a class='format-status-link' href='#$($rf.Route)' data-coverage-status='$($rf.Color)'><span class='coverage-icon coverage-$($rf.Color)'></span><span>$($rf.Ext)</span></a></li>`n"
    }

    # datFormats in Coverage List
    foreach ($k in $DatFormats.Keys) {
        $fmt = $DatFormats[$k]
        $color = "green"
        $status = $fmt.Scope
        $detail = $fmt.Desc
        $route = "Formats-dat-$k"

        $formatEntriesHtml += @"
        <li class="format-coverage-item" data-format-route="$route" data-coverage-status="$color">
            <span class="coverage-icon coverage-$color" role="img" aria-label="$status"></span>
            <div><strong><a href="#$route">$($fmt.Ext)</a></strong> <span class="coverage-status">$status</span><span class="coverage-detail">$detail</span></div>
        </li>
"@
        $formatMapLeavesHtml += "<li><a class='format-status-link' href='#$route' data-coverage-status='$color'><span class='coverage-icon coverage-$color'></span><span>$($fmt.Ext)</span></a></li>`n"
        $iframesHtml += "<iframe id='$route' class='page' src='./Formats/dat/datFormats/$k.html' loading='lazy' title='$($fmt.Name)'></iframe>`n"
    }

    $indexHtml = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>$ProjectTitle - Reversing Documentation</title>
    <link rel="stylesheet" href="style/main.css">
    <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body>
    <nav class="topbar">
        <a class="brand" href="#home">$ProjectTitle Docs</a>
        <div class="topbar-links">
            <a href="#Files">Overview &amp; Census</a>
            <a href="#Files-PS3">PlayStation</a>
            <a href="#Files-Xbox360">Xbox</a>
            <a href="#Files-PC">PC</a>
            <a href="javascript:history.back()">Back</a>
            <a id="up-link" href="#home">Up</a>
        </div>
    </nav>
    <main class="pages">
        <section class="page home-page home-layout" id="home">
            <section class="format-coverage" aria-labelledby="format-coverage-title">
                <div class="format-coverage-heading">
                    <h1 id="format-coverage-title">${ProjectTitle} - Pipeline Format Coverage</h1>
                    <p>$ProjectSubtitle</p>
                </div>
                <p class="coverage-summary"><strong>$($rootFormatList.Count + $DatFormats.Count) tracked format families</strong> · Cross-generation coverage from Nu2 (2005) through NXG, DX11, and 64-bit Remasters (2024).</p>
                <ul class="format-coverage-legend" id="conversion-status-legend">
                    <li><span class="coverage-icon coverage-green"></span><strong>Green</strong> Usable specification / verified across archives</li>
                    <li><span class="coverage-icon coverage-yellow"></span><strong>Yellow</strong> Partial implementation / validation pending</li>
                    <li><span class="coverage-icon coverage-blue"></span><strong>Blue</strong> Executable analysis / layout verified</li>
                    <li><span class="coverage-icon coverage-grey"></span><strong>Grey</strong> Platform support unverified</li>
                </ul>
                <ul class="format-coverage-list">
                    $formatEntriesHtml
                </ul>
                <p><a href="#docs-guide">Documentation guide</a> · <a href="#Files">Combined Filesystem &amp; Format Census</a></p>
            </section>

            <nav class="documentation-tree" aria-labelledby="documentation-tree-title">
                <div class="documentation-tree-heading">
                    <h2 id="documentation-tree-title">Documentation Map</h2>
                    <p>Select a format or directory branch to inspect byte layouts, cross-game scope, and evidence.</p>
                </div>
                <ul class="documentation-tree-root">
                    <li class="documentation-tree-section documentation-tree-section-game">
                        <a class="documentation-tree-root-link" href="#Files">
                            <span class="documentation-tree-kicker">Directory Trees &amp; Census</span>
                            <span class="documentation-tree-title">Combined Filesystem</span>
                        </a>
                        <ul class="documentation-tree-branch">
                            <li><a class="documentation-tree-group-link" href="#Files-PS3">PlayStation (PS2 &amp; PS3)</a></li>
                            <li><a class="documentation-tree-group-link" href="#Files-Xbox360">Xbox (Original &amp; Xbox 360)</a></li>
                            <li><a class="documentation-tree-group-link" href="#Files-PC">PC (Windows Retail &amp; Steam)</a></li>
                        </ul>
                    </li>
                    <li class="documentation-tree-section documentation-tree-section-formats">
                        <a class="documentation-tree-root-link" href="#Formats-dat">
                            <span class="documentation-tree-kicker">Reverse Engineering</span>
                            <span class="documentation-tree-title">File Formats</span>
                        </a>
                        <ul class="documentation-tree-branch">
                            <li>
                                <span class="documentation-tree-group-label">Core Formats &amp; Archives</span>
                                <ul class="documentation-tree-leaves">
                                    $formatMapLeavesHtml
                                </ul>
                            </li>
                        </ul>
                    </li>
                </ul>
            </nav>
        </section>

        <!-- Root Format Iframes -->
        <iframe id="Formats-xex" class="page" src="./Formats/xex/index.html" loading="lazy" title="Xbox & Xbox 360 Executables"></iframe>
        <iframe id="Formats-bin" class="page" src="./Formats/bin/index.html" loading="lazy" title="PlayStation Executables"></iframe>
        <iframe id="Formats-exe" class="page" src="./Formats/exe/index.html" loading="lazy" title="PC Windows Executables"></iframe>
        <iframe id="Formats-dat" class="page" src="./Formats/dat/dat.html" loading="lazy" title="TT Archive Formats (.DAT)"></iframe>

        <!-- datFormats Extracted Format Iframes -->
        $iframesHtml

        <!-- Files Section Iframes -->
        <iframe id="Files" class="page" src="./Files/index.html" loading="lazy" title="Combined Filesystem Overview"></iframe>
        <iframe id="Files-PS3" class="page" src="./Files/PS3/index.html" loading="lazy" title="PlayStation Combined Filesystem"></iframe>
        <iframe id="Files-Xbox360" class="page" src="./Files/Xbox_360/index.html" loading="lazy" title="Xbox Combined Filesystem"></iframe>
        <iframe id="Files-PC" class="page" src="./Files/PC/index.html" loading="lazy" title="PC Combined Filesystem"></iframe>

        <!-- Documentation Guide Iframe -->
        <iframe id="docs-guide" class="page" src="./docs.html" loading="lazy" title="Documentation Guide"></iframe>
    </main>

    <script>
        (function() {
            var upLink = document.getElementById("up-link");
            function getCurrentId() {
                var hash = window.location.hash || "";
                return hash.replace(/^#/, "") || "";
            }
            function updateUpLink() {
                var currentId = getCurrentId();
                if (!currentId || currentId === "home") {
                    upLink.setAttribute("href", "#home");
                } else if (currentId.indexOf("Formats-dat-") === 0) {
                    upLink.setAttribute("href", "#Formats-dat");
                } else if (currentId.indexOf("Formats-") === 0) {
                    upLink.setAttribute("href", "#home");
                } else if (currentId.indexOf("Files-") === 0) {
                    upLink.setAttribute("href", "#Files");
                } else {
                    upLink.setAttribute("href", "#home");
                }
            }
            window.addEventListener("hashchange", updateUpLink);
            updateUpLink();
        })();
    </script>
</body>
</html>
"@
    Write-HtmlFile (Join-Path $DocsDir "index.html") $indexHtml
    Write-Host "Docs project built: $DocsDir" -ForegroundColor Cyan
}

Write-Host "Shell and guide builders loaded." -ForegroundColor Green

# --------------------------------------------------------------------------------------------------
# MAIN EXECUTION DISPATCHER
# --------------------------------------------------------------------------------------------------

Write-Host "`n>>> 1. Building Developer Shared Docs Project: Travellers_Tales <<<" -ForegroundColor Yellow
$ttDocsDir = Join-Path $RootPath "reversing\docs\Travellers_Tales"
Build-DocsProject `
    -DocsDir $ttDocsDir `
    -ProjectKey "Travellers_Tales" `
    -ProjectTitle "Traveller's Tales (TT Games) Shared Architecture" `
    -ProjectSubtitle "Cross-title reverse engineering reference covering the Nu2 / NXG / DX11 / NTT Engine evolution (2005–2024), .DAT TOC versions -1 through -12, .HDR/CMP2/LZ2K/DFLT/LZHAM compression, and cross-game format census." `
    -BackUpLink "#home"

# Root developer index redirect
$devRootIndex = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>LEGO Reversing Documentation - Developer Hub</title>
    <link rel="stylesheet" href="Travellers_Tales/style/main.css">
</head>
<body class="doc-page">
    <h1>LEGO Games Reversing Documentation: Developer Hub</h1>
    <p>Select a developer reference project:</p>
    <ul>
        <li><a href="Travellers_Tales/index.html"><strong>Traveller's Tales (TT Games / TT Fusion)</strong></a> — Flagship developer of LEGO action-adventure video games since 2005 (Nu2, NXG, DX11, and NTT Engines; .DAT TOC v-1..v-12, PakDat, CMP2, datwin).</li>
    </ul>
</body>
</html>
"@
Write-HtmlFile (Join-Path $RootPath "reversing\docs\index.html") $devRootIndex

Write-Host "`n>>> 2. Building Submodule Game Docs Projects <<<" -ForegroundColor Yellow

$GameSubmodules = @(
    @{
        Dir = "Lego_Harry_Potter"
        Title = "LEGO Harry Potter"
        Subtitle = "Years 1-4 (2010), Years 5-7 (2011), and 2024 Collection Remaster (PS3, Xbox 360 Retail & Demos, Steam PC x64)."
    },
    @{
        Dir = "Lego_Batman"
        Title = "LEGO Batman"
        Subtitle = "LEGO Batman 1 (2008), LEGO Batman 2: DC Super Heroes (2012 WinSteam inspected: 27,481 files), LEGO Batman 3 (2014), and DC Super-Villains (2018)."
    },
    @{
        Dir = "Lego_Star_Wars"
        Title = "LEGO Star Wars"
        Subtitle = "The Video Game (2005 PS2/Xbox/GCN inspected), Original Trilogy (2006 PS2/Xbox/X360/PC inspected), Complete Saga, Clone Wars, TFA, and Skywalker Saga."
    },
    @{
        Dir = "Lego_Indiana_Jones"
        Title = "LEGO Indiana Jones"
        Subtitle = "The Original Adventures (2008 Classic Nu2) and The Adventure Continues (2009 Creator NXG Engine transition & dynamic split-screen)."
    },
    @{
        Dir = "Lego_Marvel_Super_Heroes"
        Title = "LEGO Marvel Super Heroes"
        Subtitle = "LEGO Marvel Super Heroes (2013 PakDat v1.02), LEGO Marvel's Avengers (2016), and LEGO Marvel Super Heroes 2 (2017 .CC40TAD)."
    },
    @{
        Dir = "Lego_Pirates_of_the_Caribbean"
        Title = "LEGO Pirates of the Caribbean"
        Subtitle = "The Video Game (2011 Builder NXG Engine, PakDat v1.01 TOC v-4, dynamic ocean simulation & buoyancy physics)."
    },
    @{
        Dir = "Lego_Dimensions"
        Title = "LEGO Dimensions"
        Subtitle = "Toys-to-Life (2015 PS3 EU & US inspected: 124,716 files across 10 .HDR/.DAT volumes, TOC v-7, CMP2 LZMA, and 47 NTAG213 NFC Toy Tag dumps)."
    },
    @{
        Dir = "Lego_Worlds"
        Title = "LEGO Worlds"
        Subtitle = "Procedural voxel terrain generation (2017 DX11 Engine), LDD .lxfml brick blueprint integration, and .CC40TAD streaming."
    }
)

foreach ($g in $GameSubmodules) {
    $gameDocsDir = Join-Path $RootPath "Games\$($g.Dir)\reversing\docs"
    Write-Host "Building docs for $($g.Title) at $gameDocsDir..." -ForegroundColor Cyan
    Build-DocsProject `
        -DocsDir $gameDocsDir `
        -ProjectKey $g.Dir `
        -ProjectTitle $g.Title `
        -ProjectSubtitle $g.Subtitle `
        -BackUpLink "#home"
}

Write-Host "`n>>> All Lego Documentation Projects Successfully Generated! <<<" -ForegroundColor Green
