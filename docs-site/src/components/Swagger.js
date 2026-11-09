import { useEffect, useRef, useState } from 'react';
import useBaseUrl from '@docusaurus/useBaseUrl';

// Swagger UI inside the documentation page: the frame grows with its content, so the page
// has a single scroll and the menu on the left stays in view.
export default function Swagger() {
  const frame = useRef(null);
  const [height, setHeight] = useState(800);
  useEffect(() => {
    const id = setInterval(() => {
      const body = frame.current?.contentDocument?.body;
      if (body) setHeight(body.scrollHeight);
    }, 300);
    return () => clearInterval(id);
  }, []);
  return (
    <iframe
      ref={frame}
      className="swagger-embedded"
      src={useBaseUrl('/swagger-ui/index.html')}
      title="API (Swagger)"
      style={{ height }}
    />
  );
}
