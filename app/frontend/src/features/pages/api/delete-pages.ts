import { api } from "@/lib/api-client";
import { useMutation, useQueryClient } from "@tanstack/react-query";

const mDeleteSitePages = (siteSlug: string) => {
  // We define the mutation callback inside of the mutation in order to close-over the siteSlug value
  const deletePages = async ( pageSlugs: string[]) => {
    await Promise.all(pageSlugs.map(async pageSlug => {
      if (pageSlug === 'home') {
        throw Error('The homepage cannot be deleted');
      }
      await api.delete(`/sites/${siteSlug}/pages/${pageSlug}`);
    }));
  }
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: deletePages,
    onSuccess: () => queryClient.invalidateQueries({queryKey: ['sites', siteSlug, 'pages']})
  })
}

export { mDeleteSitePages }