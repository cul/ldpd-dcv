import { queryOptions, useSuspenseQuery } from "@tanstack/react-query";
import { QueryConfig } from "@/lib/react-query";

import { api } from '@/lib/api-client';
import { NavGroup } from "@/types/api";


type UseNavGroupsQueryOptions = {
  queryConfig?: QueryConfig<typeof getNavGroupQueryOptions>;
}

const getNavGroups = async (siteSlug: string): Promise<NavGroup[] | null> => {
  const response = await api.get<{ navGroups: NavGroup[] }>(`/sites/${siteSlug}/nav_groups`)
  return response?.navGroups ?? null;
}

const getNavGroupQueryOptions = (siteSlug: string) => {
  return queryOptions({
    queryKey: ['sites', siteSlug, 'navGroups'],
    queryFn: () => getNavGroups(siteSlug),
  })
}

const useNavGroupsSuspense = (slug: string, { queryConfig }: UseNavGroupsQueryOptions = {}): NavGroup[] => {
  const { data: navGroups } = useSuspenseQuery({
    ...getNavGroupQueryOptions(slug),
    ...queryConfig,
  });
  if (!navGroups) throw Error(`useNaveGroupsSuspense got no nav groups for the given site (${slug})`);
  return navGroups;
}

export { getNavGroupQueryOptions, useNavGroupsSuspense };
