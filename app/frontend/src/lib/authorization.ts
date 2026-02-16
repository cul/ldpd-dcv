import { QueryClient } from '@tanstack/react-query';
import { Site, User } from '@/types/api';
import { AUTH_QUERY_KEY } from './authentication';


enum ROLES {
  ADMIN = 'ADMIN',
  USER = 'USER',
  EDITOR = 'EDITOR'
}

type RoleTypes = keyof typeof ROLES;

const hasAnyRole = (user: User, allowedRoles: RoleTypes[]): boolean => {
  const role = user.permissions.role;
  return allowedRoles.includes(role);
}

// Enforces authorization before serving a route
// Throws an error if user is not authorized to visit this route
// This is not real authorization checking; it is just for UX. The backend API includes robust authorization checks.
// If authorized, returns current user
const requireAuthorization = async (queryClient: QueryClient, roles: RoleTypes[], sites?: string[]): Promise<User> => {
  const user = queryClient.getQueryData<User>(AUTH_QUERY_KEY)

  if (!user) {
    throw new Error('User not authenticated');
  }

  if (!roles || roles.length === 0) {
    return user; // No specific roles required, just need to be authenticated
  }

  if (sites && sites.length > 0) {
    // todo - are they an editor of the site?
    // return
  }

  if (!hasAnyRole(user, roles)) {
    // throw error
  }

  return user;
}

export { ROLES, requireAuthorization };
export type { RoleTypes };
