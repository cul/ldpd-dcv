import { QueryClient } from "@tanstack/react-query";

import SitesList from '@/features/sites/components/sites-list';
import { getSitesQueryOptions } from "@/features/sites/api/get-sites";
import FetchingSuspense from "@/components/ui/fetching-suspense";
import { authorizeAdminOnly } from "@/lib/authorization";
import { AuthError } from "@/types/errors";


const clientLoader = (queryClient: QueryClient) => async () => {
  // Authorization check
  // Only admins may access the sites list page
  const authorized = await authorizeAdminOnly(queryClient);
  if (!authorized) {
    throw new AuthError("Only DLC Administrators can visit this page.");
  }
 
  // Prefetch sites data
  await queryClient.prefetchQuery(getSitesQueryOptions());
}

const SitesIndexRoute = () => {
  return (
    <FetchingSuspense dataName="sites">
      <SitesList />
    </FetchingSuspense>
)};

export { clientLoader, SitesIndexRoute as default };
