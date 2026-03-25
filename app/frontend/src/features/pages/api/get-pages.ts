import { api } from "@/lib/api-client";
import { QueryConfig } from "@/lib/react-query";
import { SitePage } from "@/types/api";
import { queryOptions, useSuspenseQuery } from "@tanstack/react-query";

type UsePagesQueryOptions = {
  queryConfig?: QueryConfig<typeof getPagesQueryOptions>;
}

const getPages = async (siteSlug: string): Promise<SitePage[]> => {
  console.log("GET PAGES!")
  const response = await api.get<{ pages: SitePage[] }>(`/sites/${siteSlug}/pages`);
  return response?.pages ?? [];
}

const getPagesQueryOptions = (siteSlug: string) => {
  return queryOptions({
    queryKey: ['sites', siteSlug, 'pages'],
    queryFn: () => getPages(siteSlug),
  })
}

const usePagesSuspense = (siteSlug: string, { queryConfig }: UsePagesQueryOptions = {}): SitePage[] => {
  const { data: pages } = useSuspenseQuery({
    ...getPagesQueryOptions(siteSlug),
    ...queryConfig,
  });
  if (!pages) throw Error('usePagesSuspense got no pages');
  return pages;
}

export { getPagesQueryOptions, usePagesSuspense };