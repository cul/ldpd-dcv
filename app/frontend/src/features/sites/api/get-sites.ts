import { queryOptions, useQuery, useSuspenseQuery } from '@tanstack/react-query';

import { QueryConfig } from '@/lib/react-query';
import { Site } from '@/types/api';
import { api } from '@/lib/api-client';

type UseSitesQueryOptions = {
  queryConfig?: QueryConfig<typeof getSitesQueryOptions>;
};

const getSites = async (): Promise<Site[] | null> => {
  try {
    const endpoint = '/sites';

    const response = await api.get<{ sites: Site[] }>(endpoint);

    return response?.sites ?? null;
  } catch (error) {
    console.error('Error fetching sites list:', error);
    return null;
  }
};

const getSitesQueryOptions = () => {
  return queryOptions({
    queryKey: ['sites'], // consider 'scoping': isEditor ? ['sites', { scope: 'editor' }] : ['sites'],
    queryFn: () => getSites(),
    staleTime: 1000 * 60 * 5, // 5 minutes
    //  other config options (override defaults set in queryConfig - @/lib/react-query)
  });
};

// If ADMIN: returns list of all DLC subsites
// If EDITOR: returns list of subsites the editor can edit
const useSitesSuspense = (): Site[] => {
  const { data: sites } = useSuspenseQuery(getSitesQueryOptions());
  if (!sites) {
    // TODO handle
    throw Error('Could not load sites data');
  }
  return sites;
};

// If ADMIN: returns list of all DLC subsites
// If EDITOR: returns list of subsites the editor can edit
const useSites = ({ queryConfig }: UseSitesQueryOptions = {}) => {
  return useQuery({
    ...getSitesQueryOptions(),
    ...queryConfig,
  });
};

export { getSitesQueryOptions, useSites, useSitesSuspense };
