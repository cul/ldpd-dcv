import { Site, SiteGeneralProperties } from "@/types/api";

export const getSiteGeneralProperties = (site: Site): SiteGeneralProperties => {
  return {
    slug: site.slug,
    title: site.title,
    alternativeTitle: site.alternativeTitle,
    palette: site.palette,
    layout: site.layout,
    searchType: site.searchType,
    showFacets: site.showFacets,
  }
}

const TooltipFieldMessageHash = new Map<string, string> ([
  ['title', 'The title of the site. This is data published from Hyacinth and should not be edited here.'],
  ['alternativeTitle', "The subtitle of the site. If blank and the Hyacinth data for the site includes a Library Location, that library's name will be used in some layouts."],
  ['palette', "The color scheme for the site, governing the homepage and any configured site pages. 'DLC default' defers to the design team's default configurations. See the site editor documentation for details."],
  ['layout', "The overall layout of markup for the site, governing the homepage and any configured site pages. 'DLC default' defers to the design team's default configurations. See the site editor documentation for details."],
  ['searchType', "The search type for the site indicates how search results should be presented. 'Catalog' indicates that search results should be presented in the context of filters on the general DLC catalog. 'Local' indicates that search results should be presented as an isolated corpus, with the configured site layout and palettes. 'Custom' indicates that a developer-implemented custom site provides this site's search, and should generally not be selected. See the site editor documentation for details"],
  ['portraitLayoutImages', "Configures the repository PIDs of images for the site homepage, where supported by the configured layout.  See the site editor documentation for details."],
  ['signatureLayoutImages', "Manages the design assets for a site homepage configured with the signature layout. See the site editor documentation for details"],
  ['groupLabel', "The label for this group of links, which will be presented as a drop-down menu if there are multiple links. If the group has only one link, the group label will not be displayed and the link will be presented directly in the site navigation bar."],
  ['linkLabel', "The label used for a link in a drop-down menu or, if it is the only link in a group, the site navigation bar."],
  ['linkValue', "The URL associated with this link. Full URLs will indicate that they are links to external resources. If a page slug is given and the link is marked as internal, a link to the named page will be built."],
  ['external', 'Mark whether your link value links to an external site (if it is an internal page, leave this field unchecked).'],
  ['iconClass', " The fontawesome class to use to iconify this link. The link label will be help text/title for the icon button."],
  // ['name', "description"],
  // ['name', "description"],
  // ['name', "description"],
  // ['name', "description"],
]);

export const sitePropertiesTooltipMessage = (fieldName: string) => {
  if (!TooltipFieldMessageHash.has(fieldName)) return ''
  return TooltipFieldMessageHash.get(fieldName);
}

// Helper to move an element in an array from src index to dst index, shifting
// the rest of the elements to the right as needed
// TODO : use splice for this
export const moveArrayElements = (original: boolean[], src: number, dst: number) => {
  const copy = [...original];
  const tmp = original[src];
  if (dst < src) {
    for (let i = src; i > dst; i--) {
      copy[i] = original[i-1]
    }
  } else {
    for (let i = src; i < dst; i++) {
      copy[i] = original[i+1]
    }
  }
  copy[dst] = tmp;
  return copy;
}

