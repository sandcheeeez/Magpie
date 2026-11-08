#!/usr/bin/env python3
"""App icon concepts in the Home dashboard / Vehicles style: one gradient stroke (44 px outline +
22 px details at .75 opacity, round caps/joins) and a green status ring, on a dark tile. The menu bar
version uses the same shapes in a single colour (a template image), with strokes close to SF Symbols' regular weight at 18 pt. Writes concepts.html + concepts.png (rendered with headless Chrome)."""
import pathlib, subprocess

OUT = pathlib.Path(__file__).parent
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
GREEN = "#22c55e"
DARK = "#16161b"

# name: (bold strokes, detail strokes, hub center, gradient y-range)
CONCEPTS = {
    "clipboard": (  # board + clip; status ring is the clip's hole
        "M196 132 H164 Q132 132 132 164 V388 Q132 420 164 420 H348 Q380 420 380 388 V164 Q380 132 348 132 H316",
        "M188 262 H324 M188 318 H324 M188 374 H272",
        (256, 132), (100, 420)),
    "stack": (  # history: a card in front of the ones before it
        "M128 220 Q128 196 152 196 H336 Q360 196 360 220 V380 Q360 404 336 404 H152 Q128 404 128 380 Z",
        "M176 148 H360 Q384 148 384 172 V332 M224 100 H384 Q408 100 432 124 M168 270 H284 M168 330 H244",
        (316, 330), (100, 404)),
    "rewind": (  # history: a clock face that loops back on itself
        "M256 112 A144 144 0 1 1 132 184 M108 150 L132 184 L172 172",
        "M256 180 V256",
        (256, 256), (112, 400)),
    "keyhole": (  # privacy: clipboard whose clip is a lock shackle
        "M164 196 Q132 196 132 228 V388 Q132 420 164 420 H348 Q380 420 380 388 V228 Q380 196 348 196 Z "
        "M196 196 V156 A60 60 0 0 1 316 156 V196",
        "M256 338 V372",
        (256, 300), (96, 420)),
}
PALETTES = {  # top → bottom
    "dusk (Home)": ["#f97316", "#a855f7"],
    "ember (Vehicles)": ["#f59e0b", "#ef4444"],
    "ocean": ["#22d3ee", "#6366f1"],
    "lagoon": ["#38bdf8", "#14b8a6"],
}


def svg(concept, stops, gid, bg=DARK):
    bold, detail, (hx, hy), (y1, y2) = CONCEPTS[concept]
    n = len(stops) - 1
    st = "".join(f'<stop offset="{i / n:.2f}" stop-color="{c}"/>' for i, c in enumerate(stops))
    rect = f'<rect width="512" height="512" rx="112" fill="{bg}"/>' if bg else ""
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">{rect}'
            f'<defs><linearGradient id="{gid}" x1="0" y1="{y1}" x2="0" y2="{y2}" gradientUnits="userSpaceOnUse">{st}'
            f'</linearGradient></defs><g fill="none" stroke="url(#{gid})" stroke-linecap="round" stroke-linejoin="round">'
            f'<path d="{detail}" stroke-width="22" opacity=".75"/><path d="{bold}" stroke-width="44"/></g>'
            f'<circle cx="{hx}" cy="{hy}" r="28" fill="none" stroke="{GREEN}" stroke-width="24"/></svg>')


def menubar(concept, color):
    """Single colour, thicker strokes, cropped to the shape, like a template image."""
    bold, detail, (hx, hy), _ = CONCEPTS[concept]
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="72 56 368 400"><g fill="none" stroke="{color}" '
            f'stroke-linecap="round" stroke-linejoin="round"><path d="{detail}" stroke-width="24"/>'
            f'<path d="{bold}" stroke-width="32"/><circle cx="{hx}" cy="{hy}" r="26" stroke-width="24"/></g></svg>')


rows = []
for p, (pname, stops) in enumerate(PALETTES.items()):
    cells = "".join(f'<figure><div class="tile">{svg(c, stops, f"g{p}{c}")}</div></figure>' for c in CONCEPTS)
    rows.append(f'<div class="row"><div class="pal"><i style="background:linear-gradient(90deg,{",".join(stops)})"></i>'
                f'{pname}</div>{cells}</div>')

bars = []
for mode, bg, fg in (("light menu bar", "#ececec", "#1d1d1f"), ("dark menu bar", "#2a2a2e", "#f5f5f7")):
    cells = "".join(f'<figure><div class="bar" style="background:{bg}">'
                    f'<span class="sym">{menubar(c, fg)}</span><span class="sym big">{menubar(c, fg)}</span></div></figure>'
                    for c in CONCEPTS)
    bars.append(f'<div class="row"><div class="pal">{mode}<br><small>18 pt · 2× zoom</small></div>{cells}</div>')

head = "".join(f"<b>{c}</b>" for c in CONCEPTS)
html = f'''<!doctype html><style>
body{{margin:0;padding:24px;background:linear-gradient(160deg,#20222f,#0b0b10);font:600 14px -apple-system,system-ui;color:#ddd;width:max-content}}
.row,.head{{display:grid;grid-template-columns:130px repeat({len(CONCEPTS)},150px);gap:18px;align-items:center;margin-bottom:14px}}
.head b{{text-align:center;font-size:16px}} figure{{margin:0;display:flex;justify-content:center}}
.tile svg{{width:128px;height:128px;display:block;filter:drop-shadow(0 6px 14px rgba(0,0,0,.45))}}
.pal i{{display:block;width:90px;height:8px;border-radius:4px;margin-bottom:6px}} small{{color:#999;font-weight:500}}
.bar{{display:flex;gap:18px;align-items:center;justify-content:center;width:150px;height:56px;border-radius:10px}}
.sym svg{{width:18px;height:18px;display:block}} .big svg{{width:36px;height:36px}}
h2{{font-size:13px;color:#999;margin:22px 0 10px;text-transform:uppercase;letter-spacing:.06em}}
</style><div class="head"><span></span>{head}</div>{"".join(rows)}<h2>Menu bar (no colour)</h2>{"".join(bars)}'''
(OUT / "concepts.html").write_text(html)
subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=2",
                "--window-size=840,1000", f"--screenshot={OUT / 'concepts.png'}", (OUT / "concepts.html").as_uri()],
               check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
print("wrote", OUT / "concepts.png")
