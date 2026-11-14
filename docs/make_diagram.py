#!/usr/bin/env python3
"""Generates the pipeline overview as Excalidraw JSON.
Writes pipeline.excalidraw (File > Open) and clipboard.json (paste into a canvas)."""
import json, random, pathlib

random.seed(7)
els = []
FONT = 5  # Excalifont
COL = {
    "blue": "#a5d8ff", "green": "#b2f2bb", "yellow": "#ffec99", "purple": "#d0bfff",
    "gray": "#e9ecef", "orange": "#ffd8a8", "red": "#ffc9c9", "done": "#8ce99a", "none": "transparent",
}


def base(t, x, y, w, h, **kw):
    e = dict(id=f"{t}{len(els)}", type=t, x=x, y=y, width=w, height=h, angle=0,
             strokeColor="#1e1e1e", backgroundColor="transparent", fillStyle="solid",
             strokeWidth=2, strokeStyle="solid", roughness=1, opacity=100, groupIds=[],
             frameId=None, roundness=None, seed=random.randint(1, 2**31), version=1,
             versionNonce=random.randint(1, 2**31), isDeleted=False, boundElements=[],
             updated=1, link=None, locked=False)
    e.update(kw)
    els.append(e)
    return e


def text(s, x, y, size=16, container=None, align="left", color="#1e1e1e"):
    lines = s.split("\n")
    w = max(len(l) for l in lines) * size * 0.55
    h = len(lines) * size * 1.25
    if container:  # center inside the container (or on the arrow midpoint)
        cx, cy = x, y
        x, y = cx - w / 2, cy - h / 2
    t = base("text", x, y, w, h, text=s, originalText=s, fontSize=size, fontFamily=FONT,
             textAlign="center" if container else align, verticalAlign="middle",
             containerId=container["id"] if container else None, lineHeight=1.25,
             autoResize=True, strokeColor=color)
    if container:
        container["boundElements"].append({"type": "text", "id": t["id"]})
    return t


def box(s, x, y, w, h, bg, size=16, dashed=False, shape="rectangle"):
    r = base(shape, x, y, w, h, backgroundColor=COL[bg], roundness={"type": 3},
             strokeStyle="dashed" if dashed else "solid")
    if s:
        text(s, x + w / 2, y + h / 2, size, container=r)
    return r


