import { FC, PropsWithChildren, useState, Suspense, ReactNode, useEffect } from "react";
import Spinner from 'react-bootstrap/Spinner';
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { ErrorBoundary } from "react-error-boundary";
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';

import { queryConfig } from '@/lib/react-query';
import { MainErrorFallback } from '@/components/errors/main';
import { useCurrentUser } from '@/lib/auth';


const AuthLoader = ({ children }: { children: ReactNode }) => {
  const { data: user, isLoading } = useCurrentUser();

  // Redirect by modifying window should happen in useEffect hook
  useEffect(() => {
    if (!isLoading && !user) {
      window.location.href = '/sign_in';
    };
  }, [user, isLoading])

  if (isLoading) {
    return <div>Loading user account...</div>
  }

  // If user is null, return to finish rendering and allow redirection
  if (!user) return null;

  return <>{children}</>;
};

const AppProvider: FC<PropsWithChildren> = ({ children }) => {
  const [queryClient] = useState(
    () => new QueryClient({
        defaultOptions: queryConfig,
      }),
  );

  return (
    <Suspense
      fallback={
        <div className="flex h-screen w-screen items-center justify-center">
          <Spinner />
        </div>
      }
    >
      <ErrorBoundary FallbackComponent={MainErrorFallback}>
        <QueryClientProvider client={queryClient}>
          {import.meta.env.DEV && <ReactQueryDevtools />}
          <AuthLoader>
            {children}
            </AuthLoader>
        </QueryClientProvider>
      </ErrorBoundary>
    </Suspense>
  );
};

export default AppProvider;