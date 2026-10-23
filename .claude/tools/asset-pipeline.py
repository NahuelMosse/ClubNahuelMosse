#!/usr/bin/env python3
"""asset-pipeline.py: treats photos and video so every asset of a page shares one palette, one grain and one set of proportions.

Subcommands (each writes its files to --out and merges its numbers into <out>/report.json):
  grade <img> --palette <hex,hex,...> [--strength 0.7] [--grain 0.35] [--width 2400]
        gradient-map LUT toward the palette (S curve on luminance, original desaturated underneath) plus baked monochrome grain.
        report: mean distance of the pixels to the nearest palette color, before and after.
  crop <img> --ratio 3:2|4:5|16:9 [--focus 0.5,0.5]    crop to a system ratio around a focal point.
  variants <img> [--widths 640,1024,1600,2400]          AVIF and WebP per width, same ratio as the input.
  cutout <img> [--lo 45] [--hi 110]                     cutout by background color (median of the border), ramped alpha, halo check.
        report: halo_score (mean distance of the edge pixels to the background; below 40 is a halo) and halo (true or false).
  loop <video> [--start 0] [--duration 4] [--width 1280]  loop.mp4 (H.264) and loop-av1.mp4 (AV1), cropped, no audio, plus a poster.
Needs only PIL and ffmpeg. Exit 0 done, 2 could not run (PIL or ffmpeg missing, bad arguments, an ffmpeg failure).
"""
import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path

try:
    from PIL import Image, ImageChops, ImageFilter, ImageOps
except ImportError:
    print('asset-pipeline: could not run: PIL (Pillow) is not installed', file=sys.stderr)
    sys.exit(2)

if not shutil.which('ffmpeg'):
    print('asset-pipeline: could not run: ffmpeg is not on the PATH', file=sys.stderr)
    sys.exit(2)

RATIOS = {'3:2': (3, 2), '4:5': (4, 5), '16:9': (16, 9)}
HALO_MIN = 40
LOOP_MAX_KB = 1500


def fail(msg):
    print(f'asset-pipeline: {msg}', file=sys.stderr)
    sys.exit(2)


def hexrgb(h):
    h = h.strip().lstrip('#')
    if len(h) != 6:
        fail(f'bad hex color: {h}')
    try:
        return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))
    except ValueError:
        fail(f'bad hex color: {h}')


def palette_distance(img, palette):
    small = img.convert('RGB').resize((160, 100))
    px = list(small.getdata())
    return round(sum(min(sum((p[i] - c[i]) ** 2 for i in range(3)) ** 0.5 for c in palette) for p in px) / len(px), 1)


def merge_report(out, key, data):
    f = out / 'report.json'
    rep = json.loads(f.read_text()) if f.exists() else {}
    rep[key] = data
    f.write_text(json.dumps(rep, indent=1))


def kb(p):
    return round(Path(p).stat().st_size / 1024)


def ff(*args):
    r = subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', *map(str, args)], capture_output=True, text=True)
    if r.returncode:
        fail(f'ffmpeg failed: {r.stderr.strip().splitlines()[-1] if r.stderr.strip() else r.returncode}')


def load(path):
    try:
        return Image.open(path).convert('RGB')
    except OSError as e:
        fail(f'{path}: {e}')


def ramp_channels(palette):
    """256 luminance steps to RGB along the palette sorted dark to light."""
    pal = sorted(palette, key=lambda c: 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2])
    n = len(pal) - 1
    chans = ([], [], [])
    for i in range(256):
        t = i / 255 * n
        a = min(int(t), n - 1) if n else 0
        b = min(a + 1, n)
        f = t - a
        for k in range(3):
            chans[k].append(round(pal[a][k] + (pal[b][k] - pal[a][k]) * f))
    return chans


def cmd_grade(a, out):
    palette = [hexrgb(h) for h in a.palette.split(',')]
    if len(palette) < 2:
        fail('--palette needs at least two colors')
    img = load(a.image)
    if img.width > a.width:
        img = img.resize((a.width, round(img.height * a.width / img.width)), Image.LANCZOS)
    before = palette_distance(img, palette)
    lum = ImageOps.grayscale(img).point(lambda v: round(255 * ((v / 255) ** 2 * (3 - 2 * v / 255) * 0.35 + v / 255 * 0.65)))
    mapped = Image.merge('RGB', [lum.point(ch) for ch in ramp_channels(palette)])
    under = Image.blend(ImageOps.grayscale(img).convert('RGB'), img, 0.35)
    graded = Image.blend(under, mapped, a.strength)
    noise = Image.effect_noise(graded.size, 40).filter(ImageFilter.GaussianBlur(0.6))
    graded = Image.blend(graded, ImageChops.overlay(graded, Image.merge('RGB', [noise] * 3)), a.grain)
    dest = out / f'{Path(a.image).stem}-graded.jpg'
    graded.save(dest, quality=90)
    after = palette_distance(graded, palette)
    merge_report(out, 'grade', {'file': str(dest), 'palette': a.palette, 'dist_before': before, 'dist_after': after,
                                'strength': a.strength, 'grain': a.grain})
    print(f'grade: {dest} · distance to palette {before} -> {after}')


def cmd_crop(a, out):
    rw, rh = RATIOS[a.ratio]
    try:
        fx, fy = (float(v) for v in a.focus.split(','))
    except ValueError:
        fail('--focus is x,y between 0 and 1')
    img = load(a.image)
    W, H = img.size
    cw, ch = (round(H * rw / rh), H) if W / H > rw / rh else (W, round(W * rh / rw))
    x = min(max(round(W * fx - cw / 2), 0), W - cw)
    y = min(max(round(H * fy - ch / 2), 0), H - ch)
    dest = out / f'{Path(a.image).stem}-{a.ratio.replace(":", "x")}.png'
    img.crop((x, y, x + cw, y + ch)).save(dest)
    merge_report(out, 'crop', {'file': str(dest), 'ratio': a.ratio, 'box': [x, y, x + cw, y + ch]})
    print(f'crop: {dest} {cw}x{ch}')


