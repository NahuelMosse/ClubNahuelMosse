# HTTP defaults

The answers to the questions an HTTP card leaves open in almost every run. When the card says nothing on one of these and it
touches the card's routes, take it without deliberating, all as ONE `<ID>-ASM-NN · HTTP defaults` with a planned test per row
(each test tagged with that ASM): each is the reading cheapest to undo. What the card does say wins; a default that contradicts a sentence of `L1` is not taken.

| Open question | Default | Its test sends |
|---|---|---|
| `content-type` | The media type is compared without case and without parameters: `Application/JSON; charset=utf-8` is JSON; missing or `application/jsonx` is not | the three |
| Byte limit | Bytes of the raw body, counted while reading; exactly at the limit passes, one byte more is refused before parsing | limit and limit + 1, with a multibyte character |
| Integer id in the path | `^[1-9][0-9]*$` up to `Number.MAX_SAFE_INTEGER`; anything else (`0`, `01`, `-1`, `1.5`, `1e3`, 20 digits) is not found | each form |
| Integer in the query | Decimal digits only; empty (`?limite=`) or repeated (`?limite=1&limite=2`) is invalid. A filter above `Number.MAX_SAFE_INTEGER` is valid and matches nothing (200 `[]`); a page size above the card's cap is 400 | empty, repeated, `+5`, ` 5`, `9007199254740993`, cap + 1 |
| Text field | `trim()` at the edges (tab, newline, NBSP), length in code points (`[...s].length`), stored trimmed; the server cap is the input's `maxlength` | `"	Ana
"`, NBSP, an emoji at the cap |
| Case | One rule for uniqueness and search: `toLowerCase()`, Unicode, applied in the app | `Ñandú` against `ñandú` |
| Free-text search | A literal substring: `%`, `_` and `'` are characters, bound as parameters with `ESCAPE`; empty means no filter; over several fields, an OR field by field, never over the concatenated text | `%`, `_`, `' OR 1=1 --`, `Ñ`, a term split across two fields |
| Order of a list | By id ascending, also after a filter | three rows created out of name order |
| Echoed `X-Request-Id` | Taken when it is 1 to 128 visible ASCII characters (`0x21`–`0x7E`); otherwise a generated UUID | 129 characters, a space, a newline |
| Unsupported method | A path that matches a route answers 405 with `Allow`, even with an invalid id (`DELETE /items/abc`) | that request |
| Unknown path, trailing slash | 404 with the card's not-found body; `/items/` is not `/items`, and `//items` is a path, never a host or a 5xx | all three |
| Broken percent-encoding | In the path or the query (`%`, `%zz`, `%E0%A4%A`) it is 400 with the card's error body, never decoded to U+FFFD and searched | each |
| Extra keys, duplicate keys | Extra keys are ignored and not stored; a repeated key keeps the last value (`JSON.parse`) | `{"name":"a","name":"Ana","x":1}` |
| Server error | 500 with one body for every internal error (`{"error":"interno"}` in the card's words), no stack, the common headers, the error logged | a forced database failure (`--fault-db`) |
| Malformed request, slow body, huge header | The server's `clientError` answers 400, a header over the limit 431, and its request timeout 408, all with the common headers, and closes | the `attack.mjs` raw rows |
| `Location` | A path relative to the host (`/items/7`) | the 201 |
| Failed migration | Each migration in a transaction; a failure stops the start with exit ≠ 0 and the database as before | a migration that throws |
| A field's type | Only a JSON string is text; a number, `true`, `null`, an array or an object is invalid, never coerced | each |
| Client success | The screen takes any 2xx as success, not only the status the server sends | a stub answering 200 |
