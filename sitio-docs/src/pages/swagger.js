import useBaseUrl from '@docusaurus/useBaseUrl';
import Layout from '@theme/Layout';

// Swagger UI con el contrato versionado de la API (apps/api/openapi.json); scripts/copiar.mjs lo deja en static/swagger-ui/.
export default function Swagger() {
  return (
    <Layout title="API (Swagger)" description="Las rutas de la API de ClubNahuelMosse">
      <iframe className="swagger-marco" src={useBaseUrl('/swagger-ui/index.html')} title="API (Swagger)" />
    </Layout>
  );
}
