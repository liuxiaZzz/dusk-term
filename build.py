#!/usr/bin/env python3
"""Build the Dusk iTerm2 themes.

Edit the palettes below, then run:  python3 build.py
Outputs (committed to the repo, so users don't need to run this):
  colors/Dusk Dark.itermcolors        dark
  colors/Dusk Light.itermcolors         light
  colors/Dusk Glass Light.itermcolors        light glass
  colors/Dusk Glass Dark.itermcolors  dark glass
  iterm/dusk.json              iTerm2 Dynamic Profiles (colors + transparency + font)
"""
import json
import os
import plistlib

HERE = os.path.dirname(os.path.abspath(__file__))

# ── Dusk Dark: dark, translucent, sapphire navy + pink ──
DUSK_DARK = {
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
    "Ansi 2 Color":  "#8fc4ff", "Ansi 10 Color": "#b3d7ff",   # "green" slot is blue (valid commands); typos use red = rose
    "Ansi 3 Color":  "#ffd4a3", "Ansi 11 Color": "#ffe3c2",
    "Ansi 4 Color":  "#7aa2ff", "Ansi 12 Color": "#9ebcff",
    "Ansi 5 Color":  "#ff8fd0", "Ansi 13 Color": "#ffb3e0",
    "Ansi 6 Color":  "#7fd4ff", "Ansi 14 Color": "#a6e3ff",
    "Ansi 7 Color":  "#dde3f5", "Ansi 15 Color": "#ffffff",
}

# ── Dusk Light: light, misty pink-grey + ink blue ──
# Light-theme convention: ANSI 0 is light and 7/15 are dark, so "white" text stays readable.
DUSK_LIGHT = {
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
    "Ansi 2 Color":  "#3b78b5", "Ansi 10 Color": "#5592c8",   # "green" slot is blue (valid commands); typos use red = rose
    "Ansi 3 Color":  "#c08a4a", "Ansi 11 Color": "#cf9a5c",
    "Ansi 4 Color":  "#4f6fb3", "Ansi 12 Color": "#6a87c4",
    "Ansi 5 Color":  "#d07aa6", "Ansi 13 Color": "#dc8fb6",
    "Ansi 6 Color":  "#4f8fb0", "Ansi 14 Color": "#6aa3c2",
    "Ansi 7 Color":  "#4a4d66", "Ansi 15 Color": "#3a3d55",
}

# ── Dusk Glass Light: light frosted glass (iOS-like): cool white, ink text, pink accents ──
DUSK_GLASS_LIGHT = {
    "Background Color":    "#f3f4fa",
    "Foreground Color":    "#1f2440",
    "Bold Color":          "#141833",
    "Cursor Color":        "#d0679a",
    "Cursor Text Color":   "#f3f4fa",
    "Cursor Guide Color":  "#a9bde6",
    "Selection Color":     "#f2c9dc",
    "Selected Text Color": "#141833",
    "Link Color":          "#3f63b8",
    "Badge Color":         "#e3a6c2",
    "Tab Color":           "#f3f4fa",
    "Ansi 0 Color":  "#e3e5ef", "Ansi 8 Color":  "#7f84a3",
    "Ansi 1 Color":  "#c2496a", "Ansi 9 Color":  "#d35c7c",
    "Ansi 2 Color":  "#2f72b0", "Ansi 10 Color": "#4b8cc6",
    "Ansi 3 Color":  "#b47a32", "Ansi 11 Color": "#c68b44",
    "Ansi 4 Color":  "#3f63b8", "Ansi 12 Color": "#5a7cc8",
    "Ansi 5 Color":  "#c4669c", "Ansi 13 Color": "#d47fae",
    "Ansi 6 Color":  "#2f7fa8", "Ansi 14 Color": "#4a95bb",
    "Ansi 7 Color":  "#3a3f5c", "Ansi 15 Color": "#1f2440",
}

