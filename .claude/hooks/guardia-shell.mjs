#!/usr/bin/env node
// PreToolUse sobre Bash: el guardia de archivos sólo ve Edit/Write, así que un `cat > archivo`
// o un `sed -i` lo esquiva entero. Esto tapa ese camino.
// Contrato: exit 0 deja pasar, exit 2 bloquea y Claude lee stderr.

import { readFileSync } from 'node:fs';

const entrada = JSON.parse(readFileSync(0, 'utf8'));
const cmd = entrada.tool_input?.command ?? '';
if (!cmd) process.exit(0);

const rechazar = (motivo) => {
  process.stderr.write(motivo + '\n');
  process.exit(2);
};

// Redirección, sed -i, tee, mv/cp sobre un destino: las formas de escribir sin Edit/Write.
const escribeEn = (patronArchivo) =>
  new RegExp(
    `(>>?|\\btee\\b(\\s+-a)?|\\bsed\\b[^|;]*\\s-i|\\bmv\\b|\\bcp\\b)[^|;&]*${patronArchivo}`,
  ).test(cmd);

if (escribeEn('card\\.snapshot\\.md')) {
  rechazar(
    'Escribir card.snapshot.md por shell esquiva el guardia. Si la card cambió: renombrá el ' +
    'vigente a card.snapshot.<fecha>.md y escribí uno nuevo con /card. Crearlo por primera vez ' +
    'sí se puede con Write.'
  );
}

if (/\bsed\b[^|;]*\s-i[^|;]*ambiguedades\.md/.test(cmd)) {
  rechazar(
    'ambiguedades.md es append-only. Un `sed -i` reescribe líneas ya registradas. Para cambiar ' +
    'un estado, agregá un evento nuevo al final con `>>`.'
  );
}

// Matar por nombre de proceso se lleva puestos los de otros agentes y del usuario.
if (/\b(taskkill\b[^|;]*\/IM|pkill\b|killall\b)/i.test(cmd)) {
  rechazar(
    'Matar por nombre de proceso se lleva los procesos de otros agentes, del editor y del ' +
    'usuario, y no hay forma de deshacerlo. Matá por PID: guardá el pid de lo que levantás, o ' +
    'buscalo por el puerto que reservaste. Si no sabés el pid, dejalo vivo y decilo.'
  );
}

process.exit(0);
