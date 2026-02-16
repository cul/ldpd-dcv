import { queryOptions, useQuery } from "@tanstack/react-query";

import { QueryConfig } from "@/lib/react-query";
import { Site } from "@/types/api";
import { api } from "@/lib/api-client";

const getSites = async (): Promise<Site[] | null> => {
  try {
    const response = await api.get<{ sites: Site[] }>('/sites');
    return response.sites
  } catch (error) {
    console.error('Error fetching sites list:', error);
    return null; //  Should I throw? TODO;
  }
};

const getSitesQueryOptions = () => {
  return queryOptions({
    queryKey: ['sites'],
    queryFn: getSites,
    //  other config options (override defaults set in queryConfig - @/lib/react-query)
    });
};

type UseSitesQueryOptions = {
  queryConfig?: QueryConfig<typeof getSitesQueryOptions>;
}

const UseSites = ({ queryConfig} : UseSitesQueryOptions = {}) => {
  return useQuery({
    ...getSitesQueryOptions(),
    ...queryConfig,
  });
};

export { UseSites, getSitesQueryOptions };