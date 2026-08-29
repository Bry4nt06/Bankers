#!/usr/bin/env python3
"""Export a compact, reviewable hierarchy/script audit from a Roblox .rbxlx/XML place.

Usage:
    python scripts/export_rbxlx_audit.py TheTakeAudit.xml audit

Outputs:
    audit/TheTakeHierarchy.txt
    audit/TheTakeScripts.txt
    audit/TheTakeCandidates.txt

The parser streams the XML so a very large .rbxlx file does not need to be loaded
fully into memory. Geometry-heavy leaf classes are omitted from the hierarchy
report unless they are near the root; scripts are always included.
"""

from __future__ import annotations

import argparse
import html
import os
import re
import xml.etree.ElementTree as ET
from pathlib import Path

SCRIPT_CLASSES = {"Script", "LocalScript", "ModuleScript"}

# These classes create most of the XML size but usually do not help identify
# menu/intro ownership or gameplay-system boundaries.
NOISY_GEOMETRY_CLASSES = {
    "Part",
    "MeshPart",
    "UnionOperation",
    "WedgePart",
    "CornerWedgePart",
    "TrussPart",
    "Seat",
    "VehicleSeat",
    "SpawnLocation",
    "Attachment",
    "Bone",
    "Decal",
    "Texture",
    "SurfaceAppearance",
    "SpecialMesh",
    "BlockMesh",
    "CylinderMesh",
    "FileMesh",
    "PointLight",
    "SpotLight",
    "SurfaceLight",
    "ParticleEmitter",
    "Trail",
    "Beam",
    "Smoke",
    "Fire",
    "Sparkles",
    "Sound",
    "Weld",
    "WeldConstraint",
    "Motor6D",
    "Motor",
    "ManualWeld",
    "Snap",
    "Glue",
    "NoCollisionConstraint",
    "BallSocketConstraint",
    "HingeConstraint",
    "RopeConstraint",
    "RodConstraint",
    "SpringConstraint",
    "PrismaticConstraint",
    "CylindricalConstraint",
    "AlignPosition",
    "AlignOrientation",
    "LinearVelocity",
    "AngularVelocity",
    "VectorForce",
    "BodyPosition",
    "BodyVelocity",
    "BodyGyro",
    "BodyForce",
    "BodyAngularVelocity",
    "BodyThrust",
}

CANDIDATE_RE = re.compile(
    r"(?:broken|intro|opening|starter|startscene|menu|mainmenu|lobby|title|splash|camera|"
    r"spawnplayer|spawn|maploader|maptimer|mapname|mapcreator|weapon|loadout|shop|round|vote)",
    re.IGNORECASE,
)


def local_tag(tag: str) -> str:
    if "}" in tag:
        return tag.rsplit("}", 1)[1]
    return tag


def safe_text(value: str | None) -> str:
    return value or ""


def path_for(stack: list[dict[str, str]]) -> str:
    names = []
    for frame in stack:
        name = frame.get("name") or f"<{frame.get('class', 'Item')}>"
        names.append(name.replace("\n", " ").replace("\r", " "))
    return ".".join(names)


