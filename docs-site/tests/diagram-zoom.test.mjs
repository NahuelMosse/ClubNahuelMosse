import test from 'node:test';
import assert from 'node:assert/strict';
import { addZoom } from '../src/clientModules/diagram-zoom.js';

function buildDiagram() {
  const buttons = [];
  const container = {
    fullscreen: 0,
    appendChild: (b) => buttons.push(b),
    requestFullscreen() { this.fullscreen += 1; },
  };
  const document = {
    createElement: () => ({ listeners: {}, addEventListener(n, f) { this.listeners[n] = f; } }),
  };
  const svg = { ownerDocument: document, closest: () => container };
  return { svg, container, buttons };
}

test('cada diagrama Mermaid se agranda con la rueda, se mueve arrastrando y abre en pantalla completa @DOC-01-S4', () => {
  const { svg, container, buttons } = buildDiagram();
  let options;
  const instance = { resize() {}, fit() {}, center() {} };
  addZoom(svg, (element, o) => { assert.equal(element, svg); options = o; return instance; });

  assert.equal(options.mouseWheelZoomEnabled, true);
  assert.equal(options.panEnabled, true);
  assert.equal(options.controlIconsEnabled, true);

  assert.equal(buttons.length, 1);
  assert.equal(buttons[0].textContent, 'Full screen');
  buttons[0].listeners.click();
  assert.equal(container.fullscreen, 1);
});
