import { useMutation, useQueryClient } from "@tanstack/react-query";

import { Site, SiteGeneralProperties, SitePortraitImageUris } from '@/types/api';
import { api } from '@/lib/api-client';


// Update all or some attributes of a subsite (union of Site and subtypes of Site)
const updateSite = async (site: Site | SiteGeneralProperties | SitePortraitImageUris) => {
  if (!site.slug) throw Error("Error: An API request was made that required a subsite slug as identifier but was not given one.")

  const response = await api.patch<{ site: Site }>(`/sites/${site.slug}`, { site });
  return response?.site ?? null;
}

const useMUpdateSite = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: updateSite,
    onSuccess: () => queryClient.invalidateQueries({queryKey: ['sites']}) // invalidate all sites if we update a single site
  })
}

export { useMUpdateSite }