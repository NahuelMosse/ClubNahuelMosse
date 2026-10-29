# HTTP defaults

The answers to the questions an HTTP card leaves open in almost every run. When the card says nothing on one of these and it
touches the card's routes, write it as `<ID>-ASM-NN · <the default>` with its planned test, without deliberating: each is the
reading cheapest to undo. What the card does say wins; a default that contradicts a sentence of `L1` is not taken.

| Open question | Default | Its test sends |
|---|---|---|
| `content-type` | The media type is compared without case and without parameters: `Application/JSON; charset=utf-8` is JSON; missing or `application/jsonx` is not | the three |
| Byte limit | Bytes of the raw body, counted while reading; exactly at the limit passes, one byte more is refused before parsing | limit and limit + 1, with a multibyte character |
| Integer id in the path | `^[1-9][0-9]*$` up to `Number.MAX_SAFE_INTEGER`; anything else (`0`, `01`, `-1`, `1.5`, `1e3`, 20 digits) is not found | each form |
| Integer in the query | Decimal digits only; empty (`?limite=`) or repeated (`?limite=1&limite=2`) is invalid | empty, repeated, `+5`, ` 5` |
| Free-text search | A literal substring: `%`, `_` and `'` are characters, bound as parameters with `ESCAPE`; empty means no filter; case folding in the app when the database folds ASCII only | `%`, `_`, `' OR 1=1 --`, `Ñ` |
| Order of a list | By id ascending, also after a filter | three rows created out of name order |
| Echoed `X-Request-Id` | Taken when it is 1 to 128 visible ASCII characters (`0x21`–`0x7E`); otherwise a generated UUID | 129 characters, a space, a newline |
| Unsupported method | A path that matches a route answers 405 with `Allow`, even with an invalid id (`DELETE /items/abc`) | that request |
| Unknown path, trailing slash | 404 with the card's not-found body; `/items/` is not `/items` | both |
| Extra keys, duplicate keys | Extra keys are ignored and not stored; a repeated key keeps the last value (`JSON.parse`) | `{"name":"a","name":"Ana","x":1}` |
| Server error | 500 with the card's error shape (`{"error":"interno"}` in its words), no stack, the common headers | a forced database failure (`--fault-db`) |
| Malformed request, slow body | The server's `clientError` answers 400 and its request timeout 408, both with the common headers, and closes | the `attack.mjs` raw rows |
| `Location` | A path relative to the host (`/items/7`) | the 201 |
| Failed migration | Each migration in a transaction; a failure stops the start with exit ≠ 0 and the database as before | a migration that throws |
| A field's type | Only a JSON string is text; a number, `true`, `null`, an array or an object is invalid, never coerced | each |
