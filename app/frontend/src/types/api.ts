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
  persistent_url: string;
  publisher_uri: string;
  image_uris: string[];
  repository_id: string;
  layout: string;
  palette: string;
  search_type: string;
  restricted: boolean;
  permissions: string[];
  map_search: boolean;
  date_search: boolean;
  alternative_title?: string; // optional
  show_facets?: boolean; // optional
  search_configuration?: Record<string, any>; // optional, flexible structure
}
