import { ReactNode, useEffect } from "react";

import { useCurrentUser } from "@/lib/authentication";


// Ensures Authentication before serving the app.
// Retrieves the current user data from the query cache, and if not present, redirects to the sign-in page.
const AuthenticationBoundary = ({ children }: { children: ReactNode }) => {
  // console.log("⚠️ Authentication Boundary component entry")
  const { data: user, isLoading } = useCurrentUser(); // subscribe to current user

  // Redirect by modifying window should happen in useEffect hook
  useEffect(() => {
    if (!isLoading && !user) {

      window.location.href = '/sign_in';
      return
    };
  }, [user, isLoading])

  if (isLoading) {
    return <div>Loading user account...</div>
  }

  // If user is null, return to finish rendering and allow redirection
  if (!user) return null;

  // console.log('✅ Authentication Boundary passed!');
  return children;
};

export default AuthenticationBoundary;
