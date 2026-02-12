import { queryOptions, useQuery } from "@tanstack/react-query";

import { QueryConfig } from "@/lib/react-query";
import { Site } from "@/types/api";
import { api } from "@/lib/api-client";

const getSites = async (): Promise<{ sites: Site[] }> => {
  return await api.get<{ sites: Site[] }>('/sites');
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

export { UseSites };