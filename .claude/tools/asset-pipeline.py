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
  loop <video>|--clips a.mp4,b.mp4,... [--start 0] [--duration 10] [--width 1280] [--seam crossfade|pingpong|none|auto] [--short "<why>"]
                                      [--duration-range 4-8] [--crossfade <s>] [--allow "<why>"]
        loop.mp4 (H.264) and loop-av1.mp4 (AV1), cropped, no audio, plus a poster. A hero loop is 8 s or more: a shorter one needs
        --short with the reason. crossfade (default) blends the last second into the first, so the jump disappears and the source
        needs duration + 1 s after --start; pingpong plays forward then backward; none is a hard cut.
        auto searches the source (from --start) for the pair of frames, --duration-range seconds apart (default 4-8), that look most
        alike over a 4-frame window (so the motion goes the same way), cuts there and blends --crossfade s (default 0.4). A searched
        loop under 8 s needs no --short.
        --clips mounts several clips (2-4 s each, 8 s or more in all) with hard cuts, the montage of production heroes: the restart is
        one more cut and seam_ok is true.
        Frame rate: never resampled by dropping or duplicating frames. The loop keeps the source rate (60 and 59.94 fps take every
        other frame: 30 and 29.97); --clips picks one rate every clip reaches exactly (25 fps retimed to 24 by timestamps, 23.976 to
        24, 29.97 to 30) and refuses a clip that cannot reach it.
        Source check, before using a clip: frozen frames (neighbour diff under FROZEN_DIFF) over FROZEN_MAX of the frames, or a
        step over SPIKE_X times the median, refuses the clip unless --allow "<why>" is given.
        report: seam_ratio (diff of the last frame against the first, over the median diff between neighbours; 1 is a normal step)
        and seam_ok (at SEAM_MAX_RATIO or less), fps, the checks of each source.
  audit <img|dir> [<img|dir> ...] [--label <art>] [--percentile 25]
        what the set of assets looks like, before the page uses it. Per file: sharpness (variance of the Laplacian on a 1200 px
        downscale) and warmth (mean R minus mean B); with --label, the ink distance (CIE76 delta E between the ink of the file and
        the ink of the label art: the mean color of its most saturated pixels). The sharpness floor is SHARP_FACTOR times that
        percentile of the set (default the 25th), so it follows the set and never flags a uniformly soft one; a file under it, an ink
        over INK_DE_MAX and a set whose warmth spreads over WARMTH_SPREAD_MAX are listed as flags.
        report: audit.files (sharpness, warmth, ink_de, flags), audit.set (sharp_floor, warmth_min, warmth_max, warmth_spread, flags).