def arrow(a, b, pts, label=None, dashed=False):
    """pts: absolute points; first touches a, last touches b."""
    x0, y0 = pts[0]
    ar = base("arrow", x0, y0,
              max(p[0] for p in pts) - min(p[0] for p in pts),
              max(p[1] for p in pts) - min(p[1] for p in pts),
              points=[[px - x0, py - y0] for px, py in pts], roundness={"type": 2},
              strokeStyle="dashed" if dashed else "solid",
              startBinding={"elementId": a["id"], "focus": 0, "gap": 6},
              endBinding={"elementId": b["id"], "focus": 0, "gap": 6},
              startArrowhead=None, endArrowhead="arrow", lastCommittedPoint=None, elbowed=False)
    a["boundElements"].append({"type": "arrow", "id": ar["id"]})
    b["boundElements"].append({"type": "arrow", "id": ar["id"]})
    if label:
        mid = pts[len(pts) // 2] if len(pts) > 2 else ((pts[0][0] + pts[1][0]) / 2, (pts[0][1] + pts[1][1]) / 2)
        text(label, mid[0], mid[1], 14, container=ar)
    return ar


def band(title, x, y, w, h, bg):
    base("rectangle", x, y, w, h, backgroundColor=COL[bg], opacity=25, strokeStyle="dashed",
         roundness={"type": 3}, strokeWidth=1)
    text(title, x + 14, y + 10, 20)


# ---------- header ----------
text("Smart Dev pipeline — overview", 40, 10, 36)
box("RULES:  1 stage = 1 fresh session   ·   hand off through FILES, not chat   ·   keep context under 40%"
    "   ·   commit on every green test   ·   new ideas go to PARKED, never into the current session",
    40, 70, 1620, 60, "gray", 17)

# ---------- once per project ----------
band("ONCE PER PROJECT (revisit rarely)", 40, 160, 840, 270, "blue")
s1 = box("SESSION · EXPLORE\nproblem, users, codebase,\nconstraints, risks\n\n→ writes docs/explore.md",
         70, 210, 340, 180, "blue")
s2 = box("SESSION · USER STORIES\nstories + acceptance criteria\n+ explicit NON-GOALS\n\n→ backlog cards + non-goals",
         510, 210, 340, 180, "blue")
arrow(s1, s2, [(416, 300), (504, 300)], "explore.md")

fast = box("FAST LANE\nsmall bug fix / tweak\nskips explore, stories, spec", 930, 240, 330, 120, "orange")
text("scale the process to the task", 950, 370, 14, color="#868e96")

# ---------- per story loop ----------
band("PER STORY — LOOP until backlog is empty", 40, 470, 1250, 320, "green")
s3 = box("SESSION · SPEC\nminimal spec for ONE story\n\n→ card's Implementation Plan", 70, 530, 270, 180, "green")
s4 = box("SESSION · BUILD (TDD)\nred → green → refactor\ncommit on every green test\n\n→ code + tests + commits",
         400, 530, 310, 180, "green")
s5 = box("SESSION · REVIEW\nfresh eyes: code vs spec\n+ acceptance criteria\n\n→ pass / list of fixes",
         770, 530, 280, 180, "yellow")
done = box("DONE ✓\ncard → Done", 1110, 575, 160, 90, "done", shape="ellipse")

arrow(s2, s3, [(680, 396), (205, 524)], "pick next story")
arrow(fast, s4, [(1095, 366), (600, 524)], "straight to build", dashed=True)
arrow(s3, s4, [(346, 620), (394, 620)])
arrow(s4, s5, [(716, 620), (764, 620)])
arrow(s5, done, [(1056, 620), (1104, 620)], "pass")
arrow(s5, s4, [(910, 716), (910, 745), (555, 745), (555, 716)], "fail → fixes")
arrow(done, s3, [(1190, 671), (1190, 770), (205, 770), (205, 716)], "next story")

# ---------- board ----------
band("BACKLOG.MD BOARD (in repo)", 1320, 470, 340, 320, "gray")
for i, c in enumerate(["To Do", "Doing", "Review", "Done", "Parked"]):
    box(c, 1335 + i * 64, 520, 58, 170, "orange" if c == "Parked" else "none", 12)
text("you: backlog browser (web)\n       backlog board (terminal)\nClaude: backlog CLI", 1340, 705, 14)

# ---------- session lifecycle ----------
band("EVERY SESSION — LIFECYCLE", 40, 830, 1250, 270, "purple")
l1 = box("SESSION START\nhook injects .smartdev/STATE.md\n(~200 tokens, only in\npipeline projects)", 70, 880, 270, 150, "purple")
l2 = box("WORK ONE STAGE\n/smartdev:start rules\nfresh context", 390, 880, 250, 150, "purple")
l3 = box("CONTEXT WATCH\nstatus line: yellow at 30%\nred at 40% → hand off now", 690, 880, 260, 150, "red")
l4 = box("WRAP UP\n→ smartdev:handoff\nupdates STATE.md · moves card\n· 1 line in project log", 1000, 880, 270, 150, "purple")
arrow(l1, l2, [(346, 955), (384, 955)])
arrow(l2, l3, [(646, 955), (684, 955)])
arrow(l3, l4, [(956, 955), (994, 955)])
arrow(l4, l1, [(1135, 1036), (1135, 1075), (205, 1075), (205, 1036)], "next session (days or months later)")

# ---------- artifacts ----------
band("PERSISTENT FILES = the real handoff", 1320, 830, 340, 270, "gray")
text(".smartdev/STATE.md\n   stage · current story · next step\n   · blockers (≤15 lines)\n"
     "docs/explore.md  (+ non-goals)\nbacklog/tasks/  (cards: story,\n   criteria, spec, notes)\n\n"
     ".smartdev/log.md  (1 line/session)\n\nterminal: smartdev\n   all projects: stage · task · date", 1335, 870, 14)

# self-check: every binding / container points at a real element
ids = {e["id"] for e in els}
for e in els:
    for k in ("startBinding", "endBinding"):
        if e.get(k):
            assert e[k]["elementId"] in ids, e
    assert e.get("containerId") in ids | {None}, e
    for b in e["boundElements"]:
        assert b["id"] in ids, e

out = pathlib.Path(__file__).parent
(out / "pipeline.excalidraw").write_text(json.dumps(
    {"type": "excalidraw", "version": 2, "source": "https://excalidraw.com", "elements": els,
     "appState": {"viewBackgroundColor": "#ffffff", "gridSize": None}, "files": {}}, ensure_ascii=False))
(out / "clipboard.json").write_text(json.dumps(
    {"type": "excalidraw/clipboard", "elements": els, "files": {}}, ensure_ascii=False))
print(f"{len(els)} elements written")
