"""Reports how much of the developer guide is implemented.

Reads CHECKLIST.md and counts ticked boxes per section. Only sections 1-9 are
counted towards the headline: they are the ones that map to the guide. The
blockers, the Stitch design and the out-of-guide features are reported
separately because they are not part of the specification.

    python scripts/progress.py
"""

from __future__ import annotations

import pathlib
import re
import sys

CHECKLIST = pathlib.Path(__file__).resolve().parent.parent / "CHECKLIST.md"

SECTION = re.compile(r"^## (.+)$")
BOX = re.compile(r"^\s*- \[([ x])\]")

# Sections 1-9 map onto the guide; the rest are ours.
GUIDE_SECTION = re.compile(r"^([1-9])\. ")


def main() -> int:
    if not CHECKLIST.exists():
        print(f"No checklist at {CHECKLIST}", file=sys.stderr)
        return 1

    sections: list[tuple[str, int, int]] = []
    name = "(preamble)"
    done = total = 0

    for line in CHECKLIST.read_text(encoding="utf-8").splitlines():
        heading = SECTION.match(line)
        if heading:
            sections.append((name, done, total))
            name, done, total = heading.group(1).strip(), 0, 0
            continue
        box = BOX.match(line)
        if box:
            total += 1
            done += box.group(1) == "x"
    sections.append((name, done, total))

    guide_done = guide_total = 0
    other_done = other_total = 0

    print(f"{'SECTION':<44} {'DONE':>9}   PROGRESS")
    print("-" * 78)

    for name, done, total in sections:
        if total == 0:
            continue
        is_guide = bool(GUIDE_SECTION.match(name))
        if is_guide:
            guide_done, guide_total = guide_done + done, guide_total + total
        else:
            other_done, other_total = other_done + done, other_total + total
        print(f"{name[:44]:<44} {f'{done}/{total}':>9}   {bar(done, total)}")

    print("-" * 78)
    print(
        f"{'GUIDE (sections 1-9)':<44} "
        f"{f'{guide_done}/{guide_total}':>9}   {bar(guide_done, guide_total)}"
    )
    print(
        f"{'Blockers, design and out-of-guide':<44} "
        f"{f'{other_done}/{other_total}':>9}   {bar(other_done, other_total)}"
    )
    return 0


def bar(done: int, total: int, width: int = 20) -> str:
    if total == 0:
        return "n/a"
    pct = done / total
    filled = round(pct * width)
    return f"[{'#' * filled}{'.' * (width - filled)}] {pct * 100:5.1f}%"


if __name__ == "__main__":
    raise SystemExit(main())
