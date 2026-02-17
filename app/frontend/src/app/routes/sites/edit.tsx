import { useParams } from "react-router-dom";

import AuthorizationBoundary from "@/components/auth/authorization-boundary"
import { ROLES } from "@/lib/authorization";
import SiteEdit from "@/features/sites/components/sites-edit";

const SitesEditRoute = () => {
  let params = useParams();

  return (
    <AuthorizationBoundary role={ROLES.EDITOR} site={params.slug}>
      <SiteEdit slug={params.slug} />
    </AuthorizationBoundary>
  )

}

export default SitesEditRoute;