Needs only PIL and ffmpeg. Exit 0 done, 2 could not run (PIL or ffmpeg missing, bad arguments, an ffmpeg failure).
"""
import argparse
import json
import shutil
import statistics
import subprocess
import sys
from fractions import Fraction
from pathlib import Path

try:
    from PIL import Image, ImageChops, ImageFilter, ImageOps, ImageStat
except ImportError:
    print('asset-pipeline: could not run: PIL (Pillow) is not installed', file=sys.stderr)
    sys.exit(2)

if not shutil.which('ffmpeg'):
    print('asset-pipeline: could not run: ffmpeg is not on the PATH', file=sys.stderr)
    sys.exit(2)

RATIOS = {'3:2': (3, 2), '4:5': (4, 5), '16:9': (16, 9)}
HALO_MIN = 40
# 10 s at 1280 wide: a detailed synthetic clip (testsrc2) measures 2.3 MB at CRF 26, so 1500 KB (set for 4 s) no longer fits.
LOOP_MAX_KB = 2500
LOOP_MIN_S = 8
CROSSFADE_S = 1.0
AUTO_CROSSFADE_S = 0.4
# The seam is measured against the motion of the video itself: the jump from the last frame to the first, over the median jump
# between neighbours. One continuous shot restarts at 1.0-1.2 times a step; a hard cut mid-motion is several times.
SEAM_MAX_RATIO = 1.5
# Gray 64x36 frames, mean absolute difference (0-255). A frame repeated by the encoder differs by under 0.15 from its neighbour;
# a stutter (a run of frames dropped) steps over 3 times the median. A clip above these is refused.
FROZEN_DIFF = 0.15
FROZEN_MAX = 0.10
SPIKE_X = 3
MEDIAN_FLOOR = 0.05
SEARCH_FPS = 12
SEARCH_WINDOW = 4
FPS_MAX = Fraction(3001, 100)
AUDIT_WIDTH = 1200
SHARP_FACTOR = 0.5
INK_DE_MAX = 12
WARMTH_SPREAD_MAX = 25
IMAGE_EXT = {'.png', '.jpg', '.jpeg', '.webp', '.avif', '.tif', '.tiff'}


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


def duration_of(path):
    r = subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', str(path)], capture_output=True, text=True)
    try:
        return float(r.stdout.strip())
    except ValueError:
        fail(f'{path}: ffprobe cannot read the duration')


def probe_fps(path):
    r = subprocess.run(['ffprobe', '-v', 'error', '-select_streams', 'v:0', '-show_entries', 'stream=avg_frame_rate,r_frame_rate',
                        '-of', 'default=nw=1', str(path)], capture_output=True, text=True)
    found = dict(line.split('=', 1) for line in r.stdout.splitlines() if '=' in line)
    for key in ('avg_frame_rate', 'r_frame_rate'):
        try:
            f = Fraction(found.get(key, '0/0'))
        except (ValueError, ZeroDivisionError):
            continue
        if f > 0:
            return f
    fail(f'{path}: ffprobe cannot read the frame rate')


def gray_frames(path, start=None, duration=None, fps=None):
    """64x36 gray frames of `path`: every decoded frame, or `fps` per second when given (a search does not need them all)."""
    cmd = ['ffmpeg', '-hide_banner', '-loglevel', 'error']
    if start:
        cmd += ['-ss', str(start)]
    cmd += ['-i', str(path)]
    if duration:
        cmd += ['-t', str(duration)]
    cmd += ['-an', '-vf', (f'fps={fps},' if fps else '') + 'scale=64:36,format=gray']
    if not fps:
        cmd += ['-fps_mode', 'passthrough']
    r = subprocess.run(cmd + ['-f', 'rawvideo', '-'], capture_output=True)
    if r.returncode:
        fail(f'ffmpeg could not read the frames of {path}')
    size = 64 * 36
    return [Image.frombytes('L', (64, 36), r.stdout[i * size:(i + 1) * size]) for i in range(len(r.stdout) // size)]


def mad(a, b):
    return ImageStat.Stat(ImageChops.difference(a, b)).mean[0]


def step_diffs(frames):
    return [mad(frames[i], frames[i + 1]) for i in range(len(frames) - 1)]


def seam_ratio(video):
    """The jump from the last frame of `video` to its first, over the median jump between neighbours: what the eye sees at the restart."""
    frames = gray_frames(video)
    if len(frames) < 3:
        fail(f'{video}: too few frames to measure the seam')
    return round(mad(frames[-1], frames[0]) / max(statistics.median(step_diffs(frames)), MEDIAN_FLOOR), 2)


def check_source(path, start=None, duration=None):
    """Measures a clip as it will be used: fps, frozen frames, steps over SPIKE_X times the median. Refuses it unless allowed."""
    frames = gray_frames(path, start, duration)
    if len(frames) < 3:
        fail(f'{path}: too few frames to check the source')
    d = step_diffs(frames)
    med = statistics.median(d)
    frozen = sum(x < FROZEN_DIFF for x in d) / len(d)
    spikes = sum(x > SPIKE_X * max(med, MEDIAN_FLOOR) for x in d)
    return {'file': str(path), 'fps': round(float(probe_fps(path)), 3), 'frames': len(frames), 'median_diff': round(med, 2),
            'frozen_ratio': round(frozen, 3), 'spikes': spikes}


def vet(src, allow):
    why = []
    if src['frozen_ratio'] > FROZEN_MAX:
        why.append(f"{src['frozen_ratio'] * 100:.0f} % of its frames are frozen (limit {FROZEN_MAX * 100:.0f} %)")
    if src['spikes']:
        why.append(f"{src['spikes']} steps over {SPIKE_X}x the median: it stutters")
    src['ok'] = not why
    if why and not allow:
        fail(f"{src['file']} is refused: {'; '.join(why)}. Use another clip, or pass --allow \"<why>\" to keep it.")
    if why:
        src['allowed'] = allow
    return src


def native_plan(fps):
    """The source rate, halved (every other frame) while it is over 30 fps. Frames are never dropped or duplicated otherwise."""
    k = 1
    while fps / k > FPS_MAX:
        k *= 2
    return {'k': k, 'eff': fps / k, 'out': fps / k, 'retimed': False}


RETIME_TARGETS = (Fraction(24), Fraction(25), Fraction(30))


def reachable(fps):
    """Rates a clip reaches exactly: its own, halved, or retimed by timestamps (25 to 24; 23.976, 29.97 to 24, 30). {rate: (k, retimed)}."""
    found, k = {}, 1
    while fps / k >= 12:
        r = fps / k
        found.setdefault(r, (k, False))
        for t in RETIME_TARGETS:
            if r != t and (abs(r / t - 1) < Fraction(2, 1000) or (r == 25 and t == 24)):
                found.setdefault(t, (k, True))
        k *= 2
    return found


def fmt_rate(r):
    return f'{float(r):.3f}'.rstrip('0').rstrip('.')


def choose_plans(clips, fpss):
    """One output rate for the whole montage: the one most clips reach, with fewest retimes, then the highest."""
    reach = [reachable(f) for f in fpss]
    rate = min(set().union(*reach), key=lambda c: (-sum(c in r for r in reach), sum(r[c][1] for r in reach if c in r), -c))
    plans = []
    for clip, fps, r in zip(clips, fpss, reach):
        if rate not in r:
            fail(f'{clip} ({fmt_rate(fps)} fps) cannot reach {fmt_rate(rate)} fps exactly: it reaches {", ".join(fmt_rate(x) for x in sorted(r))}. '
                 f'Frames would be dropped or duplicated; use a clip at one of those rates, or leave it out.')
        k, retimed = r[rate]
        plans.append({'k': k, 'eff': fps / k, 'out': rate, 'retimed': retimed})
    return plans


def search_loop(path, start, lo, hi, x):
    """The pair of frames lo..hi seconds apart that look most alike over SEARCH_WINDOW frames (same picture, same motion direction)."""
    frames = gray_frames(path, start, fps=SEARCH_FPS)
    n, w = len(frames), SEARCH_WINDOW
    lo_f, hi_f, tail = int(lo * SEARCH_FPS + 0.999), int(hi * SEARCH_FPS), max(round(x * SEARCH_FPS), w - 1)
    if n - 1 - tail < lo_f:
        fail(f'{path} lasts {n / SEARCH_FPS:.1f} s after --start {start:g}: a loop of {lo:g} s plus {x:g} s of blend does not fit')
    wins = []
    for i in range(n - w + 1):
        img = Image.new('L', (64, 36 * w))
        for k in range(w):
            img.paste(frames[i + k], (0, 36 * k))
        wins.append(img)
    best = None
    for i in range(n - tail):
        for j in range(i + lo_f, min(i + hi_f, n - 1 - tail) + 1):
            cand = (mad(wins[i], wins[j]), -(j - i), i, j)
            if best is None or cand < best:
                best = cand
    score, _, i, j = best
    step = max(statistics.median(step_diffs(frames)), MEDIAN_FLOOR)
    return {'start': round((start or 0) + i / SEARCH_FPS, 3), 'duration': round((j - i) / SEARCH_FPS, 3),
            'score': round(score, 2), 'ratio': round(score / step, 2)}


def retime(plan):
    """Every k-th frame, then timestamps N / rate: exact, with no filter that drops or duplicates by rounding."""
    sel = f"select='not(mod(n,{plan['k']}))'," if plan['k'] > 1 else ''
    return f"{sel}setpts=N/({plan['out'].numerator}/{plan['out'].denominator})/TB"


def loop_filter(a, plan):
    d, x = a.duration, a.x
    prep = f'{retime(plan)},scale={a.width}:-2,format=yuv420p'

    def head(t):  # `t` seconds of output, read from the source at its own speed
        return f"[0:v]trim=start={a.start}:duration={round(float(t * plan['out'] / plan['eff']), 4)},setpts=PTS-STARTPTS,{prep}"
    if a.seam == 'none':
        return head(d) + '[v]'
    if a.seam == 'pingpong':
        return head(d / 2) + ',split[f][r];[r]reverse[b];[f][b]concat=n=2:v=1[v]'
    # out(t) = S(t) from x to d; for t under x, the tail S(d + t) fades into the head S(t): the last frame is S(d - 1 frame)
    # and the first S(d), consecutive frames of the source.
    return (head(d + x) + ',split=3[a][b][c];'
            f'[a]trim=start=0:end={x},setpts=PTS-STARTPTS[head];'
            f'[b]trim=start={d}:end={d + x},setpts=PTS-STARTPTS[tail];'
            f'[c]trim=start={x}:end={d},setpts=PTS-STARTPTS[rest];'
            f'[tail][head]xfade=transition=fade:duration={x}:offset=0[mix];'
            f'[mix][rest]concat=n=2:v=1[v]')


def montage_filter(clips, width, plans):
    h = round(width * 9 / 16 / 2) * 2
    parts = ''.join(f'[{i}:v]{retime(plans[i])},scale={width}:{h}:force_original_aspect_ratio=increase,crop={width}:{h},setsar=1,format=yuv420p[c{i}];'
                    for i in range(len(clips)))
    return parts + ''.join(f'[c{i}]' for i in range(len(clips))) + f'concat=n={len(clips)}:v=1[v]'


def parse_range(text):
    try:
        lo, hi = (float(v) for v in text.split('-'))
    except ValueError:
        fail(f'--duration-range is <min>-<max> seconds, as 4-8 (got {text})')
    if not 0 < lo <= hi:
        fail(f'--duration-range is <min>-<max> seconds, as 4-8 (got {text})')
    return lo, hi


def cmd_loop(a, out):
    flt, sources, search = None, [], None
    a.x = 0
    if a.clips:
        clips = [c for c in a.clips.split(',') if c]
        if len(clips) < 2:
            fail('--clips needs at least two clips: a.mp4,b.mp4')
        plans = choose_plans(clips, [probe_fps(c) for c in clips])
        plan = plans[0]
        sources = [vet(check_source(c), a.allow) for c in clips]
        a.duration = round(sum(duration_of(c) * float(p['eff'] / p['out']) for c, p in zip(clips, plans)), 1)
        a.seam = 'montage'
        a.video, inputs, flt = clips[0], [x for c in clips for x in ('-i', c)], montage_filter(clips, a.width, plans)
        if a.duration < LOOP_MIN_S and not a.short:
            fail(f'the montage lasts {a.duration} s: a hero loop is {LOOP_MIN_S} s or more. Add clips or pass --short "<why>".')
    elif not a.video:
        fail('loop needs a video or --clips')
    else:
        inputs = ['-i', a.video]
        plan = native_plan(probe_fps(a.video))
        x = a.crossfade if a.crossfade is not None else (AUTO_CROSSFADE_S if a.seam == 'auto' else CROSSFADE_S)
        if a.seam == 'auto':
            search = search_loop(a.video, a.start, *parse_range(a.duration_range), x)
            a.start, a.duration = search['start'], search['duration']
        elif a.duration < LOOP_MIN_S and not a.short:
            fail(f'a hero loop is {LOOP_MIN_S} s or more (--duration {a.duration}): a short one repeats visibly. Pass --short "<why>" to keep it.')
        a.x = min(x, a.duration / 4) if a.seam in ('crossfade', 'auto') else 0
        need = a.start + a.duration + a.x
        have = duration_of(a.video)
        if have < need - 0.05:
            fail(f'{a.video} lasts {have:.1f} s and --seam {a.seam} needs {need:.1f} s from --start {a.start}: use a longer source, a lower --duration or --seam pingpong')
        sources = [vet(check_source(a.video, a.start, need - a.start), a.allow)]
    flt = flt or loop_filter(a, plan)
    rate = f"{plan['out'].numerator}/{plan['out'].denominator}"
    mp4, av1, poster = out / 'loop.mp4', out / 'loop-av1.mp4', out / 'loop-poster.jpg'
    ff(*inputs, '-filter_complex', flt, '-map', '[v]', '-an', '-r', rate, '-c:v', 'libx264', '-crf', '26', '-preset', 'slow', '-movflags', '+faststart', mp4)
    ff(*inputs, '-filter_complex', flt, '-map', '[v]', '-an', '-r', rate, '-c:v', 'libsvtav1', '-crf', '42', '-preset', '6', '-movflags', '+faststart', av1)
    ff('-i', mp4, '-frames:v', '1', '-q:v', '3', poster)
    ratio = seam_ratio(mp4)
    rep = {'duration_s': a.duration, 'seam': a.seam, 'seam_ratio': ratio, 'seam_ok': a.seam == 'montage' or ratio <= SEAM_MAX_RATIO,
           'fps': round(float(plan['out']), 3), 'sources': sources,
           'mp4_kb': kb(mp4), 'av1_kb': kb(av1), 'poster_kb': kb(poster), 'under_limit': kb(mp4) <= LOOP_MAX_KB and kb(av1) <= LOOP_MAX_KB}
    if search:
        rep['search'] = search
    if a.short:
        rep['short_reason'] = a.short
    merge_report(out, 'loop', rep)
    print(f'loop: {a.duration:g} s at {rep["fps"]:g} fps, mp4 {rep["mp4_kb"]} KB, av1 {rep["av1_kb"]} KB (limit {LOOP_MAX_KB} KB), poster {rep["poster_kb"]} KB')
    print(f'seam: {a.seam} · seam_ratio {ratio} (max {SEAM_MAX_RATIO}) · {"ok" if rep["seam_ok"] else "FAIL: the jump shows, use --seam auto, crossfade or pingpong"}')


def sharpness(img):
    # Laplacian through PIL: scale 8 and offset 128 keep +-1020 inside a byte, the variance is scaled back.
    g = img.convert('L')
    if g.width > AUDIT_WIDTH:
        g = g.resize((AUDIT_WIDTH, max(1, round(g.height * AUDIT_WIDTH / g.width))), Image.LANCZOS)
    lap = g.filter(ImageFilter.Kernel((3, 3), [0, 1, 0, 1, -4, 1, 0, 1, 0], scale=8, offset=128))
    return round(ImageStat.Stat(lap).var[0] * 64, 1)


def warmth(img):
    r, _, b = ImageStat.Stat(img.convert('RGB')).mean
    return round(r - b, 1)


def to_lab(rgb):
    def lin(v):
        v /= 255
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = (lin(v) for v in rgb)
    xyz = (0.4124 * r + 0.3576 * g + 0.1805 * b, 0.2126 * r + 0.7152 * g + 0.0722 * b, 0.0193 * r + 0.1192 * g + 0.9505 * b)
    f = [(t / n) ** (1 / 3) if t / n > 0.008856 else 7.787 * (t / n) + 16 / 116 for t, n in zip(xyz, (0.95047, 1.0, 1.08883))]
    return (116 * f[1] - 16, 500 * (f[0] - f[1]), 200 * (f[1] - f[2]))


def ink_of(img):
    small = img.convert('RGB').resize((200, max(1, round(img.height * 200 / img.width))))
    px = [p for p in small.getdata() if max(p) > 40 and (max(p) - min(p)) / max(p) > 0.25]
    if not px:
        return None
    px.sort(key=lambda p: (max(p) - min(p)) / max(p), reverse=True)
    top = px[:max(1, len(px) // 10)]
    return tuple(sum(p[i] for p in top) / len(top) for i in range(3))


def delta_e(a, b):
    return round(sum((x - y) ** 2 for x, y in zip(to_lab(a), to_lab(b))) ** 0.5, 1)


def percentile(values, q):
    v = sorted(values)
    k = (len(v) - 1) * q / 100
    lo = int(k)
    return v[lo] + (v[min(lo + 1, len(v) - 1)] - v[lo]) * (k - lo)


def cmd_audit(a, out):
    files = []
    for item in a.images:
        path = Path(item)
        if path.is_dir():
            files += sorted(f for f in path.iterdir() if f.suffix.lower() in IMAGE_EXT)
        elif path.exists():
            files.append(path)
        else:
            fail(f'{item}: not found')
    if not files:
        fail('audit: no images')
    label_ink = None
    if a.label:
        label_ink = ink_of(load(a.label))
        if label_ink is None:
            fail(f'{a.label}: no inked pixels to compare against')
    rows = []
    for f in files:
        img = load(f)
        row = {'file': f.name, 'sharpness': sharpness(img), 'warmth': warmth(img), 'flags': []}
        if label_ink:
            ink = ink_of(img)
            row['ink_de'] = delta_e(ink, label_ink) if ink else None
        rows.append(row)
    floor = round(percentile([r['sharpness'] for r in rows], a.percentile) * SHARP_FACTOR, 1)
    for r in rows:
        if r['sharpness'] < floor:
            r['flags'].append(f'soft: sharpness {r["sharpness"]} under {floor}')
        if r.get('ink_de') is not None and r['ink_de'] > INK_DE_MAX:
            r['flags'].append(f'ink off the label: delta E {r["ink_de"]} (max {INK_DE_MAX})')
    warm = [r['warmth'] for r in rows]
    spread = round(max(warm) - min(warm), 1)
    flags = [f'warmth spreads {spread} (max {WARMTH_SPREAD_MAX}): the set does not read as one light'] if spread > WARMTH_SPREAD_MAX else []
    merge_report(out, 'audit', {'files': rows, 'set': {'sharp_floor': floor, 'warmth_min': min(warm), 'warmth_max': max(warm), 'warmth_spread': spread, 'flags': flags}})
    for r in rows:
        print(f'{r["file"]}: sharpness {r["sharpness"]} · warmth {r["warmth"]}' + (f' · ink dE {r["ink_de"]}' if r.get('ink_de') is not None else '') + (' · FAIL ' + '; '.join(r['flags']) if r['flags'] else ''))
    print(f'set: {len(rows)} files · sharpness floor {floor} · warmth spread {spread}' + (' · FAIL ' + flags[0] if flags else ''))


def main():
    ap = argparse.ArgumentParser(prog='asset-pipeline.py', description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd', required=True)

    def add(name, arg, nargs=None):
        p = sub.add_parser(name)
        p.add_argument(arg, nargs=nargs)
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
    p = add('loop', 'video', '?')
    p.add_argument('--start', type=float, default=0)
    p.add_argument('--duration', type=float, default=10)
    p.add_argument('--width', type=int, default=1280)
    p.add_argument('--seam', choices=('crossfade', 'pingpong', 'none', 'auto'), default='crossfade')
    p.add_argument('--duration-range', default='4-8', help='with --seam auto: seconds between the two matching frames (default 4-8)')
    p.add_argument('--crossfade', type=float, help='seconds of blend (default 1 for crossfade, 0.4 for auto)')
    p.add_argument('--clips', help='comma-separated clips to mount with hard cuts')
    p.add_argument('--short', help='why a loop under 8 s is acceptable')
    p.add_argument('--allow', help='why a source with frozen frames or spikes is used anyway')

    p = sub.add_parser('audit')
    p.add_argument('images', nargs='+')
    p.add_argument('--label', help='the label art: ink of every file is compared against it')
    p.add_argument('--percentile', type=float, default=25)
    p.add_argument('--out', default='assets-out', help='output folder (default assets-out)')

    try:
        a = ap.parse_args()
    except SystemExit as e:
        sys.exit(e.code if e.code in (0, None) else 2)
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    {'grade': cmd_grade, 'crop': cmd_crop, 'variants': cmd_variants, 'cutout': cmd_cutout, 'loop': cmd_loop, 'audit': cmd_audit}[a.cmd](a, out)


if __name__ == '__main__':
    # The report lines carry `·`; a Windows console codepage would mangle it for whoever parses the output.
    sys.stdout.reconfigure(encoding='utf-8')
    main()
