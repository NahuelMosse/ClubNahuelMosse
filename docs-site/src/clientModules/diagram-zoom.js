const CONTAINER = '.docusaurus-mermaid-container';
const MARK = 'data-zoom';

export function addZoom(svg, createPanZoom) {
  const instance = createPanZoom(svg, {
    mouseWheelZoomEnabled: true,
    panEnabled: true,
    controlIconsEnabled: true,
    zoomScaleSensitivity: 0.3,
    minZoom: 0.5,
    maxZoom: 20,
  });
  const container = svg.closest(CONTAINER);
  const button = svg.ownerDocument.createElement('button');
  button.type = 'button';
  button.textContent = 'Full screen';
  button.className = 'button button--secondary button--sm';
  button.addEventListener('click', () => container.requestFullscreen());
  container.appendChild(button);
  return instance;
}

function activate(createPanZoom) {
  document.querySelectorAll(`${CONTAINER} svg:not([${MARK}])`).forEach((svg) => {
    svg.setAttribute(MARK, '1');
    svg.style.maxWidth = 'none';
    svg.setAttribute('height', '60vh');
    addZoom(svg, createPanZoom);
  });
}

let observing = false;

export function onRouteDidUpdate() {
  if (typeof document === 'undefined' || observing) return;
  observing = true;
  import('svg-pan-zoom').then(({ default: createPanZoom }) => {
    activate(createPanZoom);
    // Mermaid draws the SVGs asynchronously, after the route.
    new MutationObserver(() => activate(createPanZoom)).observe(document.body, {
      childList: true,
      subtree: true,
    });
  });
}