# ── Dusk Glass Dark: dark frosted glass, deep sapphire smoke ──
DUSK_GLASS_DARK = {
    "Background Color":    "#0f1730",
    "Foreground Color":    "#f4f6ff",
    "Bold Color":          "#ffb3dc",
    "Cursor Color":        "#ff9fd2",
    "Cursor Text Color":   "#0f1730",
    "Cursor Guide Color":  "#7aa2ff",
    "Selection Color":     "#7a3a6c",
    "Selected Text Color": "#ffffff",
    "Link Color":          "#8cd8ff",
    "Badge Color":         "#ff9fd2",
    "Tab Color":           "#0f1730",
    "Ansi 0 Color":  "#1c2a52", "Ansi 8 Color":  "#6c7ca6",
    "Ansi 1 Color":  "#ff6a94", "Ansi 9 Color":  "#ff88ab",
    "Ansi 2 Color":  "#96c8ff", "Ansi 10 Color": "#b8dbff",
    "Ansi 3 Color":  "#ffd6a8", "Ansi 11 Color": "#ffe5c6",
    "Ansi 4 Color":  "#86abff", "Ansi 12 Color": "#a8c3ff",
    "Ansi 5 Color":  "#ff9fd2", "Ansi 13 Color": "#ffbce2",
    "Ansi 6 Color":  "#8cd8ff", "Ansi 14 Color": "#ade6ff",
    "Ansi 7 Color":  "#e2e7f8", "Ansi 15 Color": "#ffffff",
}

# glass look: see-through background, strong blur, solid colored blocks (prompt segments)
GLASS = {
    "Blur Radius": 30,
    "Only The Default BG Color Uses Transparency": True,
    "Minimum Contrast": 0.2,
    "Vertical Spacing": 1.15,
    "Use Tab Color": False,
}

# hostname watermark (iTerm2 badge): shows the user variable duskHost, set by the shell on ssh
BADGE = {
    "Badge Text": "\\(user.duskHost)",
    "Badge Font": "JetBrainsMonoNFM-Bold",
    "Badge Max Width": 0.25,
    "Badge Max Height": 0.08,
    "Badge Right Margin": 18,
    "Badge Top Margin": 12,
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
    ("Dusk Dark", "6f1c9e2a-5b7d-4c1e-9a3f-5a4b7c9e2d01", DUSK_DARK, {"Blur Radius": 24}),
    ("Dusk Light",  "3d7a1c52-8e4b-4f0a-b6d2-0d1a7e5c9f02", DUSK_LIGHT,  {"Blur Radius": 16}),
    ("Dusk Glass Light", "a4e1c7d2-2f6b-4c8a-9e3d-1b7f5a9c0e11", DUSK_GLASS_LIGHT, {**GLASS, "Transparency": 0.38}),
    ("Dusk Glass Dark", "b5f2d8e3-3a7c-4d9b-8f4e-2c8a6b0d1f22", DUSK_GLASS_DARK, {**GLASS, "Transparency": 0.42}),
]


def color(hexstr, alpha=1.0):
    h = hexstr.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return {"Red Component": r, "Green Component": g, "Blue Component": b,
            "Alpha Component": alpha, "Color Space": "sRGB"}


ALPHA = {"Cursor Guide Color": 0.3, "Badge Color": 0.22}


def colors_of(palette):
    return {k: color(v, ALPHA.get(k, 1.0)) for k, v in palette.items()}


def main():
    os.makedirs(os.path.join(HERE, "colors"), exist_ok=True)
    os.makedirs(os.path.join(HERE, "iterm"), exist_ok=True)
    profiles = []
    for name, guid, palette, extra in PROFILES:
        cols = colors_of(palette)
        with open(os.path.join(HERE, "colors", f"{name}.itermcolors"), "wb") as f:
            plistlib.dump(cols, f)
        profiles.append({"Name": name, "Guid": guid, **COMMON, **BADGE, **extra, **cols})
    with open(os.path.join(HERE, "iterm", "dusk.json"), "w") as f:
        json.dump({"Profiles": profiles}, f, indent=2)
    print("built colors/*.itermcolors and iterm/dusk.json")


if __name__ == "__main__":
    main()
