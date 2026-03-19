import { queryOptions, useQuery, useSuspenseQuery } from "@tanstack/react-query";

import { QueryConfig } from "@/lib/react-query";
import { Site } from '@/types/api';
import { api } from '@/lib/api-client';


type UseSiteQueryOptions = {
  queryConfig?: QueryConfig<typeof getSiteQueryOptions>;
}


const getSite = async (siteSlug: string): Promise<Site | null> => {
  // try {
    const response = await api.get<{ site: Site }>(`/sites/${siteSlug}`);
    return response?.site ?? null;
  // } catch (error) {
  //   console.error('Error fetching site information', error);
  //   return null;
  // }
}

const getSiteQueryOptions = (siteSlug: string) => {
  return queryOptions({
    queryKey: ['sites', siteSlug],
    queryFn: () => getSite(siteSlug),
  })
}

const useSiteSuspense = (slug: string): Site => {
  const { data: site } = useSuspenseQuery(getSiteQueryOptions(slug));
  if (!site) throw Error("useSiteSuspense got no site");
  return site;
}

// not used atm -- we use suspense version
const useSite = (siteSlug: string, { queryConfig }: UseSiteQueryOptions = {}) => {
  return useQuery({
    ...getSiteQueryOptions(siteSlug),
    ...queryConfig,
  })
}

export { getSiteQueryOptions, useSite, useSiteSuspense };
