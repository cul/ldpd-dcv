import { ReactNode, useEffect } from "react";

import { useCurrentUser } from "@/lib/authentication";
import { useLocation } from "react-router-dom";


// Ensures Authentication before serving the app.
// Retrieves the current user data from the query cache, and if not present, redirects to the sign-in page.
const AuthenticationBoundary = ({ children }: { children: ReactNode }) => {
  const { data: user, isLoading } = useCurrentUser(); // subscribe to current user
  const { pathname } = useLocation();

  useEffect(() => {
    if (!isLoading && !user) {
      window.location.href = `/auth/redirect?return_to=${window.location.origin}/admin${pathname}`;
      return
    };
  }, [user, isLoading, pathname])

  if (isLoading) {
    return <div>Loading user account...</div>
  }

  // TODO : useSuspenseQuery
  if (!user) return null;

  return children;
};

export default AuthenticationBoundary;
