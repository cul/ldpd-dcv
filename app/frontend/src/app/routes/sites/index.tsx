import { QueryClient, useSuspenseQuery } from "@tanstack/react-query";

import SitesList from '@/features/sites/components/sites-list';
import { ROLES } from "@/lib/authorization";
import AuthorizationBoundary from "@/components/auth/authorization-boundary";
import { getSitesQueryOptions } from "@/features/sites/api/get-sites";
import FetchingSuspense from "@/components/ui/fetching-suspense";

const clientLoader = (queryClient: QueryClient) => async () => {
  queryClient.prefetchQuery(getSitesQueryOptions());
}

const SitesIndexRoute = () => {
  return (
    <AuthorizationBoundary role={ROLES.ADMIN} >
      <FetchingSuspense dataName="sites">
        <SitesList />
      </FetchingSuspense>
    </AuthorizationBoundary>
)};

export { clientLoader, SitesIndexRoute as default };
