"""Turns the Vital Animations archive into web-sized media plus a manifest.

The source pack is ~3.8 GB of 1080-1440px square H.264 at 1.7-9.4 Mbps, which
is roughly ten times the bitrate a short looping demo needs. Each clip also
carries a ~2 kbps AAC track that is silent; dropping it saves nothing in bytes
but avoids the audio-focus interruption Android raises when a video with a
sound track starts playing.

Output per exercise, keyed by the pack's own `id` (verified unique across all
six sets, so a flat key space is safe):

    video/<id>.mp4     720x720 H.264, no audio, faststart
    poster/<id>.webp   single frame, 480x480

The poster matters beyond saving bandwidth in lists: Flutter's Image.network
renders it with no extra dependency, so the library can show every exercise
before any video player is wired up.

Reads straight out of the zip and extracts one clip at a time, so the full
3.8 GB is never unpacked to disk.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import json
import os
import subprocess
import sys
import tempfile
import zipfile

VIDEO_EXTS = (".mp4", ".mov")


def run(cmd: list[str]) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=True, text=True)


def probe_duration(path: str) -> float:
    out = run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration",
         "-of", "default=nk=1:nw=1", path]
    ).stdout.strip()
    try:
        return float(out)
    except ValueError:
        return 0.0


def encode_one(
    zip_path: str,
    member: str,
    exercise_id: str,
    out_dir: str,
    size: int,
    crf: int,
    poster_size: int,
) -> tuple[str, bool, str]:
    """Extracts one clip, writes its video and poster, returns (id, ok, note)."""
    video_out = os.path.join(out_dir, "video", f"{exercise_id}.mp4")
    poster_out = os.path.join(out_dir, "poster", f"{exercise_id}.webp")

    if os.path.exists(video_out) and os.path.exists(poster_out):
        return exercise_id, True, "skipped (already built)"

    suffix = os.path.splitext(member)[1]
    tmp = None
    try:
        with zipfile.ZipFile(zip_path) as z, tempfile.NamedTemporaryFile(
            suffix=suffix, delete=False
        ) as handle:
            tmp = handle.name
            with z.open(member) as src:
                while chunk := src.read(1 << 20):
                    handle.write(chunk)

        result = run([
            "ffmpeg", "-nostdin", "-v", "error", "-y", "-i", tmp,
            "-an",
            "-vf", f"scale={size}:{size}:flags=lanczos",
            "-c:v", "libx264", "-crf", str(crf), "-preset", "slow",
            "-pix_fmt", "yuv420p", "-movflags", "+faststart",
            video_out,
        ])
        if result.returncode != 0:
            return exercise_id, False, f"video: {result.stderr.strip()[:200]}"

        # 40% in, which lands mid-repetition rather than on the neutral
        # standing pose most of these clips open and close on.
        at = max(0.0, probe_duration(video_out) * 0.4)
        result = run([
            "ffmpeg", "-nostdin", "-v", "error", "-y",
            "-ss", f"{at:.3f}", "-i", video_out,
            "-frames:v", "1",
            "-vf", f"scale={poster_size}:{poster_size}:flags=lanczos",
            "-c:v", "libwebp", "-q:v", "80",
            poster_out,
        ])
        if result.returncode != 0:
            return exercise_id, False, f"poster: {result.stderr.strip()[:200]}"

        return exercise_id, True, ""
    finally:
        if tmp and os.path.exists(tmp):
            os.unlink(tmp)


def collect(zip_path: str) -> tuple[list[dict], list[str]]:
    """Pairs every metadata record with its clip. Returns (records, problems)."""
    with zipfile.ZipFile(zip_path) as z:
        names = [i.filename for i in z.infolist() if not i.is_dir()]
        videos = [n for n in names if n.lower().endswith(VIDEO_EXTS)]
        by_stem: dict[str, list[str]] = {}
        for v in videos:
            by_stem.setdefault(
                os.path.splitext(os.path.basename(v))[0], []
            ).append(v)

        records: list[dict] = []
        problems: list[str] = []
        seen: set[str] = set()

        for meta in sorted(n for n in names if n.lower().endswith(".json")):
            folder = os.path.dirname(meta)
            set_name = folder.split("/")[0]
            for rec in json.loads(z.read(meta).decode("utf-8-sig")):
                rid = rec["id"]
                candidates = [
                    v for v in by_stem.get(rid, []) if v.startswith(folder)
                ]
                if not candidates:
                    problems.append(f"no clip for {rid} ({rec.get('name')}) in {meta}")
                    continue
                if rid in seen:
                    problems.append(f"duplicate id {rid} in {meta}")
                    continue
                seen.add(rid)
                records.append({**rec, "_member": candidates[0], "_set": set_name})

        for stem, paths in by_stem.items():
            if stem not in seen:
                problems.append(f"clip with no record: {paths[0]}")

        return records, problems


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--zip", required=True, help="the Vital Animations archive")
    parser.add_argument("--out", required=True, help="output directory")
    parser.add_argument("--size", type=int, default=720)
    parser.add_argument("--poster-size", type=int, default=480)
    parser.add_argument("--crf", type=int, default=28)
    parser.add_argument("--jobs", type=int, default=min(8, os.cpu_count() or 4))
    parser.add_argument("--limit", type=int, default=0, help="first N only, for a trial run")
    args = parser.parse_args()

    os.makedirs(os.path.join(args.out, "video"), exist_ok=True)
    os.makedirs(os.path.join(args.out, "poster"), exist_ok=True)

    records, problems = collect(args.zip)
    for p in problems:
        print(f"  ! {p}", flush=True)
    if args.limit:
        records = records[: args.limit]
    print(f"{len(records)} exercises to build, {args.jobs} jobs\n", flush=True)

    failures: list[tuple[str, str]] = []
    done = 0
    with concurrent.futures.ThreadPoolExecutor(args.jobs) as pool:
        futures = {
            pool.submit(
                encode_one, args.zip, r["_member"], r["id"], args.out,
                args.size, args.crf, args.poster_size,
            ): r
            for r in records
        }
        for future in concurrent.futures.as_completed(futures):
            rid, ok, note = future.result()
            done += 1
            if not ok:
                failures.append((rid, note))
                print(f"  FAILED {rid}: {note}", flush=True)
            if done % 50 == 0 or done == len(records):
                print(f"  {done}/{len(records)}", flush=True)

    built = {r["id"] for r in records} - {rid for rid, _ in failures}
    manifest = [
        {
            "id": r["id"],
            "name": r["name"],
            "bodyPart": r["bodyPart"],
            "target": r["target"],
            "equipment": r["equipment"],
            "secondaryMuscles": r.get("secondaryMuscles", []),
            "instructions": r.get("instructions", []),
            "description": r.get("description", ""),
            "sourceSet": r["_set"],
            "video": f"video/{r['id']}.mp4",
            "poster": f"poster/{r['id']}.webp",
        }
        for r in records
        if r["id"] in built
    ]
    manifest.sort(key=lambda m: m["name"].lower())

    manifest_path = os.path.join(args.out, "manifest.json")
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)

    def total(sub: str) -> int:
        d = os.path.join(args.out, sub)
        return sum(os.path.getsize(os.path.join(d, n)) for n in os.listdir(d))

    print(f"\nmanifest : {len(manifest)} entries -> {manifest_path}")
    print(f"video    : {total('video') / 2**20:8.1f} MB")
    print(f"poster   : {total('poster') / 2**20:8.1f} MB")
    print(f"source   : {os.path.getsize(args.zip) / 2**30:8.2f} GiB")
    if failures:
        print(f"\n{len(failures)} failed")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
