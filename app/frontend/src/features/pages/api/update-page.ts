
import { api } from "@/lib/api-client";
import { SitePage, SitePageGeneralData } from "@/types/api";
import { useMutation, useQueryClient } from "@tanstack/react-query";

const updatePages = async (pages: SitePage[] | SitePageGeneralData[]) => {
  await api.patch<{ pages: SitePage[] }>(`/sites/${pages[0].siteSlug}/pages`, { pages });
}

const useMUpdateSitePages = (siteSlug: string) => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: updatePages,
    onSuccess: async () => {
      await queryClient.refetchQueries({queryKey: ['sites', siteSlug, 'pages']});
    }
  })
}

export { useMUpdateSitePages }