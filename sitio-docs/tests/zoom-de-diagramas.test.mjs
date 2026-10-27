import test from 'node:test';
import assert from 'node:assert/strict';
import { agregarZoom } from '../src/clientModules/zoom-de-diagramas.js';

function armarDiagrama() {
  const botones = [];
  const contenedor = {
    fullscreen: 0,
    appendChild: (b) => botones.push(b),
    requestFullscreen() { this.fullscreen += 1; },
  };
  const documento = {
    createElement: () => ({ listeners: {}, addEventListener(n, f) { this.listeners[n] = f; } }),
  };
  const svg = { ownerDocument: documento, closest: () => contenedor };
  return { svg, contenedor, botones };
}

test('cada diagrama Mermaid se agranda con la rueda, se mueve arrastrando y abre en pantalla completa @DOC-01-S4', () => {
  const { svg, contenedor, botones } = armarDiagrama();
  let opciones;
  const instancia = { resize() {}, fit() {}, center() {} };
  agregarZoom(svg, (elemento, o) => { assert.equal(elemento, svg); opciones = o; return instancia; });

  assert.equal(opciones.mouseWheelZoomEnabled, true);
  assert.equal(opciones.panEnabled, true);
  assert.equal(opciones.controlIconsEnabled, true);

  assert.equal(botones.length, 1);
  assert.equal(botones[0].textContent, 'Pantalla completa');
  botones[0].listeners.click();
  assert.equal(contenedor.fullscreen, 1);
});
