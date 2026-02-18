import { ReactNode } from "react";

import { isUserAuthorized, RoleTypes } from '@/lib/authorization'
import { useCurrentUser } from "@/lib/authentication";


type AuthorizationBoundaryProps = {
  role: RoleTypes;
  site?: string; // Only relevant when the required roles include Editor
  children: ReactNode;
}

// Conditionally render the children based on whether the current user has one
// of the listed required roles.
// If the required roles includes "EDITOR" and the user is a non-admin, then the sites array will need
// to be checked as well.
const AuthorizationBoundary = ({ role, site, children }: AuthorizationBoundaryProps) => {
  // console.log("⚠️ Authentication Boundary component entry")
  const { data: user, isLoading } = useCurrentUser();

  if (isLoading) {
    return <div>Loading user account...</div>
  }

  if (!user) {
    console.log("This should definitely never happen...");
    return null;
  }

  if (isUserAuthorized(user, { role, site })) return children;

  throw new Error('User is not authorized');
};

export default AuthorizationBoundary;