def should_emit_hierarchy(class_name: str, depth: int) -> bool:
    if depth <= 2:
        return True
    if class_name in SCRIPT_CLASSES:
        return True
    return class_name not in NOISY_GEOMETRY_CLASSES


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", help="Path to TheTakeAudit.xml / .rbxlx")
    parser.add_argument("output_dir", nargs="?", default="audit")
    args = parser.parse_args()

    input_path = Path(args.input)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    hierarchy_path = output_dir / "TheTakeHierarchy.txt"
    scripts_path = output_dir / "TheTakeScripts.txt"
    candidates_path = output_dir / "TheTakeCandidates.txt"

    stack: list[dict[str, str]] = []
    item_count = 0
    script_count = 0
    hierarchy_count = 0
    candidate_count = 0

    with hierarchy_path.open("w", encoding="utf-8", newline="\n") as hierarchy_out, \
         scripts_path.open("w", encoding="utf-8", newline="\n") as scripts_out, \
         candidates_path.open("w", encoding="utf-8", newline="\n") as candidates_out:

        hierarchy_out.write("# THE TAKE Roblox hierarchy audit\n")
        hierarchy_out.write(f"# Source: {input_path.name}\n")
        hierarchy_out.write("# Geometry-heavy leaf instances are intentionally omitted.\n\n")

        scripts_out.write("# THE TAKE Roblox script-source audit\n")
        scripts_out.write(f"# Source: {input_path.name}\n\n")

        candidates_out.write("# THE TAKE likely menu/intro/gameplay-boundary candidates\n")
        candidates_out.write(f"# Source: {input_path.name}\n\n")

        # start/end streaming keeps memory bounded. Roblox Item Properties occur
        # before child Items in normal rbxlx output, so parent names are known as
        # descendants are traversed.
        for event, elem in ET.iterparse(input_path, events=("start", "end")):
            tag = local_tag(elem.tag)

            if event == "start" and tag == "Item":
                stack.append({
                    "class": elem.attrib.get("class", "Item"),
                    "name": "",
                    "source": "",
                })
                continue

            if event != "end":
                continue

            if stack and elem.attrib.get("name") == "Name":
                # Roblox normally serializes Name as <string name="Name">.
                stack[-1]["name"] = safe_text(elem.text)

            if stack and elem.attrib.get("name") == "Source":
                # Script.Source is typically ProtectedString but we intentionally
                # key on the property name rather than the XML element type.
                stack[-1]["source"] = safe_text(elem.text)

            if tag == "Item" and stack:
                item_count += 1
                frame = stack[-1]
                class_name = frame.get("class", "Item")
                depth = len(stack) - 1
                obj_path = path_for(stack)
                source = frame.get("source", "")

                if should_emit_hierarchy(class_name, depth):
                    hierarchy_out.write(f"{depth:02d}\t{class_name}\t{obj_path}\n")
                    hierarchy_count += 1

                if class_name in SCRIPT_CLASSES:
                    script_count += 1
                    scripts_out.write("=" * 100 + "\n")
                    scripts_out.write(f"PATH: {obj_path}\n")
                    scripts_out.write(f"CLASS: {class_name}\n")
                    scripts_out.write("-" * 100 + "\n")
                    scripts_out.write(source)
                    if source and not source.endswith("\n"):
                        scripts_out.write("\n")
                    scripts_out.write("\n")

                candidate_blob = f"{class_name} {obj_path} {source[:4000]}"
                if CANDIDATE_RE.search(candidate_blob):
                    candidates_out.write(f"{class_name}\t{obj_path}\n")
                    if class_name in SCRIPT_CLASSES and source:
                        # Include only compact matching source lines here. Full
                        # script text remains available in TheTakeScripts.txt.
                        for line_no, line in enumerate(source.splitlines(), 1):
                            if CANDIDATE_RE.search(line):
                                trimmed = line.strip()
                                if len(trimmed) > 500:
                                    trimmed = trimmed[:500] + " ..."
                                candidates_out.write(f"    L{line_no}: {trimmed}\n")
                    candidates_out.write("\n")
                    candidate_count += 1

                stack.pop()
                elem.clear()

    print(f"[TheTakeAudit] parsed items: {item_count:,}")
    print(f"[TheTakeAudit] hierarchy lines: {hierarchy_count:,}")
    print(f"[TheTakeAudit] scripts: {script_count:,}")
    print(f"[TheTakeAudit] candidates: {candidate_count:,}")
    for path in (hierarchy_path, scripts_path, candidates_path):
        size_mb = path.stat().st_size / (1024 * 1024)
        print(f"[TheTakeAudit] wrote {path} ({size_mb:.2f} MB)")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
