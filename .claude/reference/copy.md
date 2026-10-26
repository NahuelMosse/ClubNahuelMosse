# Copy: a voice and a number, not template phrases

Source: a study of 14 public sites made by an AI site builder. The strongest ones say something only their offer can say ("Two cities. Thirteen days. 1,884 events.", a long quote in the first person); the weakest run on filler ("Powerful Features", "Loved by Writers", a testimonial from "Sarah Chen").

## The `copy:` row of `## Look`

One line before the first headline is written: the concrete number of the offer (a count, a price, a duration, a distance: something that is checkable) and who speaks (the brand in first person, a founder, a customer by name and role, a handwritten note). The hero headline, one proof and one quote use them. A page with no number to give says so in the row (`copy: no number · the brand speaks`) instead of inventing one.

## Template phrases (a lint failure)

`design-round` runs `copy-lint.mjs` over the visible text; these phrases, in English and Spanish, fail the row `template phrase` (the list lives in `copy-lint.json`, key `template`):

- Powerful Features
- Loved by Writers (any "Loved by <word>")
- Trusted by thousands, millions or teams
- Unlock (and unlocks, unlocked, unlocking)
- Elevate (and elevates, elevating)
- All-in-one, one-stop, Everything you need
- Built for the modern ..., Streamline your ..., Empower your teams
- Lorem ipsum, Sarah Chen
- Funciones potentes, Características principales, Amado por, Todo lo que necesitas, Soluciones integrales

The fix is a sentence only this product can say, with its number, never a synonym of the phrase.
