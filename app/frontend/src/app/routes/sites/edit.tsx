import { useParams } from "react-router";

import AuthorizationBoundary from "@/components/auth/authorization-boundary"
import { ROLES } from "@/lib/authorization";


const SitesEditRoute = () => {
  let params = useParams();
  return (
    <AuthorizationBoundary role={ROLES.EDITOR} site={params.slug}>
      <Site site={params.slug} />
    </AuthorizationBoundary>
  )
}