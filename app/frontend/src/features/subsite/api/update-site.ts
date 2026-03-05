import { queryOptions, useMutation, useQuery, useQueryClient, useSuspenseQuery } from "@tanstack/react-query";

import { QueryConfig } from "@/lib/react-query";
import { Site, SiteGeneralProperties } from '@/types/api';
import { api } from '@/lib/api-client';
import { getSiteQueryOptions } from "./get-site";


// Update all or some attributes of a subsite
const updateSite = async (site: Site | SiteGeneralProperties) => {
  try {
    console.log('UPDATING SITE (MUTATION)')
    console.log("DATA RECEIVED:")
    console.log(site)
    console.log("JSON:")
    console.log(JSON.stringify({site}));
    const response = await api.patch<{ site: Site }>(`/sites/${site.slug}`, { site });
    return response?.site ?? null;
  } catch {
    console.error('Error putting site')
  }
}

type updateSiteSignatureImagesType = {
  slug: string;
  // banner?: ;
}
// const updateSiteSignatureImages = async ({ slug, })

const mUpdateSite = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: updateSite,
    onSuccess: () => queryClient.invalidateQueries({queryKey: ['sites']}) // invalidate all sites if we update a single site
  })
}

export { mUpdateSite }