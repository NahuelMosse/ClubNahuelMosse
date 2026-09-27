#!/usr/bin/env node
// PreToolUse: bloquea las escrituras que el método prohíbe.
// Un hook no puede obligar a hacer algo; sí puede impedir. Acá va sólo lo segundo.
// Contrato: exit 0 deja pasar, exit 2 bloquea y Claude lee stderr.

import { readFileSync, existsSync } from 'node:fs';
import { dirname } from 'node:path';
import { spawnSync } from 'node:child_process';

const entrada = JSON.parse(readFileSync(0, 'utf8'));
const ruta = (entrada.tool_input?.file_path ?? '').replaceAll('\\', '/');
const herramienta = entrada.tool_name ?? '';

if (!ruta) process.exit(0);

const rechazar = (motivo) => {
  process.stderr.write(motivo + '\n');
  process.exit(2);
};

// Bloquea editarlo, no crearlo: el paso 1 de la primera card tiene que poder escribirlo.
if (/\/card\.snapshot\.md$/.test(ruta) && existsSync(ruta)) {
  rechazar(
    'El card.snapshot.md no se edita nunca. Si la card cambió: renombrá el vigente a ' +
    'card.snapshot.<fecha>.md y escribí uno nuevo con /card. Editarlo pone en verde lo que ' +
    'estaba en rojo sin dejar rastro.'
  );
}

if (/\/ambiguedades\.md$/.test(ruta) && herramienta === 'Edit') {
  rechazar(
    'ambiguedades.md es append-only: una línea por evento, y una línea escrita no se toca. ' +
    'Para registrar un cambio de estado, agregá un evento nuevo al final.'
  );
}

// Regla 7 — el que implementa no baja la vara que él mismo tiene que superar.
// El congelamiento no es una fase declarada: es el commit en rojo del paso 4. Un test
// tagueado ya commiteado está congelado; uno que todavía no entró a git se está escribiendo.
const TAG = /@[A-Z]+-\d+-H\d+-\d+/;

if (/\.(spec|test)\.[tj]sx?$/.test(ruta)) {
  let tagueado = false;
  try {
    tagueado = existsSync(ruta) && TAG.test(readFileSync(ruta, 'utf8'));
  } catch (e) {
    // Ante la duda el guardia frena: fallar abierto convierte la regla en una sugerencia.
    rechazar(`No se pudo leer ${ruta} para ver si tiene tags de card (${e.code}). ` +
             'El guardia frena ante la duda.');
  }

  if (tagueado) {
    const seguido = spawnSync('git', ['ls-files', '--error-unmatch', '--', ruta],
                              { cwd: dirname(ruta), encoding: 'utf8' });
    if (seguido.error) {
      rechazar(`No se pudo consultar git para ${ruta} (${seguido.error.code}). ` +
               'Sin poder verificar si el test está congelado, el guardia frena.');
    }
    if (seguido.status === 0) {
      rechazar(
        `${ruta} tiene tests tagueados por card y ya está commiteado: quedó congelado en el ` +
        'paso 4. El que implementa no edita tests de escenario. Si el test está mal, decilo ' +
        'y pedí que se corrija — no lo corrijas vos.'
      );
    }
  }
}

process.exit(0);
