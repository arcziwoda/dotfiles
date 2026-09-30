#!/usr/bin/env python3
"""Render `tmux capture-pane -e -p` output (ANSI SGR) to a PNG.

Usage: render.py OUT.png [COLS] < capture.txt
Only the first COLS columns are drawn (the sidebar). Colours default to
Catppuccin Macchiato, matching Ghostty's theme.
"""
import os
import re
import sys
import unicodedata

from PIL import Image, ImageDraw, ImageFont

FONT_DIR = os.path.expanduser("~/Library/Fonts/")
SIZE = 28
REG = ImageFont.truetype(FONT_DIR + "JetBrainsMonoNerdFont-Regular.ttf", SIZE)
BOLD = ImageFont.truetype(FONT_DIR + "JetBrainsMonoNerdFont-Bold.ttf", SIZE)
FALLBACK = ImageFont.truetype("/System/Library/Fonts/Menlo.ttc", SIZE)

BG = (36, 39, 58)
FG = (202, 211, 245)
# Catppuccin Macchiato ANSI 0-15, as Ghostty's theme defines them.
ANSI = [
    (73, 77, 100), (237, 135, 150), (166, 218, 149), (238, 212, 159),
    (138, 173, 244), (245, 189, 230), (139, 213, 202), (184, 192, 224),
    (91, 96, 120), (237, 135, 150), (166, 218, 149), (238, 212, 159),
    (138, 173, 244), (245, 189, 230), (139, 213, 202), (165, 173, 203),
]


def xterm256(n):
    if n < 16:
        return ANSI[n]
    if n < 232:
        n -= 16
        steps = [0, 95, 135, 175, 215, 255]
        return (steps[n // 36], steps[(n // 6) % 6], steps[n % 6])
    v = 8 + (n - 232) * 10
    return (v, v, v)


def parse(text, cols):
    rows = []
    state = dict(fg=None, bg=None, bold=False, dim=False, rev=False)
    for line in text.split("\n"):
        cells = []
        i = 0
        while i < len(line) and len(cells) < cols:
            m = re.match(r"\x1b\[([0-9;:]*)m", line[i:])
            if m:
                apply(state, m.group(1))
                i += m.end()
                continue
            if line[i] == "\x1b":
                m = re.match(r"\x1b\[[0-9;?]*[A-Za-z]|\x1b\][^\x07]*\x07", line[i:])
                i += m.end() if m else 1
                continue
            ch = line[i]
            if unicodedata.category(ch) in ("Mn", "Me", "Cf"):
                i += 1  # zero-width: occupies no cell
                continue
            cells.append((ch, dict(state)))
            if unicodedata.east_asian_width(ch) in "WF":
                cells.append(("", dict(state)))
            i += 1
        rows.append(cells)
    return rows


def apply(state, params):
    parts = [int(p) if p else 0 for p in re.split(r"[;:]", params)] if params else [0]
    k = 0
    while k < len(parts):
        p = parts[k]
        if p == 0:
            state.update(fg=None, bg=None, bold=False, dim=False, rev=False)
        elif p == 1:
            state["bold"] = True
        elif p == 2:
            state["dim"] = True
        elif p == 22:
            state["bold"] = state["dim"] = False
        elif p == 7:
            state["rev"] = True
        elif p == 27:
            state["rev"] = False
        elif 30 <= p <= 37:
            state["fg"] = ANSI[p - 30]
        elif 90 <= p <= 97:
            state["fg"] = ANSI[p - 90 + 8]
        elif 40 <= p <= 47:
            state["bg"] = ANSI[p - 40]
        elif 100 <= p <= 107:
            state["bg"] = ANSI[p - 100 + 8]
        elif p == 39:
            state["fg"] = None
        elif p == 49:
            state["bg"] = None
        elif p in (38, 48) and k + 1 < len(parts):
            key = "fg" if p == 38 else "bg"
            if parts[k + 1] == 2 and k + 4 < len(parts):
                state[key] = tuple(parts[k + 2:k + 5])
                k += 4
            elif parts[k + 1] == 5 and k + 2 < len(parts):
                state[key] = xterm256(parts[k + 2])
                k += 2
        k += 1


def main():
    out = sys.argv[1]
    cols = int(sys.argv[2]) if len(sys.argv) > 2 else 200
    rows = parse(sys.stdin.read().rstrip("\n"), cols)
    cw = int(REG.getlength("M"))
    ch = int(SIZE * 1.35)
    img = Image.new("RGB", (cw * cols, ch * len(rows)), BG)
    d = ImageDraw.Draw(img)
    for y, cells in enumerate(rows):
        for x, (c, st) in enumerate(cells):
            fg = st["fg"] or FG
            bg = st["bg"]
            if st["rev"]:
                fg, bg = (bg or BG), fg
            if st["dim"]:
                base = bg or BG
                fg = tuple((a + b) // 2 for a, b in zip(fg, base))
            if bg:
                d.rectangle([x * cw, y * ch, (x + 1) * cw, (y + 1) * ch], fill=bg)
            if c.strip():
                font = BOLD if st["bold"] else REG
                if not font.getmask(c).getbbox():
                    font = FALLBACK
                d.text((x * cw, y * ch + (ch - SIZE) // 2), c, font=font, fill=fg)
    img.save(out)


if __name__ == "__main__":
    main()
