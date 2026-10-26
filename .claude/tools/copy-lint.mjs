// copy-lint.mjs: the copy rules of the gate and of design-round, over the text a round measured. The word lists are in
// copy-lint.json (regex sources, English and Spanish together); this file only applies them.
//   lintCopy({ sections: [{ name, words }], ctas: [label], text }) -> [{ rule, detail }]
//   measureCopy (runs in the page) -> the input of lintCopy
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

export const LISTS = JSON.parse(readFileSync(join(import.meta.dirname, 'copy-lint.json'), 'utf8'));
const word = (list) => new RegExp(`(?<![\\p{L}\\p{N}])(?:${list.join('|')})(?![\\p{L}\\p{N}])`, 'giu');
const HYPE = word(LISTS.hype);
const AI = word(LISTS.aiTells);
const TEMPLATE = word(LISTS.template);
const GENERIC = word(LISTS.genericCta);
const VOSEO = word(LISTS.voseo);
const TUTEO = word(LISTS.tuteo);
const VERBS = new RegExp(`^(?:${LISTS.ctaVerbs.join('|')})$`, 'iu');

// Runs in the page: visible text by top-level section, the CTA labels and the whole text.
export const measureCopy = () => {
  const shown = (el) => { const r = el.getBoundingClientRect(); const cs = getComputedStyle(el); return r.width > 0 && r.height > 0 && cs.visibility !== 'hidden' && cs.display !== 'none'; };
  const all = [...document.querySelectorAll('section, [data-section], footer')].filter(shown);
  const top = all.filter((s) => !all.some((o) => o !== s && o.contains(s)));
  const sections = (top.length ? top : [document.body]).map((s, i) => ({
    name: s.id ? `#${s.id}` : s.getAttribute('data-section') || `${s.tagName.toLowerCase()} ${i + 1}`,
    words: (s.innerText || '').split(/\s+/).filter(Boolean).length,
  }));
  // Toggles and selectors choose a state; they are not calls to action. Declared here: the function is serialized into the page.
  const TOGGLE = '[aria-pressed], [aria-selected], [aria-checked], [role=tab], [role=radio], [role=switch], [role=option], [role=menuitemradio], input[type=radio], input[type=checkbox]';
  const ctas = [...document.querySelectorAll('button, [role=button], a[class*=btn], a[class*=button], a[class*=cta], input[type=submit]')]
    .filter((e) => shown(e) && !e.hasAttribute('aria-expanded') && !e.hasAttribute('aria-controls') && !e.matches(TOGGLE) && !e.closest('[role=tablist], [role=radiogroup]') && !e.querySelector('input[type=radio], input[type=checkbox]'))
    .map((e) => (e.value && e.tagName === 'INPUT' ? e.value : e.innerText || e.getAttribute('aria-label') || '').trim().replace(/\s+/g, ' '))
    .filter((l) => l.length >= 2);
  return { sections, ctas, text: document.body.innerText || '' };
};

const found = (re, text) => [...new Set([...text.matchAll(re)].map((m) => m[0].toLowerCase()))];

export const lintCopy = ({ sections = [], ctas = [], text = '' }) => {
  const out = [];
  const add = (rule, detail) => out.push({ rule, detail });
  const hype = found(HYPE, text); if (hype.length) add('hype', hype.slice(0, 5).join(', '));
  const tpl = found(TEMPLATE, text); if (tpl.length) add('template phrase', tpl.slice(0, 5).join(', '));
  const ai = found(AI, text); if (ai.length) add('AI tell', ai.slice(0, 5).join(', '));
  for (const label of ctas) if (found(GENERIC, label).length) add('generic CTA', `"${label}"`);
  const vos = found(VOSEO, text); const tut = found(TUTEO, text);
  if (vos.length && tut.length) add('voseo mixed with tuteo', `voseo: ${vos.slice(0, 3).join(', ')} · tuteo: ${tut.slice(0, 3).join(', ')}`);
  for (const s of sections) if (s.words > LISTS.maxWordsPerSection) add('words per section', `${s.name}: ${s.words} (max ${LISTS.maxWordsPerSection})`);
  for (const label of ctas) {
    if (found(GENERIC, label).length) continue;
    const words = label.split(/\s+/);
    if (words.length < 2 || !VERBS.test(words[0].replace(/[^\p{L}]/gu, ''))) add('CTA verb + object', `"${label}"`);
  }
  if (/"[^"\n]{1,200}"/.test(text)) add('straight quotes', 'use “ ” (or « »)');
  if (/\.{3}/.test(text)) add('three dots', 'use the ellipsis character …');
  return out;
};
