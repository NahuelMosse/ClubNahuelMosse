import { useEffect, useRef, useState } from 'react';
import useBaseUrl from '@docusaurus/useBaseUrl';

// Swagger UI inside the documentation page: the frame grows with its content, so the page
// has a single scroll and the menu on the left stays in view. The action and the frame come
// from the project's component set (design/components/).
export default function Swagger() {
  const frame = useRef(null);
  const [height, setHeight] = useState(800);
  const source = useBaseUrl('/swagger-ui/index.html');
  useEffect(() => {
    const id = setInterval(() => {
      const body = frame.current?.contentDocument?.body;
      if (body) setHeight(body.scrollHeight);
    }, 300);
    return () => clearInterval(id);
  }, []);
  return (
    <div className="stack" data-gap="3">
      <div className="inline" data-justify="end">
        <a className="btn btn--sm" href={source} target="_blank" rel="noreferrer">
          Open the API reference in a new tab
        </a>
      </div>
      <iframe
        ref={frame}
        className="swagger-embedded surface"
        data-pad="0"
        src={source}
        title="API (Swagger)"
        style={{ height }}
      />
    </div>
  );
}
