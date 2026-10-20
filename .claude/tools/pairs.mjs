// The pure part of `app.mjs pairs`: the routes a steps file visits, the coin that decides which side of a pair is X, and
// the text of `pairwise.md` when the base has no screen to compare with. The running of both apps is in app.mjs.
import { randomInt } from 'node:crypto';

// The path (and query) of every `goto` step, once each, in order.
export const gotoRoutes = (steps) => [...new Set(steps.filter((s) => s && typeof s.goto === 'string').map((s) => {
  const url = new URL(s.goto, 'http://app.invalid');
  return `${url.pathname}${url.search}`;
}))];

// The first thing the steps wait for or click, with the route they were at: what a base has to show to be a previous screen.
// A base that answers the route with a bare page has the route, not the screen. `null` when no step waits for or clicks anything.
export const firstTarget = (steps) => {
  let route = null;
  for (const s of steps ?? []) {
    if (!s || typeof s !== 'object') continue;
    if (typeof s.goto === 'string') { const url = new URL(s.goto, 'http://app.invalid'); route = `${url.pathname}${url.search}`; }
    const selector = typeof s.click === 'string' ? s.click : typeof s.wait === 'string' ? s.wait : null;
    if (selector) return { route: route ?? '/', selector };
  }
  return null;
};

// One coin per pair: which of base and HEAD is X. The key is kept out of what the reviewer is shown.
export const labelPairs = (names, coin = () => randomInt(2)) =>
  Object.fromEntries(names.map((name) => [name, coin() ? { X: 'head', Y: 'base' } : { X: 'base', Y: 'head' }]));

// The first line is the verdict the `PAIRWISE` file carries when there is no previous screen; `why` keeps the detail apart.
export const notApplicable = (route, why = '') =>
  `# Pairwise\n\nnot applicable · no previous screen at ${route}\n${why ? `\n${why}\n` : ''}`;
