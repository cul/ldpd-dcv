import { ReactNode, FC, PropsWithChildren } from "react";

import { ROLES, RoleTypes } from '@/lib/authorization'
import { Site } from "@/types/api";
import { useCurrentUser } from "@/lib/authentication";
import { User } from '@/types/api';

type AuthorizationBoundaryProps = {
  role: RoleTypes;
  site?: string; // Only relevant when the required roles include Editor
  children: ReactNode;
}

const canEditSite = (user: User, site: string): boolean | undefined => {
  return user.permissions.canEdit?.includes(site);
}

// Conditionally render the children based on whether the current user has one
// of the listed required roles.
// If the required roles includes "EDITOR" and the user is a non-admin, then the sites array will need
// to be checked as well.
const AuthorizationBoundary = ({ role, site, children }: AuthorizationBoundaryProps) => {
  console.log("⚠️ Authentication Boundary component entry")
  console.log(role, site)
  const { data: user, isLoading } = useCurrentUser();

  console.log(user)

  if (isLoading) {
    return <div>Loading user account...</div>
  }

  if (!user) {
    console.log("This should definitely never happen...");
    return null;
  }

  const currentUserRole = user.permissions.role
  console.log(currentUserRole)
  // No specific role required, just need to be authenticated
  if (!role) return children;

  if (role === ROLES.USER) return children;

  if (role === ROLES.EDITOR) {
    console.log(';;;;;;;;;;;;;;;;;;;;')
    if (currentUserRole === ROLES.ADMIN) return children;
    if (currentUserRole === ROLES.EDITOR) {
      if (!site) return children;
      if (canEditSite(user, site)) return children;
    }
  }

  if (role === ROLES.ADMIN && currentUserRole === ROLES.ADMIN) {
    console.log ("you are admin and this is admin")
    return children;
  }

  throw new Error('User is not authorized');
};

export default AuthorizationBoundary;