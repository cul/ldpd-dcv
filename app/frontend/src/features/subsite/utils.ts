import { Site, SiteGeneralProperties } from "@/types/api";


export const getSiteGeneralProperties = (site: Site): SiteGeneralProperties => {
  return (({ slug, title, alternativeTitle, palette, layout, searchType, showFacets }) => ({slug, title, alternativeTitle, palette, layout, searchType, showFacets}))(site);
}