import { FC, PropsWithChildren, useState, Suspense, ReactNode, useEffect } from "react";
import Spinner from 'react-bootstrap/Spinner';
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { ErrorBoundary } from "react-error-boundary";

import { queryConfig } from '@/lib/react-query';
import { MainErrorFallback } from '@/components/errors/main';
import AuthenticationBoundary from '@/components/auth/authentication-boundary';


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
          {children}
        </QueryClientProvider>
      </ErrorBoundary>
    </Suspense>
  );
};

export default AppProvider;