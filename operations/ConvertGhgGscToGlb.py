"""Convert TT Games LEGO .ghg/.gsc 3D assets to glTF 2.0 (.glb) and sync to Godot.

Intended to run via Blender's bundled Python (e.g.
`blender.exe --background --factory-startup --python ConvertGhgGscToGlb.py -- ...`)
or any Python 3.10+ runtime. Uses file seeking for large NU20 and 02UN/HSEM
containers and hardlinks for raw 3D files so multi-gigabyte archives export in
seconds without duplicating multi-gigabyte raw payloads.
"""

from __future__ import annotations

import argparse
import datetime
import json
import math
import os
import re
import shutil
import struct
import sys
from pathlib import Path
from typing import Any

TYPE_SIZES: tuple[int, ...] = (0, 4, 8, 12, 16, 4, 8, 4, 4, 4, 4, 2)
MAX_MESHES_PER_MODEL = 512
MAX_VERTS_PER_PRIMITIVE = 250000
MAX_INDICES_PER_PRIMITIVE = 750000
MAX_HSEM_SCAN_BYTES = 512 * 1024
MAX_HSEM_PARSE_BYTES = 16 * 1024 * 1024
MAX_NU20_BUFFER_BYTES = 16 * 1024 * 1024
IGNORED_SUBDIRS = {
    "chunk-check",
    "sample-check",
    "format-comparison",
    "parser-checks",
    "container-research",
    "with-demo",
    "cross-reference",
}


class MeshPrimitive:
    """Single triangle primitive ready for glTF 2.0 packing."""

    __slots__ = ("positions", "normals", "uvs", "indices")

    def __init__(self) -> None:
        self.positions: list[float] = []
        self.normals: list[float] = []
        self.uvs: list[float] = []
        self.indices: list[int] = []


def half_to_float(h: int) -> float:
    """Decode IEEE 754 binary16 (uint16) to float."""
    s = (h >> 15) & 0x1
    e = (h >> 10) & 0x1F
    f = h & 0x3FF
    if e == 0:
        if f == 0:
            return -0.0 if s else 0.0
        return (-1.0 if s else 1.0) * math.ldexp(f / 1024.0, -14)
    if e == 31:
        return 0.0
    return (-1.0 if s else 1.0) * math.ldexp(1.0 + f / 1024.0, e - 15)


def hardlink_or_copy(src: Path, dst: Path, force: bool = False) -> bool:
    """Create a same-volume hardlink (or copy across volumes). Returns True if written."""
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.exists():
        if not force:
            return False
        dst.unlink()
    try:
        os.link(src, dst)
        return True
    except OSError:
        shutil.copy2(src, dst)
        return True


HSEM_POST_SIZES: tuple[int, ...] = (0, 4, 8, 12, 16, 4, 8, 4, 4, 4, 4, 2)


def accum_attr(
    attr_def: int,
    tp: int,
    off: int,
    state: dict[str, int],
    sequential_if_zero: bool = False,
) -> None:
    """Accumulate attribute descriptor offsets and maximum stride."""
    if tp <= 0 or tp >= len(HSEM_POST_SIZES):
        return
    sz = HSEM_POST_SIZES[tp]
    actual_off = state["stride"] if (sequential_if_zero and off == 0 and state["stride"] > 0) else off
    if attr_def == 0 and state["pos_type"] < 0:
        state["pos_type"] = tp
        state["pos_off"] = actual_off
    elif attr_def == 1 and state["norm_type"] < 0:
        state["norm_type"] = tp
        state["norm_off"] = actual_off
    elif attr_def == 5 and state["uv_type"] < 0:
        state["uv_type"] = tp
        state["uv_off"] = actual_off
    end = max(state["stride"] + sz if sequential_if_zero else 0, actual_off + sz)
    if end > state["stride"]:
        state["stride"] = end


def decode_vec3(buf: bytes, off: int, tp: int, little_endian: bool) -> tuple[float, float, float]:
    """Decode a 3-component position/vector attribute."""
    if tp in (3, 4):
        fmt = "<fff" if little_endian else ">fff"
        return struct.unpack_from(fmt, buf, off)
    if tp == 6:
        h0, h1, h2 = struct.unpack_from(">HHH", buf, off)
        return half_to_float(h0), half_to_float(h1), half_to_float(h2)
    if tp == 8:
        b0, b1, b2 = buf[off], buf[off + 1], buf[off + 2]
        return b0 / 127.5 - 1.0, b1 / 127.5 - 1.0, b2 / 127.5 - 1.0
    return 0.0, 0.0, 0.0


def decode_normal(buf: bytes, off: int, tp: int) -> tuple[float, float, float]:
    """Decode unsigned UByteN4 / Half / Float normal attribute."""
    if tp in (3, 4, 6):
        return decode_vec3(buf, off, tp, False)
    if tp in (7, 8, 9):
        b0, b1, b2 = buf[off], buf[off + 1], buf[off + 2]
        return b0 / 127.5 - 1.0, b1 / 127.5 - 1.0, b2 / 127.5 - 1.0
    return 0.0, 1.0, 0.0


def decode_vec2(buf: bytes, off: int, tp: int) -> tuple[float, float]:
    """Decode UV attribute."""
    if tp == 2:
        return struct.unpack_from(">ff", buf, off)
    if tp == 5:
        h0, h1 = struct.unpack_from(">HH", buf, off)
        return half_to_float(h0), half_to_float(h1)
    return 0.0, 0.0


def detect_little_endian_f32(buf: bytes, vb_start: int, num_verts: int, stride: int, pos_off: int, tp: int) -> bool:
    """Heuristically detect LE vs BE float3 positions."""
    if tp not in (3, 4):
        return False
    samples = min(num_verts, 16)
    be_bad = 0
    le_bad = 0
    for i in range(samples):
        o = vb_start + i * stride + pos_off
        if o + 12 > len(buf):
            break
        bx, by, bz = struct.unpack_from(">fff", buf, o)
        lx, ly, lz = struct.unpack_from("<fff", buf, o)
        for val, bad_is_le in (((bx, by, bz), False), ((lx, ly, lz), True)):
            bad = False
            for c in val:
                if not math.isfinite(c) or abs(c) > 10000.0:
                    bad = True
                    break
            if not bad:
                mag2 = val[0] * val[0] + val[1] * val[1] + val[2] * val[2]
                if 0.0 < mag2 < 1e-12:
                    bad = True
            if bad:
                if bad_is_le:
                    le_bad += 1
                else:
                    be_bad += 1
    return le_bad < be_bad


def decode_triangles(raw: list[int], vert_count: int, prim_type: int) -> list[int]:
    """Decode index buffer using explicit topology: 0=TriangleList, 1=TriangleStrip."""
    n = len(raw)
    if n < 3 or vert_count < 3:
        return []

    out: list[int] = []
    if prim_type == 1:
        for s in range(n - 2):
            a, b, c = raw[s], raw[s + 1], raw[s + 2]
            if 0 <= a < vert_count and 0 <= b < vert_count and 0 <= c < vert_count and a != b and b != c and a != c:
                if (s & 1) == 0:
                    out.extend((a, b, c))
                else:
                    out.extend((b, a, c))
                if len(out) >= MAX_INDICES_PER_PRIMITIVE:
                    break
    else:
        usable = n - (n % 3)
        for i in range(0, usable, 3):
            a, b, c = raw[i], raw[i + 1], raw[i + 2]
            if 0 <= a < vert_count and 0 <= b < vert_count and 0 <= c < vert_count and a != b and b != c and a != c:
                out.extend((a, b, c))
                if len(out) >= MAX_INDICES_PER_PRIMITIVE:
                    break
    return out


