import { Roles } from "@/lib/authorization";

export interface User {
  uid: string;
  firstName: string;
  lastName: string;
  email: string;
  permissions: UserPermissions;
}

export interface UserPermissions {
  role: Roles;
  canEdit: string[] | null; // list of site slugs the user can edit
}

// Type representing a DLC SubSite (site model)
export interface Site {
  id: number;
  title: string;
  slug: string;
  persistentUrl: string;
  publisherUri: string;
  imageUris: string[];
  repositoryId: string;
  layout: string;
  palette: string;
  searchType: string;
  restricted: boolean;
  permissions: string[];
  mapSearch: boolean;
  dateSearch: boolean;
  alternativeTitle?: string; // optional
  showFacets?: boolean; // optional
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  searchConfiguration?: Record<string, any>; // optional, flexible structure
  bannerImageUrl: string;
  watermarkImageUrl: string;
  hasBannerImage: boolean;
  hasWatermarkImage: boolean;
  updatedAt: string;
}

// Type representing a page in a SubSite, corresponds to DLC site_page model
export interface SitePage {
  siteSlug: string;
  pageSlug: string;
  title: string;
  columns: number;
  siteId: number;
  updatedAt: string;
}

// Type defining a nested representation of a SubSite's Navigation links
// These are stored in the Rails app as nav_link model instances,
// which are not nested--see schema.db or the api endpoint site#get_site_nav_groups
// for more details
export type NavGroup = {
  groupLabel: string;
  childrenLinks: NavLink[];
}

export type NavLink = {
  linkLabel: string;
  linkValue: string;
  external: boolean | null;
  iconClass: string | null;
}

// Subtype of SitePage, for managing just the title value
export type SitePageGeneralData = Pick<SitePage,
  'siteSlug' |
  'pageSlug' |
  'title' |
  'updatedAt'
>;

// The following are subtypes of SitePage, used in forms that manage only a subset
// of a SubSite's properties.
export type SiteGeneralProperties = Pick<Site,
  'slug' | // for identification
  'title' |
  'alternativeTitle' |
  'palette' |
  'layout' |
  'searchType' |
  'showFacets' // todo: remove this?
>;

export type SitePortraitImageUris = Pick<Site,
  'slug' | // for identification
  'imageUris'
>;

export type SiteNavGroups = {
  slug: string;
  navGroups: NavGroup[]
}

//  TODO : consider having these values stored on the backend and retrieved by api endpoint
// (can change the set of options overtime without breaking things in UI)
export enum SitePalette {
  BLUE = 'blue',
  LIGHT = 'monochrome',
  DARK = 'monochromeDark',
  DEFAULT = 'default',
}
export enum SiteLayout {
  PORTRAIT = 'portrait',
  GALLERY = 'gallery',
  REPOSITORIES = 'repositories',
  SIGNATURE = 'signature',
  DEFAULT = 'default',
}
export enum SearchType {
  CATALOG = 'catalog',
  LOCAL = 'local',
  CUSTOM = 'custom',
  REPOSITORIES = 'repositories',
}