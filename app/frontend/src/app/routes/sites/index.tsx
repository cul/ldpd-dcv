import { QueryClient } from "@tanstack/react-query";

import { getSitesQueryOptions } from "@/features/sites/api/get-sites";
import FetchingSuspense from "@/components/ui/fetching-suspense";
import { authorizeAdminOrEditorOnly, getCurrentUserRole } from "@/lib/authorization";
import { AuthError } from "@/types/errors";
import SitesDashboard from "@/features/sites/components/sites-dashboard";


const clientLoader = (queryClient: QueryClient) => async () => {
  // Authorization check
  // Only admins may access the sites list page
  const authorized = await authorizeAdminOrEditorOnly(queryClient);
  if (!authorized) {
    throw new AuthError("Only DLC Administrators can visit this page.");
  }

  // Prefetch sites data
  if(await getCurrentUserRole(queryClient) === 'ADMIN') {
    await queryClient.prefetchQuery(getSitesQueryOptions());
  } else {
    await queryClient.prefetchQuery(getSitesQueryOptions({isEditor: true}));
  }
}
// todo: render diff dashboard based on current user permissions
const SitesIndexRoute = () => {
  return (
    <FetchingSuspense dataName="sites">
      <SitesDashboard />
    </FetchingSuspense>
)};

export { clientLoader, SitesIndexRoute as default };
