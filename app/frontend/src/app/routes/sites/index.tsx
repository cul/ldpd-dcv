import { QueryClient } from "@tanstack/react-query";
import { useEffect } from "react";

import SitesList from '@/features/sites/components/sites-list';
import { ROLES } from "@/lib/authorization";
import AuthorizationBoundary from "@/components/auth/authorization-boundary";

const SitesIndexRoute = () => {
  return (
    <AuthorizationBoundary role={ROLES.ADMIN} >
      <SitesList />
    </AuthorizationBoundary>
)};

export default SitesIndexRoute;