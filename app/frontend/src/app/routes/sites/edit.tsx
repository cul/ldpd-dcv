import { LoaderFunctionArgs, useParams } from "react-router-dom";
import { QueryClient } from "@tanstack/react-query";

import AuthorizationBoundary from "@/components/auth/authorization-boundary"
import { ROLES } from "@/lib/authorization";
import SiteEdit from "@/features/sites/components/sites-edit";
import { getSiteQueryOptions } from "@/features/sites/api/get-site";
import FetchingSuspense from "@/components/ui/fetching-suspense";

// Prefetch the particular site
const clientLoader = (queryClient: QueryClient) => async ( args: LoaderFunctionArgs) => {
  const slug = args.params.slug;
  if (!slug) throw Error("No slug parameter provided");
  queryClient.prefetchQuery(getSiteQueryOptions(slug));
}

const SitesEditRoute = () => {
  let { slug } = useParams();

  if (!slug) throw Error("No slug parameter provided");

  return (
    <AuthorizationBoundary role={ROLES.EDITOR} site={slug}>
      <FetchingSuspense dataName="site">
        <SiteEdit slug={slug} />
      </FetchingSuspense>
    </AuthorizationBoundary>
  )

}

export {clientLoader, SitesEditRoute as default };
