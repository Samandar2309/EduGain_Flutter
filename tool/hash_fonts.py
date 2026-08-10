"""Give the icon font a content-addressed filename after a web build.

Flutter's web output is not hashed: `assets/fonts/MaterialIcons-Regular.otf`
keeps that path forever while its CONTENTS are rebuilt on every build, because
tree-shaking regenerates it from exactly the icons the app currently uses.

A client that cached it from an earlier build therefore holds a font missing the
glyphs the new bundle asks for, and the result is not a broken page — it is SOME
icons drawing and others coming out as empty circles, which looks like a design
bug and is nearly impossible to reason about from the outside. It cost this
project four wrong diagnoses.

`Cache-Control: no-cache` on the path fixes it going forward, but cannot help a
client that already cached the old file under the old policy. A new filename
can: nothing has it cached, so there is nothing stale to serve.

It also reinstalls the service-worker tombstone, because that has to happen
after every build too and a second manual step is a step that gets skipped —
this one already was. `--pwa-strategy=none` does not leave the worker alone: it
writes an EMPTY `flutter_service_worker.js` over whatever was there, and an
empty worker does not unregister the caching worker that devices already have.

Run after `flutter build web`:

    python tool/hash_fonts.py
"""

from __future__ import annotations

import hashlib
import json
import pathlib
import sys

WEB = pathlib.Path("build/web")
MANIFEST = WEB / "assets" / "FontManifest.json"
TOMBSTONE_SRC = pathlib.Path("tool/sw_tombstone.js")
TOMBSTONE_DST = WEB / "flutter_service_worker.js"


def sweep_old_fonts(manifest: list[dict]) -> None:
    """Delete hashed fonts from earlier builds.

    Renaming leaves the previous build's file behind — `flutter build web`
    does not know about names this script invented — so they pile up in the
    build directory and ship again on every deploy. Nine copies and 1.9 MB had
    accumulated on production, one of them a 1.6 MB font from a
    `--no-tree-shake-icons` experiment months earlier.

    Safe to remove: the entry files are served `no-cache`, so every client gets
    the current `FontManifest.json` and therefore asks for the current name.
    """
    keep = {
        pathlib.PurePosixPath(font["asset"]).name
        for family in manifest
        for font in family.get("fonts", [])
    }
    fonts = WEB / "assets" / "fonts"
    if not fonts.is_dir():
        return
    dropped = 0
    for path in fonts.iterdir():
        # Only ones this script named: `<stem>.<10 hex>.<ext>`.
        parts = path.name.split(".")
        if len(parts) == 3 and len(parts[1]) == 10 and path.name not in keep:
            path.unlink()
            dropped += 1
    if dropped:
        print(f"  swept {dropped} font file(s) from earlier builds")


def install_tombstone() -> None:
    """Put the uninstaller back over the empty file the build just wrote."""
    if not TOMBSTONE_SRC.exists():
        print(f"  WARNING: {TOMBSTONE_SRC} missing — worker left as built")
        return
    body = TOMBSTONE_SRC.read_bytes()
    if TOMBSTONE_DST.exists() and TOMBSTONE_DST.read_bytes() == body:
        print("  service worker: tombstone already in place")
        return
    TOMBSTONE_DST.write_bytes(body)
    print(f"  service worker: tombstone installed ({len(body)} bytes)")


def main() -> int:
    if not MANIFEST.exists():
        print(f"no {MANIFEST} — run `flutter build web` first", file=sys.stderr)
        return 1

    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    renamed = 0

    for family in manifest:
        for font in family.get("fonts", []):
            rel = font.get("asset", "")
            # Only our own fonts; package assets keep their versioned paths.
            if not rel or rel.startswith("packages/"):
                continue
            src = WEB / "assets" / rel
            if not src.exists():
                print(f"  skip (missing): {rel}")
                continue
            digest = hashlib.sha256(src.read_bytes()).hexdigest()[:10]
            # Already hashed by a previous run over the same build.
            if f".{digest}." in src.name:
                continue
            stem = src.name.split(".")[0]
            dst = src.with_name(f"{stem}.{digest}{src.suffix}")
            # A previous run over the same build directory may already have
            # produced this exact file; identical content means an identical
            # name, so replacing it is a no-op rather than a conflict.
            if dst.exists():
                src.unlink()
            else:
                src.rename(dst)
            font["asset"] = str(
                pathlib.PurePosixPath(rel).with_name(dst.name)
            )
            print(f"  {rel}  ->  {font['asset']}")
            renamed += 1

    MANIFEST.write_text(
        json.dumps(manifest, separators=(",", ":")), encoding="utf-8", newline="\n"
    )
    print(f"hashed {renamed} font file(s)")
    sweep_old_fonts(manifest)
    install_tombstone()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
