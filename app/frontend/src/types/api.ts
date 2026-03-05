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
}

// export type SiteParams = Omit<Site,
//   'title' |
//   'slug'>;

export type SiteGeneralProperties = Pick<Site,
  'slug' | // for identification
  'title' |
  'alternativeTitle' |
  'palette' |
  'layout' |
  'searchType' |
  'showFacets' >; // todo: remove this?