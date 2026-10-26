const CONTENEDOR = '.docusaurus-mermaid-container';
const MARCA = 'data-zoom';

export function agregarZoom(svg, crearPanZoom) {
  const instancia = crearPanZoom(svg, {
    mouseWheelZoomEnabled: true,
    panEnabled: true,
    controlIconsEnabled: true,
    zoomScaleSensitivity: 0.3,
    minZoom: 0.5,
    maxZoom: 20,
  });
  const contenedor = svg.closest(CONTENEDOR);
  const boton = svg.ownerDocument.createElement('button');
  boton.type = 'button';
  boton.textContent = 'Pantalla completa';
  boton.className = 'button button--secondary button--sm';
  boton.addEventListener('click', () => contenedor.requestFullscreen());
  contenedor.appendChild(boton);
  return instancia;
}

function activar(crearPanZoom) {
  document.querySelectorAll(`${CONTENEDOR} svg:not([${MARCA}])`).forEach((svg) => {
    svg.setAttribute(MARCA, '1');
    svg.style.maxWidth = 'none';
    svg.setAttribute('height', '60vh');
    agregarZoom(svg, crearPanZoom);
  });
}

let observando = false;

export function onRouteDidUpdate() {
  if (typeof document === 'undefined' || observando) return;
  observando = true;
  import('svg-pan-zoom').then(({ default: crearPanZoom }) => {
    activar(crearPanZoom);
    // Mermaid dibuja los SVG de forma asíncrona, después de la ruta.
    new MutationObserver(() => activar(crearPanZoom)).observe(document.body, {
      childList: true,
      subtree: true,
    });
  });
}
