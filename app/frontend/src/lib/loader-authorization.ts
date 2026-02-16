import { QueryClient } from '@tanstack/react-query';
import { ROLES, RoleTypes  } from './authorization';
import { User } from '@/types/api';
import { AUTH_QUERY_KEY } from './authentication';

const hasAnyRole = (user: User, allowedRoles: RoleTypes[]): boolean => {
  const role = user.permissions.role;
  return allowedRoles.includes(role);
}

// Enforces authorization and throws an error if the user is not authorized
// If authorized, returns current user
const  requireAuthorization = async (queryClient: QueryClient, roles: RoleTypes[], sites?: string[]): Promise<User> => {
  const user = queryClient.getQueryData<User>(AUTH_QUERY_KEY)

  if (!user) {
    throw new Error('User not authenticated');
  }

  if (!roles || roles.length === 0) {
    return user; // No specific roles required, just need to be authenticated
  }

  if (sites && sites.length > 0) {
    // todo
    // return
  }

  if (!hasAnyRole(user, roles)) {
    // throw error
  }

  return user;
}

export { requireAuthorization };