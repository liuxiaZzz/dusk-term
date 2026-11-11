#!/usr/bin/env python3
"""Draw docs/preview.svg from the palettes in build.py: the four themes in a 2x2 grid.
Glass themes are drawn semi-transparent over a soft wallpaper to hint at the frosted look."""
import html
import importlib.util
import os

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("build", os.path.join(HERE, "..", "build.py"))
b = importlib.util.module_from_spec(spec)
spec.loader.exec_module(b)

W, H, GAP, PAD = 520, 300, 24, 20
SEGMENTS = [("#e48bb4", "#f6f7fc", " "), ("#4a62ad", "#f6f7fc", "~/project"), ("#efc6db", "#18213f", " main"),
            ("#a3cbe6", "#18213f", "5.5G"), ("#1d2a4c", "#e9aecb", "41%")]


def term(x, y, name, p, opacity):
    a = lambda k: p[f"Ansi {k} Color"]
    fg = p["Foreground Color"]
    out = [f'<g transform="translate({x},{y})">',
           f'<rect width="{W}" height="{H}" rx="14" fill="{p["Background Color"]}" fill-opacity="{opacity}"/>',
           *[f'<circle cx="{22 + i * 20}" cy="20" r="6" fill="{c}"/>' for i, c in enumerate(("#ff5f57", "#febc2e", "#28c840"))],
           f'<text x="{W / 2}" y="25" text-anchor="middle" fill="{a(8)}" font-size="12">{name}</text>']
    cx, ty = PAD, 62
    for bg, tc, t in SEGMENTS:
        w = 14 + len(t) * 8
        out += [f'<rect x="{cx}" y="{ty - 15}" width="{w}" height="22" fill="{bg}"/>',
                f'<text x="{cx + 7}" y="{ty}" fill="{tc}">{html.escape(t)}</text>']
        cx += w
    lines = [
        [(a(5), "✻ "), (a(4), "Control Center "), (a(8), "下午好")],
        [(a(2), "❯ "), (fg, "ls -l")],
        [(a(8), "drwxr-xr-x  "), (a(4), "Documents/")],
        [(a(2), "❯ "), (fg, "git status")],
        [(a(2), "  new file:  theme.zsh")],
        [(a(1), "  modified:  README.md")],
        [(a(5), ">>> "), (fg, "print("), (a(3), '"hi"'), (fg, ")")],
    ]
    ty = 102
    for ln in lines:
        spans = "".join(f'<tspan fill="{c}">{html.escape(t)}</tspan>' for c, t in ln)
        out.append(f'<text x="{PAD}" y="{ty}" xml:space="preserve">{spans}</text>')
        ty += 26
    out.append(f'<text x="{PAD}" y="{ty}" fill="{a(2)}">❯</text>'
               f'<rect x="{PAD + 16}" y="{ty - 16}" width="2" height="18" fill="{p["Cursor Color"]}"/>')
    out.append("</g>")
    return "\n".join(out)


def main():
    tw, th = W * 2 + GAP * 3, H * 2 + GAP * 3
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{tw}" height="{th}" '
             f'font-family="JetBrains Mono, Menlo, monospace" font-size="14">',
             '<defs><linearGradient id="wall" x1="0" y1="0" x2="1" y2="1">'
             '<stop offset="0" stop-color="#a9bde6"/><stop offset="0.5" stop-color="#e8c4dc"/>'
             '<stop offset="1" stop-color="#7f8fd0"/></linearGradient></defs>',
             f'<rect width="{tw}" height="{th}" rx="18" fill="url(#wall)"/>',
             term(GAP, GAP, "Dusk Light", b.DUSK_LIGHT, 0.97),
             term(W + GAP * 2, GAP, "Dusk Dark", b.DUSK_DARK, 0.97),
             term(GAP, H + GAP * 2, "Dusk Glass Light", b.DUSK_GLASS_LIGHT, 0.72),
             term(W + GAP * 2, H + GAP * 2, "Dusk Glass Dark", b.DUSK_GLASS_DARK, 0.80),
             "</svg>"]
    with open(os.path.join(HERE, "preview.svg"), "w") as f:
        f.write("\n".join(parts))
    print("wrote docs/preview.svg")


if __name__ == "__main__":
    main()
