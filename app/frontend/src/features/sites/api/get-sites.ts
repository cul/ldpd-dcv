import { queryOptions, useQuery, useSuspenseQuery } from "@tanstack/react-query";

import { QueryConfig } from "@/lib/react-query";
import { Site } from "@/types/api";
import { api } from "@/lib/api-client";


type UseSitesQueryOptions = {
  queryConfig?: QueryConfig<typeof getSitesQueryOptions>;
}


// Q: what happens if there is error? does it get returned to the mutation/query object?
const getSites = async (): Promise<Site[] | null> => {
  // throw Error("(getSites queryFn) ERROR GETTING SITES")
  try {
    // Simulate network delay
    // await new Promise(resolve => setTimeout(resolve, 2000));

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
    staleTime: 1000 * 60 * 5, // 5 minutes
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
