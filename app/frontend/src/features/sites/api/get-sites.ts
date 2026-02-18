import { queryOptions, useQuery, useSuspenseQuery } from "@tanstack/react-query";

import { QueryConfig } from "@/lib/react-query";
import { Site } from "@/types/api";
import { api } from "@/lib/api-client";


type UseSitesQueryOptions = {
  queryConfig?: QueryConfig<typeof getSitesQueryOptions>;
}


const getSites = async (): Promise<Site[] | null> => {
  try {
    // Simulate network delay
    console.log('api/sites...')
    await new Promise(resolve => setTimeout(resolve, 2000));

    const response = await api.get<{ sites: Site[] }>('/sites');

    return response?.sites ?? null;
  } catch (error) {
    console.error('Error fetching sites list:', error);
    return null;
  }
};

const getSitesQueryOptions = () => {
  return queryOptions({
    queryKey: ['sites'],
    queryFn: getSites,
    //  other config options (override defaults set in queryConfig - @/lib/react-query)
    });
};

const useSitesSuspense = (): Site[] => {
  const { data : sites } = useSuspenseQuery(getSitesQueryOptions());
  if (!sites) {
    // TODO handle
    throw Error("Could not load sites data");
  }
  return sites;
}

const useSites = ({ queryConfig} : UseSitesQueryOptions = {}) => {
  return useQuery({
    ...getSitesQueryOptions(),
    ...queryConfig,
  });
};

export { getSitesQueryOptions, useSites, useSitesSuspense };