def _is_hsem_mesh_start(buf: bytes, pos: int, ver: int) -> bool:
    """Return True if `pos` is a valid NuRenderMesh header inside HSEM."""
    if pos + 24 > len(buf):
        return False
    w0, w1, w2, w3 = struct.unpack_from(">IIII", buf, pos)
    if 1 <= w0 <= 4:
        if 0xC0000000 <= w1 <= 0xC000FFFF and w2 == 1:
            return True
        if w1 == 1 and w2 in (1, 2, 32, 33, 34, 36, 0x100, 0x104) and 3 <= w3 <= 500000:
            if ver < 0x2E:
                return buf[pos + 16] in (2, 3, 4, 6) and buf[pos + 17] == 0
            if ver >= 0xA1:
                return buf[pos + 16 : pos + 20] == b"DXTV"
            na = struct.unpack_from(">I", buf, pos + 16)[0]
            return 1 <= na <= 16 and buf[pos + 20] == 0 and 1 <= buf[pos + 21] <= 11
    if ver >= 0x2E:
        if 0xC0000000 <= w0 <= 0xC000FFFF and w1 == 1 and (w2 == 0 or w2 < 0x100000):
            return True
        if w0 == 1 and w1 in (2, 32, 33, 34, 36, 0x100, 0x104) and 3 <= w2 <= 500000:
            if ver >= 0xA1:
                return buf[pos + 12 : pos + 16] == b"DXTV"
            return 1 <= w3 <= 16 and buf[pos + 16] == 0 and 1 <= buf[pos + 17] <= 11
    return False


def _has_explicit_hsem_vbc(buf: bytes, pos: int, ver: int) -> bool:
    """Return True when the NuRenderMesh record starts with an explicit vb_count word."""
    if ver < 0x2E:
        return True
    if pos + 20 > len(buf):
        return True
    w0, w1, w2, w3 = struct.unpack_from(">IIII", buf, pos)
    if 1 <= w0 <= 4:
        if 0xC0000000 <= w1 <= 0xC000FFFF and w2 == 1:
            return True
        if w1 == 1 and w2 in (1, 2, 32, 33, 34, 36, 0x100, 0x104) and 3 <= w3 <= 500000:
            if ver >= 0xA1:
                return buf[pos + 16 : pos + 20] == b"DXTV"
            na = struct.unpack_from(">I", buf, pos + 16)[0]
            if 1 <= na <= 16 and buf[pos + 20] == 0 and 1 <= buf[pos + 21] <= 11:
                return True
    return False


def _decode_vb_slice(
    buf: bytes,
    vb_pos: dict[str, Any],
    vb_attr: dict[str, Any] | None,
    vbase: int,
    vcnt: int,
) -> tuple[list[float], list[float], list[float]]:
    """Decode (positions, normals, uvs) for a sub-mesh slice vbase..vbase+vcnt."""
    nv_pos = vb_pos["nv"]
    if vcnt <= 0 or vbase < 0 or vbase + vcnt > nv_pos:
        return [], [], []

    keep_verts = min(vcnt, MAX_VERTS_PER_PRIMITIVE)
    st_pos = vb_pos["state"]
    stride_pos = vb_pos["stride"]
    p_pos = vb_pos["data_pos"]
    if st_pos["pos_type"] < 0:
        return [], [], []

    use_le = detect_little_endian_f32(
        buf,
        p_pos + vbase * stride_pos,
        keep_verts,
        stride_pos,
        st_pos["pos_off"],
        st_pos["pos_type"],
    )
    pos_off = st_pos["pos_off"]
    pos_tp = st_pos["pos_type"]

    positions: list[float] = []
    for i in range(keep_verts):
        vi = vbase + i
        x, y, z = decode_vec3(buf, p_pos + vi * stride_pos + pos_off, pos_tp, use_le)
        positions.append(x if math.isfinite(x) and abs(x) < 1e5 else 0.0)
        positions.append(y if math.isfinite(y) and abs(y) < 1e5 else 0.0)
        positions.append(z if math.isfinite(z) and abs(z) < 1e5 else 0.0)

    src_norm_vb = vb_attr if (vb_attr is not None and vb_attr["nv"] == nv_pos and vb_attr["state"]["norm_type"] >= 0) else vb_pos
    st_norm = src_norm_vb["state"]
    normals: list[float] = []
    if st_norm["norm_type"] >= 0:
        n_off = st_norm["norm_off"]
        n_tp = st_norm["norm_type"]
        n_stride = src_norm_vb["stride"]
        n_data = src_norm_vb["data_pos"]
        for i in range(keep_verts):
            vi = vbase + i
            nx, ny, nz = decode_normal(buf, n_data + vi * n_stride + n_off, n_tp)
            length = math.sqrt(nx * nx + ny * ny + nz * nz)
            if math.isfinite(length) and length > 1e-4:
                normals.extend((nx / length, ny / length, nz / length))
            else:
                normals.extend((0.0, 1.0, 0.0))

    src_uv_vb = vb_attr if (vb_attr is not None and vb_attr["nv"] == nv_pos and vb_attr["state"]["uv_type"] >= 0) else vb_pos
    st_uv = src_uv_vb["state"]
    uvs: list[float] = []
    if st_uv["uv_type"] >= 0:
        u_off = st_uv["uv_off"]
        u_tp = st_uv["uv_type"]
        u_stride = src_uv_vb["stride"]
        u_data = src_uv_vb["data_pos"]
        for i in range(keep_verts):
            vi = vbase + i
            u, v = decode_vec2(buf, u_data + vi * u_stride + u_off, u_tp)
            uvs.append(u if math.isfinite(u) and abs(u) < 1e4 else 0.0)
            uvs.append(v if math.isfinite(v) and abs(v) < 1e4 else 0.0)

    return positions, normals, uvs


def _inv_rigid_mat4(m: tuple[float, ...]) -> tuple[list[float], list[float]]:
    """Compute inverse of a row-vector rigid-body 4x4 matrix m[0..15] -> (R_inv_3x3, t_inv_3)."""
    r00, r01, r02 = m[0], m[1], m[2]
    r10, r11, r12 = m[4], m[5], m[6]
    r20, r21, r22 = m[8], m[9], m[10]
    px, py, pz = m[12], m[13], m[14]
    # R_inv = transpose(R)
    r_inv = [r00, r10, r20, r01, r11, r21, r02, r12, r22]
    # t_inv = -pos * R_inv
    tx = -(px * r00 + py * r01 + pz * r02)
    ty = -(px * r10 + py * r11 + pz * r12)
    tz = -(px * r20 + py * r21 + pz * r22)
    return r_inv, [tx, ty, tz]


def _should_skip_nu20_layer(name: str) -> bool:
    """Skip lower LODs and dismemberment breakup layers in NU20 character models."""
    low = name.lower()
    if any(tok in low for tok in ("breakup", "medium", "medres", "_med", "low", "lores", "verylo", "_vlo", "_lo", "c3po")):
        return True
    if re.search(r"(^|_)tt[234](_|$)", low):
        return True
    return False


def _nu20_bbox_key(positions: list[float], vcnt: int, tri_cnt: int) -> tuple[Any, ...]:
    """Quantized bounding-box signature to deduplicate overlapping character variants."""
    xs = positions[0::3]
    ys = positions[1::3]
    zs = positions[2::3]
    return (
        vcnt,
        tri_cnt,
        round(min(xs), 3),
        round(max(xs), 3),
        round(min(ys), 3),
        round(max(ys), 3),
        round(min(zs), 3),
        round(max(zs), 3),
    )


