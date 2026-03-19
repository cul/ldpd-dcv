export interface User {
  uid: string;
  firstName: string;
  lastName: string;
  email: string;
  permissions: UserPermissions;
}

export interface UserPermissions {
  role: "ADMIN" | "USER" | "EDITOR";
  canEdit: string[] | null; // list of site slugs the user can edit
}

// export interface CurrentUserResponse {
//   user: User;
//   permissions: Permissions;
// }

//  todo : rewrite in camelCase
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
  searchConfiguration?: Record<string, any>; // optional, flexible structure
  bannerImageUrl: string;
  watermarkImageUrl: string;
  hasBannerImage: boolean;
  hasWatermarkImage: boolean;
  updatedAt: string;
}

//  t.string "slug", null: false
//     t.string "title"
//     t.integer "columns", default: 1, null: false
//     t.integer "site_id"
//     t.index ["site_id", "slug"], name: "index_site_pages_on_site_id_and_slug", unique: true

export interface SitePage {
  siteSlug: string;
  pageSlug: string;
  title: string;
  columns: number;
  siteId: number;
  updatedAt: string;
}

// export type SiteParams = Omit<Site,
//   'title' |
//   'slug'>;

export type SitePageGeneralData = Pick<SitePage,
  'siteSlug' |
  'pageSlug' |
  'title' |
  'updatedAt'
>;

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