#!/usr/bin/env python3
"""Build the Sakura Term iTerm2 themes.

Edit the palettes below, then run:  python3 build.py
Outputs (committed to the repo, so users don't need to run this):
  colors/Sakura Glass.itermcolors     dark color preset
  colors/Mist Sakura.itermcolors      light color preset
  iterm/sakura-term.json              iTerm2 Dynamic Profiles (colors + transparency + font)
"""
import json
import os
import plistlib

HERE = os.path.dirname(os.path.abspath(__file__))

# ── Sakura Glass: dark, translucent, sapphire navy + sakura pink ──
SAKURA_GLASS = {
    "Background Color":    "#0b1734",
    "Foreground Color":    "#f2f5ff",
    "Bold Color":          "#ff9fd6",
    "Cursor Color":        "#ff8fd0",
    "Cursor Text Color":   "#0b1734",
    "Cursor Guide Color":  "#7aa2ff",
    "Selection Color":     "#8a3a72",
    "Selected Text Color": "#ffffff",
    "Link Color":          "#7fd4ff",
    "Badge Color":         "#ff8fd0",
    "Tab Color":           "#0b1734",
    "Ansi 0 Color":  "#1a2a52", "Ansi 8 Color":  "#5f7099",
    "Ansi 1 Color":  "#ff5c8a", "Ansi 9 Color":  "#ff7fa6",
    "Ansi 2 Color":  "#ffa6cf", "Ansi 10 Color": "#ffc4e1",   # "green" slot is sakura pink
    "Ansi 3 Color":  "#ffd4a3", "Ansi 11 Color": "#ffe3c2",
    "Ansi 4 Color":  "#7aa2ff", "Ansi 12 Color": "#9ebcff",
    "Ansi 5 Color":  "#ff8fd0", "Ansi 13 Color": "#ffb3e0",
    "Ansi 6 Color":  "#7fd4ff", "Ansi 14 Color": "#a6e3ff",
    "Ansi 7 Color":  "#dde3f5", "Ansi 15 Color": "#ffffff",
}

# ── Mist Sakura: light, misty pink-grey + ink blue ──
# Light-theme convention: ANSI 0 is light and 7/15 are dark, so "white" text stays readable.
MIST_SAKURA = {
    "Background Color":    "#e8e4e8",
    "Foreground Color":    "#363950",
    "Bold Color":          "#2a2d45",
    "Cursor Color":        "#c9628f",
    "Cursor Text Color":   "#e8e4e8",
    "Cursor Guide Color":  "#a9bde6",
    "Selection Color":     "#e6c8d6",
    "Selected Text Color": "#2a2d45",
    "Link Color":          "#4f6fb3",
    "Badge Color":         "#e3a6c2",
    "Tab Color":           "#e8e4e8",
    "Ansi 0 Color":  "#dbd4da", "Ansi 8 Color":  "#9a98ad",
    "Ansi 1 Color":  "#c4566e", "Ansi 9 Color":  "#d46a82",
    "Ansi 2 Color":  "#c9628f", "Ansi 10 Color": "#d77ea3",   # "green" slot is sakura pink
    "Ansi 3 Color":  "#c08a4a", "Ansi 11 Color": "#cf9a5c",
    "Ansi 4 Color":  "#4f6fb3", "Ansi 12 Color": "#6a87c4",
    "Ansi 5 Color":  "#d07aa6", "Ansi 13 Color": "#dc8fb6",
    "Ansi 6 Color":  "#4f8fb0", "Ansi 14 Color": "#6aa3c2",
    "Ansi 7 Color":  "#4a4d66", "Ansi 15 Color": "#3a3d55",
}

COMMON = {
    "Transparency": 0.05,
    "Blur": True,
    "Background Image Location": "",
    "Normal Font": "JetBrainsMonoNFM-Regular 14",   # Nerd Font: needed for prompt icons
    "Use Bold Font": True,
    "Use Bright Bold": True,
    "Cursor Type": 1,                                # vertical bar
    "Blinking Cursor": True,
    "Vertical Spacing": 1.1,
    "Unlimited Scrollback": True,
    "Use Separate Colors for Light and Dark Mode": False,
    "Use Tab Color": True,
}

PROFILES = [
    ("Sakura Glass", "6f1c9e2a-5b7d-4c1e-9a3f-5a4b7c9e2d01", SAKURA_GLASS, {"Blur Radius": 24}),
    ("Mist Sakura",  "3d7a1c52-8e4b-4f0a-b6d2-0d1a7e5c9f02", MIST_SAKURA,  {"Blur Radius": 16}),
]


def color(hexstr, alpha=1.0):
    h = hexstr.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return {"Red Component": r, "Green Component": g, "Blue Component": b,
            "Alpha Component": alpha, "Color Space": "sRGB"}


def colors_of(palette):
    return {k: color(v, 0.3 if k == "Cursor Guide Color" else 1.0) for k, v in palette.items()}


def main():
    os.makedirs(os.path.join(HERE, "colors"), exist_ok=True)
    os.makedirs(os.path.join(HERE, "iterm"), exist_ok=True)
    profiles = []
    for name, guid, palette, extra in PROFILES:
        cols = colors_of(palette)
        with open(os.path.join(HERE, "colors", f"{name}.itermcolors"), "wb") as f:
            plistlib.dump(cols, f)
        profiles.append({"Name": name, "Guid": guid, **COMMON, **extra, **cols})
    with open(os.path.join(HERE, "iterm", "sakura-term.json"), "w") as f:
        json.dump({"Profiles": profiles}, f, indent=2)
    print("built colors/*.itermcolors and iterm/sakura-term.json")


if __name__ == "__main__":
    main()