def parse_nu20_stream(f: Any, file_size: int) -> tuple[list[MeshPrimitive], str]:
    """Parse classic PC NU20 .GHG/.GSC using GSNH NuLayer/DISP draw descriptors and bone bind matrices."""
    f.seek(0)
    head = f.read(8)
    if len(head) < 8:
        return [], "none"
    nu_off = struct.unpack_from("<I", head, 0)[0] + 4
    if nu_off < 8 or nu_off + 8 > file_size:
        return [], "none"

    f.seek(nu_off)
    if f.read(4) != b"NU20":
        return [], "none"

    n_tex = struct.unpack_from("<H", head, 4)[0]
    pos = 6
    tex_idx = 0
    while tex_idx < n_tex and pos + 28 <= nu_off:
        f.seek(pos)
        hdr = f.read(28)
        if len(hdr) < 28 or hdr[24:28] != b"DDS ":
            break
        w_signed = struct.unpack_from("<i", hdr, 0)[0]
        dds_size = struct.unpack_from("<I", hdr, 20)[0]
        if dds_size > nu_off or pos + 24 + dds_size > nu_off:
            return [], "nu20-bad-tex"
        tex_idx += 6 if w_signed < 0 else 1
        pos += 24 + dds_size

    if pos + 2 > nu_off:
        return [], "nu20-no-vb"
    f.seek(pos)
    n_vb = struct.unpack_from("<H", f.read(2), 0)[0]
    pos += 2

    vbs: list[bytes] = []
    for _ in range(n_vb):
        if pos + 4 > nu_off:
            break
        vb_size = struct.unpack_from("<I", f.read(4), 0)[0]
        pos += 4
        if vb_size == 0 or pos + vb_size > nu_off:
            break
        read_sz = min(vb_size, MAX_NU20_BUFFER_BYTES)
        vbs.append(f.read(read_sz))
        if vb_size > read_sz:
            f.seek(pos + vb_size)
        pos += vb_size

    if pos + 2 > nu_off:
        return [], "nu20-no-ib"
    f.seek(pos)
    n_ib = struct.unpack_from("<H", f.read(2), 0)[0]
    pos += 2

    ibs: list[list[int]] = []
    for _ in range(n_ib):
        if pos + 4 > nu_off:
            break
        ib_size = struct.unpack_from("<I", f.read(4), 0)[0]
        pos += 4
        if ib_size == 0 or pos + ib_size > nu_off:
            break
        read_bytes = min(ib_size, MAX_NU20_BUFFER_BYTES)
        raw_ib = f.read(read_bytes)
        cnt = len(raw_ib) // 2
        ibs.append(list(struct.unpack_from(f"<{cnt}H", raw_ib, 0)))
        if ib_size > read_bytes:
            f.seek(pos + ib_size)
        pos += ib_size

    if not vbs or not ibs:
        return [], "nu20-empty"

    # Read tail from nu_off..file_size for GSNH skeleton + NuLayer + 0x82 draw descriptors.
    tail_len = min(file_size - nu_off, MAX_NU20_BUFFER_BYTES)
    f.seek(nu_off)
    tail = f.read(tail_len)
    gsnh = tail.find(b"GSNH")
    if gsnh < 0 or gsnh + 420 > len(tail):
        return [], "nu20-empty"

    # Read bone inverse-bind matrices -> WorldBind[b] = m2[b]^-1
    nbones = struct.unpack_from("<I", tail, gsnh + 368)[0]
    world_binds: list[tuple[list[float], list[float]]] = []
    if 0 < nbones <= 512:
        r380 = struct.unpack_from("<i", tail, gsnh + 380)[0]
        m2_ptr = gsnh + 380 + r380
        if 0 <= m2_ptr and m2_ptr + nbones * 64 <= len(tail):
            for b in range(nbones):
                mat = struct.unpack_from("<16f", tail, m2_ptr + b * 64)
                world_binds.append(_inv_rigid_mat4(mat))

    # Locate group table and command array
    r280 = struct.unpack_from("<i", tail, gsnh + 280)[0]
    hdr_off = gsnh + 280 + r280 if r280 != 0 else -1
    cmd_base = -1
    n_groups = 0
    p_groups = -1
    if 0 <= hdr_off and hdr_off + 24 <= len(tail):
        cmd_base = hdr_off + 8 + struct.unpack_from("<i", tail, hdr_off + 8)[0]
        n_groups = struct.unpack_from("<i", tail, hdr_off + 16)[0]
        p_groups = hdr_off + 20 + struct.unpack_from("<i", tail, hdr_off + 20)[0]

    # Resolve (group_idx, bone_idx_or_none) pairs from NuLayer table if present
    draw_groups: list[tuple[int, int | None]] = []
    n_layers = struct.unpack_from("<I", tail, gsnh + 408)[0]
    r412 = struct.unpack_from("<i", tail, gsnh + 412)[0]
    p_layers = gsnh + 412 + r412 if (n_layers > 0 and r412 != 0) else -1

    def _collect_layers(skip_filtered: bool) -> list[tuple[int, int | None]]:
        collected: list[tuple[int, int | None]] = []
        if p_layers < 0 or p_groups < 0 or n_groups <= 0 or n_layers > 128:
            return collected
        for l_idx in range(n_layers):
            loff = p_layers + l_idx * 20
            if loff + 20 > len(tail):
                break
            n_rel, r_rel, s_rel, rl_rel, sl_rel = struct.unpack_from("<5i", tail, loff)
            lname = ""
            if n_rel != 0 and 0 <= loff + n_rel < len(tail):
                s_end = tail.find(b"\x00", loff + n_rel, min(loff + n_rel + 128, len(tail)))
                if s_end > loff + n_rel:
                    lname = tail[loff + n_rel : s_end].decode("ascii", "ignore")
            if skip_filtered and _should_skip_nu20_layer(lname):
                continue

            def _resolve_item(item_ptr: int) -> int:
                if item_ptr < 0 or item_ptr + 180 > len(tail):
                    return -1
                g_rel = struct.unpack_from("<i", tail, item_ptr + 176)[0]
                g_off = item_ptr + 176 + g_rel
                if g_off < p_groups or (g_off - p_groups) % 12 != 0:
                    return -1
                g_idx = (g_off - p_groups) // 12
                return g_idx if 0 <= g_idx < n_groups else -1

            # Prefer NextGen rigid/skinned slots first; fall back to LastGen slots if empty
            for rel, f_off, is_rigid in ((r_rel, 4, True), (s_rel, 8, False)):
                if rel == 0:
                    continue
                if is_rigid:
                    r_base = loff + f_off + rel
                    for bi in range(nbones):
                        if r_base + bi * 4 + 4 > len(tail):
                            break
                        br = struct.unpack_from("<i", tail, r_base + bi * 4)[0]
                        if br != 0:
                            t_ptr = r_base + bi * 4 + br
                            if t_ptr + 12 <= len(tail):
                                w2 = struct.unpack_from("<i", tail, t_ptr + 8)[0]
                                g_idx = _resolve_item(t_ptr + 8 + w2)
                                if g_idx >= 0:
                                    collected.append((g_idx, bi))
                else:
                    t_ptr = loff + f_off + rel
                    if t_ptr + 12 <= len(tail):
                        w2 = struct.unpack_from("<i", tail, t_ptr + 8)[0]
                        g_idx = _resolve_item(t_ptr + 8 + w2)
                        if g_idx >= 0:
                            collected.append((g_idx, None))

            if r_rel == 0 and s_rel == 0:
                for rel, f_off, is_rigid in ((rl_rel, 12, True), (sl_rel, 16, False)):
                    if rel == 0:
                        continue
                    if is_rigid:
                        r_base = loff + f_off + rel
                        for bi in range(nbones):
                            if r_base + bi * 4 + 4 > len(tail):
                                break
                            br = struct.unpack_from("<i", tail, r_base + bi * 4)[0]
                            if br != 0:
                                t_ptr = r_base + bi * 4 + br
                                if t_ptr + 12 <= len(tail):
                                    w2 = struct.unpack_from("<i", tail, t_ptr + 8)[0]
                                    g_idx = _resolve_item(t_ptr + 8 + w2)
                                    if g_idx >= 0:
                                        collected.append((g_idx, bi))
                    else:
                        t_ptr = loff + f_off + rel
                        if t_ptr + 12 <= len(tail):
                            w2 = struct.unpack_from("<i", tail, t_ptr + 8)[0]
                            g_idx = _resolve_item(t_ptr + 8 + w2)
                            if g_idx >= 0:
                                collected.append((g_idx, None))
        return collected

    if n_layers > 0:
        draw_groups = _collect_layers(skip_filtered=True)
        if not draw_groups:
            draw_groups = _collect_layers(skip_filtered=False)

    # Expand resolved groups -> (desc_ints, bone_idx_or_none); otherwise fall back to group/0x82 scan
    draw_calls: list[tuple[tuple[int, ...], int | None]] = []
    if draw_groups and cmd_base >= 0 and p_groups >= 0:
        seen_cmds: set[tuple[int, int | None]] = set()
        for g_idx, bone_idx in draw_groups:
            goff = p_groups + g_idx * 12
            if goff + 12 > len(tail):
                continue
            cnt = struct.unpack_from("<i", tail, goff)[0]
            if cnt <= 0 or cnt > 256:
                continue
            p_cmds = goff + 8 + struct.unpack_from("<i", tail, goff + 8)[0]
            for k in range(cnt):
                if p_cmds + k * 4 + 4 > len(tail):
                    break
                c_idx = struct.unpack_from("<i", tail, p_cmds + k * 4)[0]
                if (c_idx, bone_idx) in seen_cmds:
                    continue
                c_off = cmd_base + c_idx * 16
                if c_off < 0 or c_off + 16 > len(tail):
                    continue
                c0, rel, _, _ = struct.unpack_from("<4i", tail, c_off)
                t_off = c_off + 4 + rel
                if t_off < 0 or t_off + 56 > len(tail):
                    continue
                desc = struct.unpack_from("<14i", tail, t_off)
                if desc[0] in (4, 5, 6) and 0 < desc[1] < 200000 and (desc[2] & 0xFF) in (24, 28, 32, 36, 40, 44, 48):
                    seen_cmds.add((c_idx, bone_idx))
                    draw_calls.append((desc, bone_idx))

    if not draw_calls and p_groups >= 0 and cmd_base >= 0 and 0 < n_groups <= 2048:
        for g_idx in range(n_groups):
            goff = p_groups + g_idx * 12
            if goff + 12 > len(tail):
                break
            cnt = struct.unpack_from("<i", tail, goff)[0]
            if cnt <= 0 or cnt > 256:
                continue
            p_cmds = goff + 8 + struct.unpack_from("<i", tail, goff + 8)[0]
            for k in range(cnt):
                if p_cmds + k * 4 + 4 > len(tail):
                    break
                c_idx = struct.unpack_from("<i", tail, p_cmds + k * 4)[0]
                c_off = cmd_base + c_idx * 16
                if c_off < 0 or c_off + 16 > len(tail):
                    continue
                c0, rel, _, _ = struct.unpack_from("<4i", tail, c_off)
                t_off = c_off + 4 + rel
                if t_off < 0 or t_off + 56 > len(tail):
                    continue
                desc = struct.unpack_from("<14i", tail, t_off)
                if desc[0] in (4, 5, 6) and 0 < desc[1] < 200000 and (desc[2] & 0xFF) in (24, 28, 32, 36, 40, 44, 48):
                    draw_calls.append((desc, None))

    if not draw_calls:
        # Last-resort scan for 0x82 command records across tail
        scan_start = max(0, gsnh - 250000)
        for off in range(scan_start, gsnh, 4):
            c0, rel, z0, z1 = struct.unpack_from("<4i", tail, off)
            if c0 == 0x82 and z0 == 0 and z1 == 0 and 0 < rel < 200000:
                t_off = off + 4 + rel
                if t_off + 56 <= len(tail):
                    desc = struct.unpack_from("<14i", tail, t_off)
                    if desc[0] in (4, 5, 6) and 0 < desc[1] < 200000 and (desc[2] & 0xFF) in (24, 28, 32, 36, 40, 44, 48):
                        draw_calls.append((desc, None))

    primitives: list[MeshPrimitive] = []
    seen_ranges: set[tuple[int, int, int, int, int | None]] = set()
    seen_bboxes: set[tuple[Any, ...]] = set()

    for desc, bone_idx in draw_calls:
        if len(primitives) >= MAX_MESHES_PER_MODEL:
            break
        prim_tp_raw = desc[0]
        tri_cnt = desc[1]
        stride = desc[2] & 0xFF
        vbase = desc[5]
        vcnt = desc[6]
        ioff = desc[7]
        ib_idx = desc[8]
        vb_idx = desc[9]

        if not (0 <= vb_idx < len(vbs)) or not (0 <= ib_idx < len(ibs)):
            continue
        if vcnt < 3 or tri_cnt <= 0 or stride <= 0:
            continue

        range_key = (vb_idx, vbase, vcnt, ioff, bone_idx)
        if range_key in seen_ranges:
            continue

        vb_bytes = vbs[vb_idx]
        ib_all = ibs[ib_idx]
        idx_cnt = (tri_cnt + 2) if prim_tp_raw == 6 else (tri_cnt * 3)
        if vbase < 0 or (vbase + vcnt) * stride > len(vb_bytes):
            continue
        if ioff < 0 or ioff + idx_cnt > len(ib_all):
            continue

        use_bone = bone_idx is not None and 0 <= bone_idx < len(world_binds)
        if use_bone:
            r_inv, t_inv = world_binds[bone_idx]
        else:
            r_inv, t_inv = None, None

        pos_list: list[float] = []
        norm_list: list[float] = []
        uv_list: list[float] = []
        has_uv = stride >= 32
        uv_ok = True
        norm_ok = stride >= 24

        for vi in range(vbase, vbase + vcnt):
            v_off = vi * stride
            x, y, z = struct.unpack_from("<fff", vb_bytes, v_off)
            if not (math.isfinite(x) and math.isfinite(y) and math.isfinite(z) and abs(x) < 1e5 and abs(y) < 1e5 and abs(z) < 1e5):
                x, y, z = 0.0, 0.0, 0.0
            if use_bone and r_inv is not None and t_inv is not None:
                wx = x * r_inv[0] + y * r_inv[3] + z * r_inv[6] + t_inv[0]
                wy = x * r_inv[1] + y * r_inv[4] + z * r_inv[7] + t_inv[1]
                wz = x * r_inv[2] + y * r_inv[5] + z * r_inv[8] + t_inv[2]
                pos_list.extend((wx, wy, wz))
            else:
                pos_list.extend((x, y, z))

            if norm_ok:
                nx = vb_bytes[v_off + 12] / 127.5 - 1.0
                ny = vb_bytes[v_off + 13] / 127.5 - 1.0
                nz = vb_bytes[v_off + 14] / 127.5 - 1.0
                if use_bone and r_inv is not None:
                    wnx = nx * r_inv[0] + ny * r_inv[3] + nz * r_inv[6]
                    wny = nx * r_inv[1] + ny * r_inv[4] + nz * r_inv[7]
                    wnz = nx * r_inv[2] + ny * r_inv[5] + nz * r_inv[8]
                    nx, ny, nz = wnx, wny, wnz
                nlen = math.sqrt(nx * nx + ny * ny + nz * nz)
                if nlen > 1e-4:
                    norm_list.extend((nx / nlen, ny / nlen, nz / nlen))
                else:
                    norm_list.extend((0.0, 1.0, 0.0))

            if has_uv:
                u, v = struct.unpack_from("<ff", vb_bytes, v_off + stride - 8)
                if not (math.isfinite(u) and math.isfinite(v) and abs(u) <= 64.0 and abs(v) <= 64.0):
                    uv_ok = False
                uv_list.extend((u if math.isfinite(u) else 0.0, v if math.isfinite(v) else 0.0))

        sub_ib = ib_all[ioff : ioff + idx_cnt]
        tri = decode_triangles(sub_ib, vcnt, 1 if prim_tp_raw == 6 else 0)
        if len(tri) < 3:
            continue

        bbox_key = _nu20_bbox_key(pos_list, vcnt, len(tri) // 3)
        if bbox_key in seen_bboxes:
            continue
        seen_ranges.add(range_key)
        seen_bboxes.add(bbox_key)

        prim = MeshPrimitive()
        prim.positions = pos_list
        if norm_ok and len(norm_list) == vcnt * 3:
            prim.normals = norm_list
        if has_uv and uv_ok and len(uv_list) == vcnt * 2:
            prim.uvs = uv_list
        prim.indices = tri
        primitives.append(prim)

    return primitives, ("nu20-disp" if primitives else "nu20-empty")


def parse_hsem_stream(f: Any, file_size: int) -> tuple[list[MeshPrimitive], str]:
    """Parse 02UN/HSEM render-mesh container resolving 0xC000xxxx back-references and submesh slices."""
    f.seek(0)
    scan_buf = f.read(min(file_size, MAX_HSEM_SCAN_BYTES))
    hsem_pos = scan_buf.find(b"HSEM")
    if hsem_pos < 0:
        return [], "none"

    f.seek(hsem_pos)
    buf = f.read(min(file_size - hsem_pos, MAX_HSEM_PARSE_BYTES))
    if len(buf) < 16:
        return [], "none"

    p = 4
    ver = struct.unpack_from(">I", buf, p)[0]
    p += 4
    mode = f"hsem-0x{ver:X}"

    if p + 4 <= len(buf) and buf[p : p + 4] == b"ROTV":
        p += 4
    elif ver >= 0xAD:
        if p + 4 > len(buf):
            return [], mode
        p += 4

    if p + 4 > len(buf):
        return [], mode
    mesh_count = struct.unpack_from(">I", buf, p)[0]
    p += 4
    if mesh_count == 0 or mesh_count > 4096:
        return [], mode

    ltmu = buf.find(b"LTMU", p)
    psid = buf.find(b"PSID", p)
    limit = ltmu if ltmu > p else (psid if psid > p else len(buf))

    n_logh = 0
    if psid >= 0:
        scan_logh = psid
        while True:
            idx = buf.find(b"LOGH", scan_logh)
            if idx < 0:
                break
            n_logh += 1
            scan_logh = idx + 4
    n_logh = max(1, n_logh)

    all_vbs: list[dict[str, Any]] = []
    all_ibs: list[list[int]] = []
    rid_to_vb: dict[int, dict[str, Any]] = {}
    rid_to_ib: dict[int, list[int]] = {}
    submeshes: list[dict[str, Any]] = []

    for m in range(mesh_count):
        if p + 16 > limit:
            break
        if _has_explicit_hsem_vbc(buf, p, ver):
            vb_count = struct.unpack_from(">I", buf, p)[0]
            p += 4
        else:
            vb_count = 1
        if vb_count == 0 or vb_count > 16:
            break

        vb_specs: list[tuple[str, int, Any]] = []
        bad_mesh = False
        for v_slot in range(vb_count):
            if p + 4 > limit:
                bad_mesh = True
                break
            pres = struct.unpack_from(">I", buf, p)[0]
            p += 4
            if pres >= 0x80000000:
                if p + 8 > limit:
                    bad_mesh = True
                    break
                p += 8  # ref_count + byte_offset
                vb_specs.append(("ref", v_slot, pres & 0xFFFF))
            elif pres != 0:
                if p + 8 > limit:
                    bad_mesh = True
                    break
                _flags, nv = struct.unpack_from(">II", buf, p)
                p += 8
                if nv == 0 or nv > 500000:
                    bad_mesh = True
                    break
                state = {
                    "pos_type": -1,
                    "pos_off": 0,
                    "norm_type": -1,
                    "norm_off": 0,
                    "uv_type": -1,
                    "uv_off": 0,
                    "stride": 0,
                }
                if ver >= 0xA1:
                    if p + 8 > limit or buf[p : p + 4] != b"DXTV":
                        bad_mesh = True
                        break
                    p += 4
                    desc_ver = struct.unpack_from(">I", buf, p)[0]
                    p += 4
                    if desc_ver <= 0x2D:
                        if p + 32 > limit:
                            bad_mesh = True
                            break
                        for slot in range(16):
                            tp, off = buf[p], buf[p + 1]
                            p += 2
                            accum_attr(slot, tp, off, state, sequential_if_zero=True)
                    else:
                        if p + 4 > limit:
                            bad_mesh = True
                            break
                        n_attr = struct.unpack_from(">I", buf, p)[0]
                        p += 4
                        if n_attr > 64 or p + n_attr * 3 > limit:
                            bad_mesh = True
                            break
                        for _a in range(n_attr):
                            df, tp, off = buf[p], buf[p + 1], buf[p + 2]
                            p += 3
                            accum_attr(df, tp, off, state, sequential_if_zero=False)
                    if p + 6 > limit:
                        bad_mesh = True
                        break
                    p += 6
                elif ver < 0x2E:
                    if p + 32 > limit:
                        bad_mesh = True
                        break
                    for slot in range(16):
                        tp, off = buf[p], buf[p + 1]
                        p += 2
                        accum_attr(slot, tp, off, state, sequential_if_zero=True)
                else:
                    if p + 4 > limit:
                        bad_mesh = True
                        break
                    n_attr = struct.unpack_from(">I", buf, p)[0]
                    p += 4
                    if n_attr > 64 or p + n_attr * 3 > limit:
                        bad_mesh = True
                        break
                    for _a in range(n_attr):
                        df, tp, off = buf[p], buf[p + 1], buf[p + 2]
                        p += 3
                        accum_attr(df, tp, off, state, sequential_if_zero=False)

                stride = state["stride"]
                if stride <= 0 or p + nv * stride + 4 > limit:
                    bad_mesh = True
                    break
                vb_obj = {
                    "slot": v_slot,
                    "nv": nv,
                    "stride": stride,
                    "data_pos": p,
                    "state": state,
                    "next_vbase": 0,
                    "rid": None,
                }
                all_vbs.append(vb_obj)
                vb_specs.append(("new", v_slot, vb_obj))
                p += nv * stride + 4  # data + byte_offset
            else:
                if p + 4 > limit:
                    bad_mesh = True
                    break
                p += 4  # byte_offset
                vb_specs.append(("none", v_slot, None))

        if bad_mesh or p + 8 > limit:
            break

        unk1, ib_pres = struct.unpack_from(">II", buf, p)
        p += 8
        cur_ib: list[int] | None = None
        if ib_pres >= 0x80000000:
            if p + 4 > limit:
                break
            p += 4
            rid = ib_pres & 0xFFFF
            if rid not in rid_to_ib and all_ibs:
                rid_to_ib[rid] = all_ibs[-1]
            cur_ib = rid_to_ib.get(rid, all_ibs[-1] if all_ibs else None)
        elif ib_pres != 0:
            if p + 12 > limit:
                break
            _ib_flags, ic, isz = struct.unpack_from(">III", buf, p)
            p += 12
            if isz == 0:
                isz = 2
            ib_bytes = ic * isz
            if ic > 2000000 or isz not in (2, 4) or p + ib_bytes > limit:
                break
            if isz == 2:
                cur_ib = list(struct.unpack_from(f">{ic}H", buf, p))
            else:
                cur_ib = list(struct.unpack_from(f">{ic}I", buf, p))
            all_ibs.append(cur_ib)
            p += ib_bytes

        if unk1 != 0:
            # Shadow / Z-prepass mesh entry: skip geometry and advance to next NuRenderMesh
            p_after = p + 12
            if m + 1 < mesh_count:
                p = p_after + (0 if _is_hsem_mesh_start(buf, p_after, ver) else 4)
            continue

        if p + 26 > limit:
            break
        ioff, icnt, vbase = struct.unpack_from(">III", buf, p)
        vcnt, prim_tp = struct.unpack_from(">HH", buf, p + 16)
        blen = struct.unpack_from(">I", buf, p + 22)[0]
        if blen > 256:
            blen = 0

        resolved_vbs: list[dict[str, Any] | None] = []
        for kind, slot, val in vb_specs:
            if kind == "new":
                val["next_vbase"] = vbase + vcnt
                resolved_vbs.append(val)
            elif kind == "ref":
                rid = val
                if rid not in rid_to_vb:
                    cands = [
                        x for x in all_vbs
                        if x["slot"] == slot and x["rid"] is None and x["next_vbase"] == vbase and vbase + vcnt <= x["nv"]
                    ]
                    if not cands:
                        cands = [x for x in reversed(all_vbs) if x["slot"] == slot and x["rid"] is None and vbase + vcnt <= x["nv"]]
                    if not cands:
                        cands = [x for x in reversed(all_vbs) if x["slot"] == slot and vbase + vcnt <= x["nv"]]
                    if cands:
                        cands[0]["rid"] = rid
                        rid_to_vb[rid] = cands[0]
                vb_obj = rid_to_vb.get(rid)
                if vb_obj is not None:
                    vb_obj["next_vbase"] = max(vb_obj["next_vbase"], vbase + vcnt)
                resolved_vbs.append(vb_obj)
            else:
                resolved_vbs.append(None)

        if vcnt >= 3 and icnt >= 3 and cur_ib is not None and resolved_vbs and resolved_vbs[0] is not None:
            vb0 = resolved_vbs[0]
            vb1 = resolved_vbs[1] if len(resolved_vbs) > 1 else None
            if vbase + vcnt <= vb0["nv"] and ioff + icnt <= len(cur_ib):
                submeshes.append({
                    "vb0": vb0,
                    "vb1": vb1,
                    "ib": cur_ib,
                    "vbase": vbase,
                    "vcnt": vcnt,
                    "ioff": ioff,
                    "icnt": icnt,
                    "prim_tp": prim_tp,
                    "blen": blen,
                })

        p_after = p + 26 + blen
        if m + 1 < mesh_count:
            post = 76 if ver >= 0x30 else (44 if ver >= 0x2E else 8)
            advanced = False
            for d in (post, 4, 8, 44, 48, 72, 76):
                if _is_hsem_mesh_start(buf, p_after + d, ver):
                    p = p_after + d
                    advanced = True
                    break
            if not advanced:
                for cand in range(p_after + 4, min(limit - 24, p_after + 300000)):
                    if _is_hsem_mesh_start(buf, cand, ver):
                        p = cand
                        advanced = True
                        break
                if not advanced:
                    break

    if not submeshes:
        return [], mode

    lod0_cnt = math.ceil(len(submeshes) / n_logh)
    lod0 = submeshes[:lod0_cnt]
    if sum(1 for sm in lod0 if sm["blen"] > 0) >= 3:
        lod0 = [sm for sm in lod0 if sm["blen"] > 0]

    result: list[MeshPrimitive] = []
    seen_bboxes: set[tuple[Any, ...]] = set()
    for sm in lod0:
        if len(result) >= MAX_MESHES_PER_MODEL:
            break
        positions, normals, uvs = _decode_vb_slice(buf, sm["vb0"], sm["vb1"], sm["vbase"], sm["vcnt"])
        if len(positions) < 9:
            continue
        sub_ib = sm["ib"][sm["ioff"] : sm["ioff"] + sm["icnt"]]
        tri = decode_triangles(sub_ib, len(positions) // 3, sm["prim_tp"])
        if len(tri) < 3:
            continue
        bbox_key = _nu20_bbox_key(positions, len(positions) // 3, len(tri) // 3)
        if bbox_key in seen_bboxes:
            continue
        seen_bboxes.add(bbox_key)

        prim = MeshPrimitive()
        prim.positions = positions
        if len(normals) == len(positions):
            prim.normals = normals
        if len(uvs) == (len(positions) // 3) * 2:
            prim.uvs = uvs
        prim.indices = tri
        result.append(prim)

    return result, mode


def create_proxy_primitive() -> list[MeshPrimitive]:
    """Return a clean octahedron proxy primitive when a container holds no direct mesh payload."""
    prim = MeshPrimitive()
    r = 0.12
    prim.positions = [
        0.0, r, 0.0,
        -r, 0.0, -r,
        r, 0.0, -r,
        r, 0.0, r,
        -r, 0.0, r,
        0.0, -r, 0.0,
    ]
    prim.indices = [
        0, 1, 2, 0, 2, 3, 0, 3, 4, 0, 4, 1,
        5, 2, 1, 5, 3, 2, 5, 4, 3, 5, 1, 4,
    ]
    return [prim]


def write_glb(output_glb_path: Path, primitives: list[MeshPrimitive]) -> tuple[int, int]:
    """Write primitives as binary glTF 2.0 (.glb) and return (vertex_count, triangle_count)."""
    bin_chunks: list[bytes] = []
    bin_len = 0
    accessors: list[dict[str, Any]] = []
    buffer_views: list[dict[str, Any]] = []
    gltf_primitives: list[dict[str, Any]] = []
    total_verts = 0
    total_tris = 0

    for prim in primitives:
        vc = len(prim.positions) // 3
        if vc == 0 or len(prim.indices) < 3:
            continue
        total_verts += vc
        total_tris += len(prim.indices) // 3

        xs = prim.positions[0::3]
        ys = prim.positions[1::3]
        zs = prim.positions[2::3]
        pos_bytes = struct.pack(f"<{len(prim.positions)}f", *prim.positions)
        pos_view = len(buffer_views)
        buffer_views.append({"buffer": 0, "byteOffset": bin_len, "byteLength": len(pos_bytes), "target": 34962})
        pos_acc = len(accessors)
        accessors.append(
            {
                "bufferView": pos_view,
                "componentType": 5126,
                "count": vc,
                "type": "VEC3",
                "min": [min(xs), min(ys), min(zs)],
                "max": [max(xs), max(ys), max(zs)],
            }
        )
        bin_chunks.append(pos_bytes)
        bin_len += len(pos_bytes)

        attrs: dict[str, int] = {"POSITION": pos_acc}

        if len(prim.normals) == vc * 3:
            norm_bytes = struct.pack(f"<{len(prim.normals)}f", *prim.normals)
            norm_view = len(buffer_views)
            buffer_views.append({"buffer": 0, "byteOffset": bin_len, "byteLength": len(norm_bytes), "target": 34962})
            norm_acc = len(accessors)
            accessors.append({"bufferView": norm_view, "componentType": 5126, "count": vc, "type": "VEC3"})
            attrs["NORMAL"] = norm_acc
            bin_chunks.append(norm_bytes)
            bin_len += len(norm_bytes)

        if len(prim.uvs) == vc * 2:
            uv_bytes = struct.pack(f"<{len(prim.uvs)}f", *prim.uvs)
            uv_view = len(buffer_views)
            buffer_views.append({"buffer": 0, "byteOffset": bin_len, "byteLength": len(uv_bytes), "target": 34962})
            uv_acc = len(accessors)
            accessors.append({"bufferView": uv_view, "componentType": 5126, "count": vc, "type": "VEC2"})
            attrs["TEXCOORD_0"] = uv_acc
            bin_chunks.append(uv_bytes)
            bin_len += len(uv_bytes)

        idx_bytes = struct.pack(f"<{len(prim.indices)}I", *prim.indices)
        idx_view = len(buffer_views)
        buffer_views.append({"buffer": 0, "byteOffset": bin_len, "byteLength": len(idx_bytes), "target": 34963})
        idx_acc = len(accessors)
        accessors.append({"bufferView": idx_view, "componentType": 5125, "count": len(prim.indices), "type": "SCALAR"})
        bin_chunks.append(idx_bytes)
        bin_len += len(idx_bytes)

        gltf_primitives.append({"attributes": attrs, "indices": idx_acc, "material": 0, "mode": 4})

    bin_pad = (4 - (bin_len & 3)) & 3
    if bin_pad:
        bin_chunks.append(b"\x00" * bin_pad)
        bin_len += bin_pad

    doc = {
        "asset": {"version": "2.0", "generator": "RemakeEngine-LegoModelConverter-Py"},
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": [{"mesh": 0}],
        "materials": [
            {
                "pbrMetallicRoughness": {
                    "baseColorFactor": [0.85, 0.87, 0.90, 1.0],
                    "metallicFactor": 0.05,
                    "roughnessFactor": 0.65,
                },
                "doubleSided": True,
            }
        ],
        "meshes": [{"primitives": gltf_primitives}],
        "accessors": accessors,
        "bufferViews": buffer_views,
        "buffers": [{"byteLength": bin_len}],
    }
    raw_json = json.dumps(doc, separators=(",", ":")).encode("utf-8")
    json_pad = (4 - (len(raw_json) & 3)) & 3
    json_bytes = raw_json + (b" " * json_pad)

    total_len = 12 + 8 + len(json_bytes) + 8 + bin_len
    output_glb_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_glb_path, "wb") as out:
        out.write(struct.pack("<3I", 0x46546C67, 2, total_len))
        out.write(struct.pack("<2I", len(json_bytes), 0x4E4F534A))
        out.write(json_bytes)
        out.write(struct.pack("<2I", bin_len, 0x004E4942))
        for chunk in bin_chunks:
            out.write(chunk)

    return total_verts, total_tris


def convert_single_model(src_path: Path, output_glb_path: Path) -> tuple[int, int, str]:
    """Parse one LEGO .ghg/.gsc model file and export it to glTF 2.0 (.glb)."""
    file_size = src_path.stat().st_size
    primitives: list[MeshPrimitive] = []
    mode = "none"

    with open(src_path, "rb") as f:
        primitives, mode = parse_nu20_stream(f, file_size)
        if not primitives:
            primitives, hsem_mode = parse_hsem_stream(f, file_size)
            if hsem_mode != "none":
                mode = hsem_mode

    if not primitives:
        primitives = create_proxy_primitive()
        if mode == "none":
            mode = "proxy"

    verts, tris = write_glb(output_glb_path, primitives)
    return verts, tris, mode


def discover_game_models(lego_root: Path, max_per_game: int) -> dict[str, list[tuple[Path, str]]]:
    """Discover .ghg/.gsc assets across child games with archive-prefix deduplication."""
    games_dir = lego_root / "Games"
    results: dict[str, list[tuple[Path, str]]] = {}
    if not games_dir.is_dir():
        return results

    for game_dir in sorted(games_dir.iterdir(), key=lambda p: p.name.lower()):
        if not game_dir.is_dir():
            continue
        game_files = game_dir / "GameFiles"
        if not game_files.is_dir():
            continue

        search_roots: list[Path] = []
        for pref in ("extracted/assets", "windows-full/assets"):
            cand = game_files / pref
            if cand.is_dir():
                search_roots.append(cand)
        if not search_roots:
            for sub in sorted(game_files.iterdir(), key=lambda p: p.name.lower()):
                if sub.is_dir() and sub.name not in IGNORED_SUBDIRS:
                    search_roots.append(sub)
        if not search_roots:
            continue

        game_items: list[tuple[Path, str]] = []
        seen_rel: set[str] = set()
        for sr in search_roots:
            found: list[Path] = []
            for root_str, _, filenames in os.walk(sr):
                for fn in filenames:
                    lower = fn.lower()
                    if lower.endswith(".ghg") or lower.endswith(".gsc"):
                        found.append(Path(root_str) / fn)
            found.sort(key=lambda p: str(p).lower())

            for f in found:
                rel_from_sr = f.relative_to(sr).as_posix()
                slash = rel_from_sr.find("/")
                if slash > 0:
                    first = rel_from_sr[:slash]
                    if first.lower().endswith(".dat") or first.lower().endswith(".datwin") or "__" in first:
                        rel_short = rel_from_sr[slash + 1 :]
                    else:
                        rel_short = rel_from_sr
                else:
                    rel_short = rel_from_sr
                key = rel_short.lower()
                if key not in seen_rel:
                    seen_rel.add(key)
                    game_items.append((f, rel_short))
                    if max_per_game > 0 and len(game_items) >= max_per_game:
                        break
            if max_per_game > 0 and len(game_items) >= max_per_game:
                break

        if game_items:
            results[game_dir.name] = game_items

    return results


def manage_godot_import_scope(
    assets_out_root: Path,
    manifest_assets: list[dict[str, Any]],
) -> None:
    """Keep Godot startup fast when >300 assets exist by gating bulk dirs with .gdignore + un-ignored samples."""
    bulk_mode = len(manifest_assets) > 300
    by_game: dict[str, list[dict[str, Any]]] = {}
    for entry in manifest_assets:
        by_game.setdefault(entry["game"], []).append(entry)

    for game_name, entries in by_game.items():
        game_out = assets_out_root / game_name
        raw_dir = game_out / "raw"
        glb_dir = game_out / "glb"
        direct_samples = game_out / "direct_samples"
        glb_samples = game_out / "glb_samples"

        if bulk_mode:
            for d in (raw_dir, glb_dir):
                d.mkdir(parents=True, exist_ok=True)
                (d / ".gdignore").write_text("", encoding="utf-8")

            # Clear old sample links and pick up to 5 real-mesh .ghg + 5 .gsc representative samples per game.
            for sd in (direct_samples, glb_samples):
                if sd.exists():
                    shutil.rmtree(sd)
                sd.mkdir(parents=True, exist_ok=True)

            non_proxy = [e for e in entries if e["parser_mode"] not in ("proxy", "nu20-proxy")]
            pool = non_proxy if non_proxy else entries
            ghg_picks = [e for e in pool if e["relative_path"].lower().endswith(".ghg")][:5]
            gsc_picks = [e for e in pool if e["relative_path"].lower().endswith(".gsc")][:5]
            picks = ghg_picks + gsc_picks
            if not picks:
                picks = pool[:10]

            for item in picks:
                base_name = Path(item["relative_path"]).name
                raw_src = game_out / "raw" / item["relative_path"]
                glb_rel = os.path.splitext(item["relative_path"])[0] + ".glb"
                glb_src = game_out / "glb" / glb_rel
                if raw_src.exists():
                    hardlink_or_copy(raw_src, direct_samples / base_name, force=True)
                if glb_src.exists():
                    hardlink_or_copy(glb_src, glb_samples / (Path(glb_rel).name), force=True)
        else:
            for d in (raw_dir, glb_dir):
                ignore_file = d / ".gdignore"
                if ignore_file.exists():
                    ignore_file.unlink()
            for sd in (direct_samples, glb_samples):
                if sd.exists():
                    shutil.rmtree(sd)


def export_all_models(lego_root: Path, godot_dir: Path, max_per_game: int, force: bool) -> None:
    """Convert and link all discovered models into godot_dir/assets/3d/ and write manifest.json."""
    assets_out_root = godot_dir / "assets" / "3d"
    assets_out_root.mkdir(parents=True, exist_ok=True)
    manifest_path = assets_out_root / "manifest.json"

    cached_stats: dict[tuple[str, str], dict[str, Any]] = {}
    if not force and manifest_path.is_file():
        try:
            old_data = json.loads(manifest_path.read_text(encoding="utf-8"))
            for item in old_data.get("assets", []):
                cached_stats[(str(item.get("game", "")), str(item.get("relative_path", "")))] = item
        except (OSError, ValueError):
            cached_stats = {}

    game_models = discover_game_models(lego_root, max_per_game)
    manifest_assets: list[dict[str, Any]] = []
    converted_now = 0
    copied_raw_now = 0
    mode_counts: dict[str, int] = {}

    for game_name, items in game_models.items():
        print(f"[{game_name}] Processing {len(items)} 3D model(s)")
        for src_file, rel in items:
            ext_len = len(src_file.suffix)
            rel_no_ext = rel[:-ext_len] if ext_len > 0 else rel
            raw_dest = assets_out_root / game_name / "raw" / rel
            glb_dest = assets_out_root / game_name / "glb" / f"{rel_no_ext}.glb"

            if hardlink_or_copy(src_file, raw_dest, force=force):
                copied_raw_now += 1

            cache_key = (game_name, rel)
            if not force and glb_dest.is_file() and cache_key in cached_stats:
                prev = cached_stats[cache_key]
                verts = int(prev.get("vertices", 0))
                tris = int(prev.get("triangles", 0))
                parser_mode = str(prev.get("parser_mode", "cached"))
            else:
                verts, tris, parser_mode = convert_single_model(src_file, glb_dest)
                converted_now += 1

            mode_counts[parser_mode] = mode_counts.get(parser_mode, 0) + 1
            manifest_assets.append(
                {
                    "game": game_name,
                    "relative_path": rel,
                    "raw_res": f"res://assets/3d/{game_name}/raw/{rel}",
                    "glb_res": f"res://assets/3d/{game_name}/glb/{rel_no_ext}.glb",
                    "vertices": verts,
                    "triangles": tris,
                    "parser_mode": parser_mode,
                }
            )

    manage_godot_import_scope(assets_out_root, manifest_assets)

    manifest_obj = {
        "generated_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "total_assets": len(manifest_assets),
        "converted_now": converted_now,
        "copied_raw_now": copied_raw_now,
        "parser_mode_summary": mode_counts,
        "assets": manifest_assets,
    }
    manifest_path.write_text(json.dumps(manifest_obj, indent=2), encoding="utf-8")
    print(
        f"Completed conversion: total={len(manifest_assets)}, convertedNow={converted_now}, "
        f"linkedRawNow={copied_raw_now}, modes={mode_counts} -> {manifest_path}"
    )


def sync_tree_hardlink(
    src_dir: Path,
    dst_dir: Path,
    overwrite: bool = True,
    preserve_suffixes: tuple[str, ...] = (),
) -> tuple[int, int]:
    """Recursively hardlink/copy files from src_dir to dst_dir, optionally preserving matching suffixes."""
    files_synced = 0
    links_created = 0
    if not src_dir.is_dir():
        return 0, 0

    for root_str, _, filenames in os.walk(src_dir):
        rel_root = Path(root_str).relative_to(src_dir)
        out_root = dst_dir / rel_root
        out_root.mkdir(parents=True, exist_ok=True)
        for fn in filenames:
            src_f = Path(root_str) / fn
            dst_f = out_root / fn
            if dst_f.exists():
                if not overwrite or (preserve_suffixes and fn.lower().endswith(preserve_suffixes)):
                    continue
                try:
                    if os.path.samefile(src_f, dst_f):
                        files_synced += 1
                        continue
                except OSError:
                    pass
                dst_f.unlink()
            try:
                os.link(src_f, dst_f)
                links_created += 1
            except OSError:
                shutil.copy2(src_f, dst_f)
            files_synced += 1
    return files_synced, links_created


def sync_staging_to_target(staging_dir: Path, target_dir: Path) -> None:
    """Copy verified addon, viewer scripts, 3D assets, imported cache, and plugin config while preserving user scenes."""
    target_dir.mkdir(parents=True, exist_ok=True)

    addons_synced, _ = sync_tree_hardlink(staging_dir / "addons", target_dir / "addons", overwrite=True)
    scenes_synced, _ = sync_tree_hardlink(
        staging_dir / "scenes",
        target_dir / "scenes",
        overwrite=True,
        preserve_suffixes=(".tscn",),
    )
    assets_synced, asset_links = sync_tree_hardlink(staging_dir / "assets", target_dir / "assets", overwrite=True)

    staging_imported = staging_dir / ".godot" / "imported"
    if staging_imported.is_dir():
        sync_tree_hardlink(staging_imported, target_dir / ".godot" / "imported", overwrite=True)

    proj_dst = target_dir / "project.godot"
    proj_src = staging_dir / "project.godot"
    proj_text = proj_dst.read_text(encoding="utf-8") if proj_dst.is_file() else proj_src.read_text(encoding="utf-8")

    plugin_cfg = '"res://addons/lego_formats/plugin.cfg"'
    if "[editor_plugins]" not in proj_text:
        proj_text += f"\n[editor_plugins]\n\nenabled=PackedStringArray({plugin_cfg})\n"
    elif plugin_cfg not in proj_text:
        if "enabled=PackedStringArray(" in proj_text:
            proj_text = proj_text.replace("enabled=PackedStringArray(", f"enabled=PackedStringArray({plugin_cfg}, ", 1)
        else:
            proj_text = re.sub(
                r"(\[editor_plugins\]\s*)",
                rf"\1enabled=PackedStringArray({plugin_cfg})\n",
                proj_text,
                count=1,
            )

    if "run/main_scene=" not in proj_text:
        proj_text = re.sub(
            r"(\[application\][\r\n]+)",
            r'\1run/main_scene="res://scenes/AssetViewer.tscn"\n',
            proj_text,
            count=1,
        )

    proj_dst.write_text(proj_text, encoding="utf-8")
    print(
        f"Synced test_staging -> {target_dir}: addons={addons_synced}, scenes={scenes_synced}, "
        f"assets={assets_synced} (hardlinks={asset_links}), updated project.godot"
    )


def parse_cli_args() -> argparse.Namespace:
    """Parse arguments after `--` when run under Blender or standalone Python."""
    argv = sys.argv[1:]
    if "--" in argv:
        argv = argv[argv.index("--") + 1 :]

    parser = argparse.ArgumentParser(description="Convert LEGO .ghg/.gsc 3D models to .glb and sync into Godot.")
    parser.add_argument("--lego-root", required=True, help="Path to EngineApps/Games/Lego")
    parser.add_argument("--godot-dir", required=True, help="Path to staging Godot project directory")
    parser.add_argument("--max-per-game", type=int, default=0, help="Optional cap per game (0 = all)")
    parser.add_argument("--force", action="store_true", help="Overwrite existing converted .glb and links")
    parser.add_argument("--sync-to", default="", help="Optional target Godot directory to sync verified files into")
    parser.add_argument("--sync-only", action="store_true", help="Skip conversion and only sync --godot-dir -> --sync-to")
    return parser.parse_args(argv)


def main() -> int:
    args = parse_cli_args()
    lego_root = Path(args.lego_root).resolve()
    godot_dir = Path(args.godot_dir).resolve()

    if not args.sync_only:
        export_all_models(lego_root, godot_dir, args.max_per_game, args.force)

    if args.sync_to:
        sync_staging_to_target(godot_dir, Path(args.sync_to).resolve())

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
