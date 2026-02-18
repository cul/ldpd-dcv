import { LoaderFunctionArgs, Outlet, useParams } from "react-router-dom";
import { QueryClient } from "@tanstack/react-query";

import AuthorizationBoundary from "@/components/auth/authorization-boundary"
import { ROLES } from "@/lib/authorization";
import { getSiteQueryOptions } from "@/features/sites/api/get-site";
import FetchingSuspense from "@/components/ui/fetching-suspense";


/* The show route wraps all routes that interact with one subsite.
 * Those routes are in the routes/sites/show sub directory.
 * This component:
 *  - enforces authorization for editing a site
 *  - provides a suspense component to display during fetching
 *  - prefetches site data in the client loader so children components
 *    can simply call useSiteSuspense() hook to access the site data.
**/

// Prefetch the particular site
const clientLoader = (queryClient: QueryClient) => async ( args: LoaderFunctionArgs) => {
  const slug = args.params.slug;
  if (!slug) throw Error("No slug parameter provided");
  queryClient.prefetchQuery(getSiteQueryOptions(slug));
}

const SitesShowRoute = () => {
  let { slug } = useParams();

  if (!slug) throw Error("No slug parameter provided");

  return (
    <AuthorizationBoundary role={ROLES.EDITOR} site={slug}>
      <FetchingSuspense dataName="site">
        <Outlet />
      </FetchingSuspense>
    </AuthorizationBoundary>
  )
}

export {clientLoader, SitesShowRoute as default };
