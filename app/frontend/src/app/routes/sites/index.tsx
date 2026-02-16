import { QueryClient } from "@tanstack/react-query";
import { useEffect } from "react";

import { requireAuthorization } from "@/lib/loader-authorization";
import { getSitesQueryOptions } from "@/features/sites/api/get-sites";
import SitesList from '@/features/sites/components/sites-list';
import { ROLES } from "@/lib/authorization";
import AuthorizationBoundary from "@/components/auth/authorization-boundary";

const SitesIndexRoute = () => {
  return (
    <AuthorizationBoundary role={ROLES.ADMIN} >
      <SitesList />
    </AuthorizationBoundary>
)};

export { SitesIndexRoute as default };