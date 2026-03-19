/* eslint-disable @typescript-eslint/no-explicit-any */
import { UseMutationOptions, DefaultOptions } from '@tanstack/react-query';


// Default configuration for all queries and mutations in the app
export const queryConfig = {
  queries: {
    // throwOnError: true,
    refetchOnWindowFocus: true,
    retry: false,
    staleTime: 1000 * 20, // 20 seconds
    // gcTime: 1000 * 60 * 5, // 5 minutes
  },
} satisfies DefaultOptions;

export type ApiFnReturnType<FnType extends (...args: any) => Promise<any>> =
  Awaited<ReturnType<FnType>>;

export type QueryConfig<T extends (...args: any[]) => any> = Omit<
  ReturnType<T>,
  'queryKey' | 'queryFn'
>;

export type MutationConfig<
  MutationFnType extends (...args: any) => Promise<any>,
> = UseMutationOptions<
  ApiFnReturnType<MutationFnType>,
  Error,
  Parameters<MutationFnType>[0]
>;
