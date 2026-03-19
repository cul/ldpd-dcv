import { User } from '@/types/api';
import { useCurrentUser } from './authentication';


enum ROLES {
  ADMIN = 'ADMIN',
  USER = 'USER',
  EDITOR = 'EDITOR'
}

type RoleTypes = keyof typeof ROLES;

type RulesType = {
  role: RoleTypes;
  site?: string;
}

const canEditSite = (user: User, site: string): boolean | undefined => {
  return user.permissions.canEdit?.includes(site);
}

// Check if the given user's permissions satisfies the provided rules
const isUserAuthorized = (user: User, rules: RulesType): boolean => {
  const { role, site } = rules;
  const currentUserRole = user.permissions.role;

  if (!role) return true;

  if (role === ROLES.USER) return true;

  if (role === ROLES.EDITOR) {
    if (currentUserRole === ROLES.ADMIN) return true;
    if (currentUserRole === ROLES.EDITOR) {
      if (!site) return true;
      if (canEditSite(user, site)) return true;
    }
  }

  if (role === ROLES.ADMIN && currentUserRole === ROLES.ADMIN) {
    return true;
  }

  return false;
}

// Helper function for conditionally rendering elements.
// Result should be cached in a useMemo reference in whichever top-level component is using it.
// The principal difference between using this and using AuthorizationBoundary is
// that the latter is a Component that renders its children if authorized and throws
// an error otherwise. That is intended for cases where an unauthorized user should never have
// gotten so far in the first place.
// This function is used to check current user permissions for the purposes of
// conditionally rendering content (throwing an error is the wrong behavior).
const useIsAuthorized = (rules: RulesType): boolean => {
  const { data: user } = useCurrentUser();
  if (!user) return false;
  return isUserAuthorized(user, rules);
}

export { ROLES, useIsAuthorized, isUserAuthorized };
export type { RoleTypes, RulesType };
