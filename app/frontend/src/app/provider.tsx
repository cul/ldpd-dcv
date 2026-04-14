import { FC, PropsWithChildren, useState } from "react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { ReactQueryDevtools } from "@tanstack/react-query-devtools";
import { ErrorBoundary } from "react-error-boundary";

import { queryConfig } from '@/lib/react-query';
import { MainErrorFallback } from '@/components/errors/main-error';


const AppProvider: FC<PropsWithChildren> = ({ children }) => {
  const [queryClient] = useState(
    () => new QueryClient({
        defaultOptions: queryConfig,
      }),
  );

  return (
    <ErrorBoundary FallbackComponent={MainErrorFallback}>
      <QueryClientProvider client={queryClient}>
        {import.meta.env.DEV && <ReactQueryDevtools />}
        {children}
      </QueryClientProvider>
    </ErrorBoundary>
  );
};

export default AppProvider;