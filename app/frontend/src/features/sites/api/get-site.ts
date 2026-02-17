import { queryOptions, useQuery } from "@tanstack/react-query";

import { QueryConfig } from "@/lib/react-query";
import { Site } from '@/types/api';
import { api } from '@/lib/api-client';


const getSite = async (siteSlug: string): Promise<Site | null> => {
  try {
    const response = await api.get<{ site: Site }>(`/sites/${siteSlug}`);
    return response?.site ?? null;
  } catch (error) {
    console.error('Error fetching site information', error);
    return null;
  }
}

const getSiteQueryOptions = (siteSlug: string) => {
  return queryOptions({
    queryKey: ['sites', siteSlug],
    queryFn: () => getSite(siteSlug),
  })
}

type UseSiteQueryOptions = {
  queryConfig?: QueryConfig<typeof getSiteQueryOptions>;
}

const useSite = (siteSlug: string, { queryConfig }: UseSiteQueryOptions = {}) => {
  return useQuery({
    ...getSiteQueryOptions(siteSlug),
    ...queryConfig,
  })
}

export { useSite };