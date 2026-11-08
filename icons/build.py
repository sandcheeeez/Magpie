#!/usr/bin/env python3
"""Builds Stash's icons from one palette (same method as the Home dashboard and Vehicles icons).

    python3 icons/build.py               # clipboard concept, ocean palette (Dylan's pick)
    python3 icons/build.py lagoon        # another palette from PALETTES

Outputs, all in Magpie/Resources/Assets.xcassets:
  AppIcon.appiconset/{16..1024}.png       app icon: the logo on a dark macOS-grid tile
  BetaAppIcon.appiconset/{16..1024}.png   same in the beta palette, to tell the builds apart
  MagpieIconColored.imageset/appstore.png the icon shown in the About, Welcome and Help windows
  StatusIcon.imageset/status.svg          menu bar icon: same shapes, one colour, template image
PNGs are rendered with headless Chrome, then resized with sips. Design history: design/concepts.py.
"""
import pathlib, subprocess, sys, tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
ASSETS = ROOT / "Magpie" / "Resources" / "Assets.xcassets"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

PALETTES = {  # gradient stops, top → bottom
    "ocean": ["#22d3ee", "#6366f1"],
    "lagoon": ["#38bdf8", "#14b8a6"],
    "dusk": ["#f97316", "#a855f7"],
    "ember": ["#f59e0b", "#ef4444"],
}
BETA_PALETTE = "ember"
HUB = "#22c55e"  # green "status light"
TILE = "#16161b"

# Clipboard: board and clip (bold), text lines (details); the status ring is the clip's hole.
BOARD = "M196 132 H164 Q132 132 132 164 V388 Q132 420 164 420 H348 Q380 420 380 388 V164 Q380 132 348 132 H316"
LINES = "M188 262 H324 M188 318 H324 M188 374 H272"
HUB_CENTER = (256, 132)


def logo(stops, gid):
    n = len(stops) - 1
    st = "".join(f'<stop offset="{i / n:.2f}" stop-color="{c}"/>' for i, c in enumerate(stops))
    hx, hy = HUB_CENTER
    # Hub is a ring (not a disc with a background-coloured hole) so it works on any background.
    return (f'<defs><linearGradient id="{gid}" x1="0" y1="100" x2="0" y2="420" gradientUnits="userSpaceOnUse">{st}'
            f'</linearGradient></defs>'
            f'<g fill="none" stroke="url(#{gid})" stroke-linecap="round" stroke-linejoin="round">'
            f'<path d="{LINES}" stroke-width="22" opacity=".75"/><path d="{BOARD}" stroke-width="44"/></g>'
            f'<circle cx="{hx}" cy="{hy}" r="28" fill="none" stroke="{HUB}" stroke-width="24"/>')


def app_icon(stops):
    """1024 canvas with an 824 pt rounded tile, per the macOS icon grid, and a soft drop shadow."""
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">'
            '<defs><filter id="s" x="-20%" y="-20%" width="140%" height="140%">'
            '<feDropShadow dx="0" dy="10" stdDeviation="12" flood-opacity=".35"/></filter></defs>'
            f'<rect x="100" y="100" width="824" height="824" rx="186" fill="{TILE}" filter="url(#s)"/>'
            f'<g transform="translate(100 100) scale({824 / 512})">{logo(stops, "g")}</g></svg>')


def status_icon():
    """Template image: black on transparent (macOS tints it), strokes close to SF Symbols' regular weight at 18 pt."""
    hx, hy = HUB_CENTER
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="70 76 372 372">'
            '<g fill="none" stroke="#000" stroke-linecap="round" stroke-linejoin="round">'
            f'<path d="{LINES}" stroke-width="24"/><path d="{BOARD}" stroke-width="32"/>'
            f'<circle cx="{hx}" cy="{hy}" r="26" stroke-width="24"/></g></svg>\n')


def render_png(svg, out, size=1024):
    with tempfile.TemporaryDirectory() as tmp:
        page = pathlib.Path(tmp, "icon.html")
        page.write_text('<!doctype html><style>html,body{margin:0;background:transparent}'
                        f'svg{{display:block;width:{size}px;height:{size}px}}</style>' + svg)
        subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--default-background-color=00000000",
                        "--force-device-scale-factor=1", f"--window-size={size},{size}", f"--screenshot={out}", page.as_uri()],
                       check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def build_iconset(folder, stops):
    big = folder / "1024.png"
    render_png(app_icon(stops), big)
    for size in (16, 32, 64, 128, 256, 512):
        subprocess.run(["sips", "-z", str(size), str(size), str(big), "--out", str(folder / f"{size}.png")],
                       check=True, stdout=subprocess.DEVNULL)


def main():
    name = sys.argv[1] if len(sys.argv) > 1 else "ocean"
    build_iconset(ASSETS / "AppIcon.appiconset", PALETTES[name])
    build_iconset(ASSETS / "BetaAppIcon.appiconset", PALETTES[BETA_PALETTE])
    render_png(app_icon(PALETTES[name]), ASSETS / "MagpieIconColored.imageset" / "appstore.png")

    status = ASSETS / "StatusIcon.imageset"
    status.mkdir(exist_ok=True)
    (status / "status.svg").write_text(status_icon())
    (status / "Contents.json").write_text(
        '{\n  "images" : [ { "filename" : "status.svg", "idiom" : "universal" } ],\n'
        '  "info" : { "author" : "xcode", "version" : 1 },\n'
        '  "properties" : { "preserves-vector-representation" : true, "template-rendering-intent" : "template" }\n}\n')
    print(f"icons built: palette={name}, beta={BETA_PALETTE}")


if __name__ == "__main__":
    main()