def cmd_variants(a, out):
    img = load(a.image)
    rows = []
    for w in (int(v) for v in a.widths.split(',')):
        im = img.resize((w, round(img.height * w / img.width)), Image.LANCZOS)
        stem = out / f'{Path(a.image).stem}-{w}'
        im.save(f'{stem}.webp', quality=78, method=6)
        try:
            im.save(f'{stem}.avif', quality=55, speed=6)
        except (KeyError, OSError, ValueError) as e:
            fail(f'this Pillow cannot write AVIF: {e}')
        rows.append({'width': w, 'webp_kb': kb(f'{stem}.webp'), 'avif_kb': kb(f'{stem}.avif')})
    merge_report(out, 'variants', rows)
    print('variants: ' + ', '.join(f"{r['width']}px avif {r['avif_kb']} KB webp {r['webp_kb']} KB" for r in rows))


def cmd_cutout(a, out):
    obj = load(a.image)
    obj.thumbnail((1600, 1600))
    W, H = obj.size
    border = [obj.getpixel((x, y)) for x in range(0, W, 8) for y in (2, H - 3)] + [obj.getpixel((x, y)) for y in range(0, H, 8) for x in (2, W - 3)]
    bg = tuple(sorted(c[i] for c in border)[len(border) // 2] for i in range(3))
    diff = ImageChops.difference(obj, Image.new('RGB', obj.size, bg)).convert('L')
    lo, hi = a.lo, a.hi
    mask = diff.point(lambda v: 0 if v <= lo else 255 if v >= hi else round((v - lo) / (hi - lo) * 255))
    mask = mask.filter(ImageFilter.MedianFilter(3)).filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.8))
    bbox = mask.getbbox()
    if not bbox:
        fail('the cutout is empty: the object does not differ from the background by --lo')
    cut = obj.copy()
    cut.putalpha(mask)
    cut = cut.crop(bbox)
    dest = out / f'{Path(a.image).stem}-cutout.png'
    cut.save(dest)
    alpha = list(cut.getchannel('A').getdata())
    rgb = list(cut.convert('RGB').getdata())
    edge = [p for p, v in zip(rgb, alpha) if 10 <= v <= 245]
    score = round(sum(sum((p[i] - bg[i]) ** 2 for i in range(3)) ** 0.5 for p in edge) / len(edge), 1) if edge else None
    halo = score is not None and score < HALO_MIN
    merge_report(out, 'cutout', {'file': str(dest), 'background': list(bg), 'lo': lo, 'hi': hi, 'edge_pixels': len(edge),
                                 'halo_score': score, 'halo': halo})
    print(f'cutout: {dest} · halo {"YES: whole photo or raise --lo" if halo else "no"} (score {score})')


def cmd_loop(a, out):
    base = (f'trim=start={a.start}:duration={a.duration},setpts=PTS-STARTPTS,scale={a.width}:-2,fps=24,format=yuv420p')
    mp4, av1, poster = out / 'loop.mp4', out / 'loop-av1.mp4', out / 'loop-poster.jpg'
    ff('-i', a.video, '-vf', base, '-an', '-c:v', 'libx264', '-crf', '26', '-preset', 'slow', '-movflags', '+faststart', mp4)
    ff('-i', a.video, '-vf', base, '-an', '-c:v', 'libsvtav1', '-crf', '42', '-preset', '6', '-movflags', '+faststart', av1)
    ff('-i', mp4, '-frames:v', '1', '-q:v', '3', poster)
    rep = {'mp4_kb': kb(mp4), 'av1_kb': kb(av1), 'poster_kb': kb(poster), 'under_limit': kb(mp4) <= LOOP_MAX_KB and kb(av1) <= LOOP_MAX_KB}
    merge_report(out, 'loop', rep)
    print(f'loop: mp4 {rep["mp4_kb"]} KB, av1 {rep["av1_kb"]} KB (limit {LOOP_MAX_KB} KB), poster {rep["poster_kb"]} KB')


def main():
    ap = argparse.ArgumentParser(prog='asset-pipeline.py', description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd', required=True)

    def add(name, arg):
        p = sub.add_parser(name)
        p.add_argument(arg)
        p.add_argument('--out', default='assets-out', help='output folder (default assets-out)')
        return p

    p = add('grade', 'image')
    p.add_argument('--palette', required=True)
    p.add_argument('--strength', type=float, default=0.7)
    p.add_argument('--grain', type=float, default=0.35)
    p.add_argument('--width', type=int, default=2400)
    p = add('crop', 'image')
    p.add_argument('--ratio', required=True, choices=RATIOS)
    p.add_argument('--focus', default='0.5,0.5')
    p = add('variants', 'image')
    p.add_argument('--widths', default='640,1024,1600,2400')
    p = add('cutout', 'image')
    p.add_argument('--lo', type=int, default=45)
    p.add_argument('--hi', type=int, default=110)
    p = add('loop', 'video')
    p.add_argument('--start', type=float, default=0)
    p.add_argument('--duration', type=float, default=4)
    p.add_argument('--width', type=int, default=1280)

    try:
        a = ap.parse_args()
    except SystemExit as e:
        sys.exit(e.code if e.code in (0, None) else 2)
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    {'grade': cmd_grade, 'crop': cmd_crop, 'variants': cmd_variants, 'cutout': cmd_cutout, 'loop': cmd_loop}[a.cmd](a, out)


if __name__ == '__main__':
    main()
