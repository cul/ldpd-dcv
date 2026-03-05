import { Site, SiteGeneralProperties } from "@/types/api";

export const getSiteGeneralProperties = (site: Site): SiteGeneralProperties => {
  return (({ slug, title, alternativeTitle, palette, layout, searchType, showFacets }) => ({slug, title, alternativeTitle, palette, layout, searchType, showFacets}))(site);
}

const TooltipFieldMessageHash = new Map<string, string> ([
  ['title', 'The title of the site. This is data published from Hyacinth and should not be edited here.'],
  ['alternativeTitle', "The subtitle of the site. If blank and the Hyacinth data for the site includes a Library Location, that library's name will be used in some layouts."],
  ['palette', "The color scheme for the site, governing the homepage and any configured site pages. 'DLC default' defers to the design team's default configurations. See the site editor documentation for details."],
  ['layout', "The overall layout of markup for the site, governing the homepage and any configured site pages. 'DLC default' defers to the design team's default configurations. See the site editor documentation for details."],
  ['searchType', "The search type for the site indicates how search results should be presented. 'Catalog' indicates that search results should be presented in the context of filters on the general DLC catalog. 'Local' indicates that search results should be presented as an isolated corpus, with the configured site layout and palettes. 'Custom' indicates that a developer-implemented custom site provides this site's search, and should generally not be selected. See the site editor documentation for details"],
  ['portraitLayoutImages', "Configures the repository PIDs of images for the site homepage, where supported by the configured layout.  See the site editor documentation for details."],
  // ['name', "description"],
  // ['name', "description"],
  // ['name', "description"],
  // ['name', "description"],
  // ['name', "description"],
]);

export const sitePropertiesTooltipMessage = (fieldName: string) => {
  if (fieldName in TooltipFieldMessageHash) return ''
  return TooltipFieldMessageHash.get(fieldName);
}