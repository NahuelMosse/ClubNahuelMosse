# Assets: imagery that belongs to the page

Measured by blind comparison of three versions of one landing: the one with integrated resources won. What made it win: nothing
drawn with basic shapes (objects drawn that way look amateur), one photographic genre, full-bleed image with type over or across it,
grading and grain baked into each file, clean cutouts. The treatment tool is `python .claude/tools/asset-pipeline.py --help` (PIL and ffmpeg only).

## Rules

Each rule has its check; the `designer` runs them before the last capture round.

1. **Nothing drawn with primitives to show objects or icons.** Geometry only as a system (grid, type, data).
   *Check:* no decorative element combines `border-radius: 50%` with `radial-gradient` or an `inset` shadow; no SVG of circles and paths standing for an object.
2. **One icon set per screen, from Iconify** (`https://api.iconify.design/<set>/<icon>.svg`): Lucide, Phosphor or Tabler.
   *Check:* the SVGs share one `stroke-width` and one grid; one set prefix in the sources.
3. **One photographic genre per page** (all editorial, all product on seamless, all architectural daylight).
   *Check:* the contact sheet of the page's images reads as one shoot; the (R-B) warmth of the images varies by 10 or less.
4. **One LUT and the grain baked into every file** (`asset-pipeline.py grade`), no global grain layer.
   *Check:* `report.json` `dist_after` is 30 or less for each image; no `filter` or `mix-blend-mode` on a photo.
5. **Hard edge on photos, with the photo's background as the page's background.** A mask fade only for atmosphere (a glow, a haze).
   *Check:* 20 px sampled at the image border match the container `background-color` (deltaE under 3); `mask-image` on a photo is `none`.
6. **Full-bleed image, or touching the type, in at least two sections.**
   *Check:* two `section` elements where an `img` or `video` spans the viewport width or overlaps a text box.
7. **System proportions and one radius for the whole set** (`crop`: 3:2, 4:5, 16:9).
   *Check:* the histogram of `width/height` has a ratio over 40 %; `border-radius` of every media is one value.
8. **One direction of light and shadow.** The shadow of a cutout falls opposite the light of the photos; no CSS `box-shadow` on an image.
   *Check:* `box-shadow` on media is `none`; compare the shadow side against the brightest side of the nearest photo.
9. **Cutouts without halos, or the whole photo** (`cutout`).
   *Check:* `report.json` `cutout.halo` is `false`; look at the cutout over the page background at 200 %.
10. **Hero video loop under 1.5 MB, in MP4 and AV1, with poster and a pause control** (`loop`).
    *Check:* `muted loop playsinline poster` on the `video`, a visible pause button, both files at 1500 KB or less.
11. **Each image in AVIF and WebP per width** (`variants`).
    *Check:* `<picture>` with `srcset` at 640, 1024, 1600 and 2400; the 1600 px file is 200 KB or less.

## Never, and what goes instead

| Never | Instead |
|---|---|
| Objects or icons drawn with CSS or SVG shapes | a cutout photo with the page's LUT and its shadow, a public-domain engraving, an Iconify icon |
| Mixed icon sets, uneven strokes | one Iconify set, one `stroke-width` |
| Emojis as icons | an icon of the set, or a word |
| Raw stock photos | LUT, grain and a system ratio (`grade`, `crop`) |
| A photo faded into the background with a gradient mask | a hard edge, or a photo whose background is the page's |
| A fixed grain layer over the whole page | grain baked into each image, same seed and size |
| Generic gradients (violet to blue) | a flat palette color; a gradient only as a scrim |
| 3D modeled in code | a render with light and materials, a photo or a video |

## Sources without a key

| Source | Where | License and credit |
|---|---|---|
| Wikimedia Commons | `commons.wikimedia.org/w/api.php` (`generator=search`, `prop=imageinfo`, `iiprop=url\|extmetadata`; send a `User-Agent` with contact) | per file: `extmetadata.LicenseShortName`; CC BY and CC BY-SA require credit and the license; public domain does not |
| Openverse | `api.openverse.org/v1/images/?q=<q>&license=cc0,pdm` (unstable: retry) | per image (`license`, `attribution` in the JSON); prefer `cc0,pdm` |
| Poly Haven | `api.polyhaven.com/assets`, `/files/<id>` | CC0, no credit needed |
| ambientCG | `ambientcg.com/api/v2/full_json` | CC0, no credit needed |
| Iconify | `api.iconify.design/<set>/<icon>.svg` | per set: Lucide ISC, Phosphor MIT, Tabler MIT; credit in `CREDITS.md` |
| Fontshare | `api.fontshare.com/v2/css?f[]=<family>@400,700` | ITF Free Font License, free for commercial use |

Not used: Unsplash (its API terms ask for non-automated use) and Pexels videos (they need a key).

## Credits

Every asset has a line in `specs/<card>/CREDITS.md`: file, source URL, author, license, and whether credit is required.
