import { User } from '@/types/api';
import { fetchCurrentUser } from './authentication';
import { QueryClient } from '@tanstack/react-query';


export enum ROLES {
  ADMIN = 'ADMIN',
  USER = 'USER',
  EDITOR = 'EDITOR'
}

export type Roles = keyof typeof ROLES;

const isAdmin = (user: User): boolean => {
  return user.permissions.role === ROLES.ADMIN;
}

const isEditor = (user: User): boolean => {
  return user.permissions.role === ROLES.EDITOR;
}

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const getEditableSites = (user: User): string[] => {
  return user.permissions.canEdit || [];
}

export const getCurrentUserRole = async (queryClient: QueryClient) => {
  const user = await fetchCurrentUser(queryClient);
  return user.permissions.role;
}

// Admin: can edit all sites
// Editor: subsite slug must be in the user's canEdit list
const canEditSite = (user: User, subsiteSlug: string): boolean | undefined => {
  if (isAdmin(user)) return true;
  return user.permissions.canEdit?.includes(subsiteSlug);
}

// The following methods are intended to be used in route loader functions.
// They ensure that the current user data is fresh, and then call the appropriate
// authorization methods
export const authorizeAdminOnly = async (queryClient: QueryClient) => {
  const user = await fetchCurrentUser(queryClient);
  return isAdmin(user);
}

export const authorizeAdminOrEditorOnly = async (queryClient: QueryClient) => {
  const user = await fetchCurrentUser(queryClient);
  return isAdmin(user) || isEditor(user);
}

export const authorizeCanEditSite = async (subsiteSlug: string, queryClient: QueryClient) => {
  const user = await fetchCurrentUser(queryClient);
  return canEditSite(user, subsiteSlug);
}
