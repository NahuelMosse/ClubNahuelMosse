# HTTP defaults

The answers to the questions an HTTP card leaves open in almost every run. When the card says nothing on one of these and it
touches the card's routes, take it without deliberating, all as ONE `<ID>-ASM-NN · HTTP defaults` with a planned test per row
(each test tagged with that ASM): each is the reading cheapest to undo. What the card does say wins; a default that contradicts a sentence of `L1` is not taken.

| Open question | Default | Its test sends |
|---|---|---|
| `content-type` | The media type is compared without case and without parameters: `Application/JSON; charset=utf-8` is JSON; missing or `application/jsonx` is not | the three |
| Byte limit | Bytes of the raw body, counted while reading; exactly at the limit passes, one byte more is refused before parsing | limit and limit + 1, with a multibyte character |
| Integer id in the path | `^[1-9][0-9]*$` up to the largest integer the language represents exactly; anything else (`0`, `01`, `-1`, `1.5`, `1e3`, 20 digits) is not found | each form |
| Integer in the query | Decimal digits only; empty (`?limite=`) or repeated (`?limite=1&limite=2`) is invalid. A filter above that largest exact integer is valid and matches nothing (200 `[]`); a page size above the card's cap is 400 | empty, repeated, `+5`, ` 5`, `9007199254740993`, cap + 1 |
| Text field | trimmed at the edges (tab, newline, NBSP), length counted in code points, stored trimmed | `"	Ana
"`, NBSP, an emoji at the cap |
| Case | One rule for uniqueness and search: Unicode case folding, applied in the app | `Ñandú` against `ñandú` |
| Free-text search | A literal substring: `%`, `_` and `'` are characters, bound as parameters with `ESCAPE`; empty means no filter; over several fields, an OR field by field, never over the concatenated text | `%`, `_`, `' OR 1=1 --`, `Ñ`, a term split across two fields |
| Order of a list | A total order with a unique tiebreaker, also after a filter | three rows created out of name order |
| Request id | Follows `traceparent` (module observability: `reference/observability.md` OBS-IA-10); `X-Request-Id` is only an alias, taken when it is 1 to a configurable limit (default 128) of visible ASCII characters (`0x21`–`0x7E`); otherwise a generated id | over the limit, a space, a newline |
| Unsupported method | A path that matches a route answers 405 with `Allow`, even with an invalid id (`DELETE /items/abc`) | that request |
| Unknown path, trailing slash | 404 with the card's not-found body; `/items/` is not `/items`, and `//items` is a path, never a host or a 5xx | all three |
| Broken percent-encoding | In the path or the query (`%`, `%zz`, `%E0%A4%A`) it is 400 with the card's error body, never decoded to U+FFFD and searched | each |
| Extra keys, duplicate keys | Extra keys are ignored and not stored; a repeated key keeps the last value (the parser's behavior) | `{"name":"a","name":"Ana","x":1}` |
| Server error | 500 with one body for every internal error (`{"error":"…"}` in the card's words), no stack, the common headers, the error logged | a forced database failure (`--fault-db`) |
| Malformed request, slow body, huge header | The server answers 400 to a malformed request, 431 to a header over the limit and 408 to a request timeout, all with the common headers, and closes | the `attack.mjs` raw rows |
| `Location` | A path relative to the host (`/items/7`) | the 201 |
| Failed migration | Each migration in a transaction; a failure stops the start with exit ≠ 0 and the database as before | a migration that throws |
| A field's type | Only a JSON string is text; a number, `true`, `null`, an array or an object is invalid, never coerced | each |
