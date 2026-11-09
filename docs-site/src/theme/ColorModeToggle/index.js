import React from 'react';
import useIsBrowser from '@docusaurus/useIsBrowser';

// The mode a press switches to; with no stored choice (system mode) the page's current theme decides.
const nextMode = (value, isBrowser) => {
  const current = value ?? (isBrowser ? document.documentElement.dataset.theme : 'light');
  return current === 'dark' ? 'light' : 'dark';
};

/** Swizzled color-mode toggle: one design-set button, never disabled, one visible label and no icons. */
export default function ColorModeToggle({ className, onChange, value }) {
  const isBrowser = useIsBrowser();
  const target = nextMode(value, isBrowser);
  const label = target === 'dark' ? 'Dark' : 'Light';
  return (
    <div className={className}>
      <button
        type="button"
        className="btn btn--ghost btn--sm"
        aria-label={`Switch to ${target} mode`}
        onClick={() => onChange(target)}
      >
        {label}
      </button>
    </div>
  );
}
