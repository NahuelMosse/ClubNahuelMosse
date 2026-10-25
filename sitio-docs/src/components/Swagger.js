import { useEffect, useRef, useState } from 'react';
import useBaseUrl from '@docusaurus/useBaseUrl';

// Swagger UI dentro de la página de documentación: el marco crece con su contenido, así la página
// tiene un solo scroll y el menú de la izquierda queda a la vista.
export default function Swagger() {
  const marco = useRef(null);
  const [alto, setAlto] = useState(800);
  useEffect(() => {
    const id = setInterval(() => {
      const cuerpo = marco.current?.contentDocument?.body;
      if (cuerpo) setAlto(cuerpo.scrollHeight);
    }, 300);
    return () => clearInterval(id);
  }, []);
  return (
    <iframe
      ref={marco}
      className="swagger-incrustado"
      src={useBaseUrl('/swagger-ui/index.html')}
      title="API (Swagger)"
      style={{ height: alto }}
    />
  );
}
