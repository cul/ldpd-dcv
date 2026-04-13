import { queryOptions, useQuery, useSuspenseQuery } from "@tanstack/react-query";

import { QueryConfig } from "@/lib/react-query";
import { Site } from "@/types/api";
import { api } from "@/lib/api-client";
import { useCurrentUserRoleSuspense } from "@/lib/authentication";
import { ROLES } from "@/lib/authorization";


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

// If ADMIN: returns list of all DLC subsites
// If EDITOR: returns list of subsites the editor can edit
const useSitesSuspense = (): Site[] => {
  const role = useCurrentUserRoleSuspense();
  const { data: sites } = useSuspenseQuery(getSitesQueryOptions({isEditor: role === ROLES.EDITOR}));
  if (!sites) {
    // TODO handle
    throw Error("Could not load sites data");
  }
  return sites;
}

// If ADMIN: returns list of all DLC subsites
// If EDITOR: returns list of subsites the editor can edit
const useSites = ({ queryConfig} : UseSitesQueryOptions = {}) => {
  const role = useCurrentUserRoleSuspense();
  return useQuery({
    ...getSitesQueryOptions({isEditor: role === ROLES.ADMIN}),
    ...queryConfig,
  });
};

export { getSitesQueryOptions, useSites, useSitesSuspense };
