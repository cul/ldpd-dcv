import { queryOptions, useQuery, useSuspenseQuery } from "@tanstack/react-query";

import { QueryConfig } from "@/lib/react-query";
import { Site } from "@/types/api";
import { api } from "@/lib/api-client";


type UseSitesQueryOptions = {
  queryConfig?: QueryConfig<typeof getSitesQueryOptions>;
}

const getSites = async ({isEditor}: {isEditor: boolean}): Promise<Site[] | null> => {
  try {
    const endpoint = `/sites${isEditor ? '?isEditor=true' : ''}`

    const response = await api.get<{ sites: Site[] }>(endpoint);

    return response?.sites ?? null;
  } catch (error) {
    console.error('Error fetching sites list:', error);
    return null;
  }
};

// isEditor: when true, will include an isEditor query parameter with the request
// so that the sites endpoint only returns a list of sites the current_user can edit.
const getSitesQueryOptions = ({isEditor=false}: {isEditor?: boolean} = {}) => {
  return queryOptions({
    queryKey: isEditor ? ['sites', { scope: 'editor' }] : ['sites'],
    queryFn: () => getSites({isEditor}),
    staleTime: 1000 * 60 * 5, // 5 minutes
    //  other config options (override defaults set in queryConfig - @/lib/react-query)
    });
};

const useSitesSuspense = ({isEditor}: {isEditor?: boolean}={}): Site[] => {
  const { data: sites } = useSuspenseQuery(getSitesQueryOptions({isEditor}));
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
