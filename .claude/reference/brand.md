# Brand identity and packaging

A brand is defined once and every asset reuses it: packaging, label, social piece, the landing. An asset in another typeface or palette
breaks the brand, whatever its craft. Evidence: blind verdicts on the Cebador can (a label in another typeface read as a different
brand); the packaging strategies come from 50 reference cans, only one with a verified award (Olipop, series, Dieline Awards 2025).

## The brand sheet

One sheet per card, as a `## Brand` block in `card.md` or a `brand.json` next to it. It holds:
- `wordmark`: the exact font and its settings (family, style, weight and every variable axis: `Fraunces italic 900, SOFT 100, WONK 1, opsz 144`), and its minimum size.
- `fonts:` the families the brand allows, wordmark first, text face next (`fonts: Fraunces, Schibsted Grotesk`). The gate reads this line.
- `palette`: tokens per variant (flavor, line, season), with the neutral and the legal-text color.
- `icon`: the mark that travels without the wordmark, and its clear space.
- `voice`: 3 to 5 traits with a line of example each, and the dialect of the audience (voseo in Argentina).

Where the card gives no sheet, the repo's existing site, logo or design system is the sheet; the Direction writes it down and an `ASM` marks it.
`node .claude/tools/design-round.mjs <url> --brand <brand.json|card.md>` fails a text family outside `fonts`; without a sheet it only reports the fonts used.

## Every asset reuses it

- The wordmark is the same file or the same font settings everywhere; it is never retyped in a similar face.
- Text on any asset uses the text face of the sheet; the palette of a variant is the palette of that variant on the page, the label and the social piece.
- Variants share layout and change at most two variables (color and motif or character).
- A new asset is checked against the sheet before it is shown: font, palette, icon, voice.

## Packaging that catches the eye

A personality strategy is chosen on purpose and named in the Direction. Strategies and what each costs:
- **Character or mascot:** the face is the brand and reads at 3 m (Tired Hands, Omnipollo, Liquid Death). One face per flavor, same style and frame.
- **Massive type:** the letter is the image, cut by the edge (Steal This Beer, Tab, Irn-Bru). Cheapest; it needs lettering of its own.
- **Pattern system:** one pattern per flavor builds a series visible from the back of the shelf (To Øl, Magic Rock Dark Arts). Margins respected, seams checked between cans.
- **Bold color block:** one saturated tone fills the can, no gradients (Verdant TDR, Poppi).
- **Humor and voice:** name and copy make people laugh and share (Liquid Death, Poppi); a voice held across the whole line.
- **Collectible series:** three cans together are worth more than one; a fixed rule (grid, wordmark, ground) with controlled variation (Verdant DR:ink, Olipop).

**Clichés that read as generic:** fruit-splash photo at full bleed, bubbles or moving water as freshness, a flavor name in medium serif over the photo,
a small centered wordmark, a plain band as the only gesture, three flavors that change only photo and color.

**The hook is positive energy.** A character on pack smiles, winks, laughs or invites; a sad or complaining one is the anti-hook. Prop
and hand shapes are checked at 100 % (a mate is not a bottle, a straw is not a pipe) and the flavor name sits outside the strip the can silhouette bites.

**Series logic:** same frame, same wordmark, same text face; per flavor a color, a character or pattern, and a phrase. Generate or draw one character at a time with fixed seed and prompt,
and compare the set side by side for consistency.

## Realism of product imagery

- **Satin, not catalogue gloss:** bodies are satin with bounded highlights; no mirror clear coat over the whole can (`reference/3d.md`).
- **Silhouette against a real photo:** the standard 355 ml can (66 mm diameter, 122 mm tall, small neck and lid) is checked by overlaying its outline on a real photo; squat beats tall.
- **A real photo composite beats code-made 3D:** the label is composited onto a photograph of the real can when one exists.
- **No organic objects made in code:** fruit, plants and food built from primitives or simple renders read as plastic. Use a real photograph, or an AI-generated photo checked at 100 % (rind, drops, shadows, edges).
- **Generated illustration** (local image model) is fine for characters and art: generated one at a time, checked at 100 % for hands, eyes and props, text never inside the image.
- Judge every product image next to a real photo of the same object.
