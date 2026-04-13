import { QueryClient, queryOptions, useQuery, useSuspenseQuery } from '@tanstack/react-query';

import { api } from '@/lib/api-client';
import { ApiError } from '@/types/errors';
import { User } from '@/types/api';


const AUTH_QUERY_KEY = ['current-user'];

async function getCurrentUser(): Promise<User | null> {
  try {
    const response = await api.get<{ user: User }>('/users/_self');
    return response?.user ?? null;
  } catch (error: unknown) {
    console.error('Error fetching current user:', error);
    if (error instanceof ApiError && error.status === 401) return null;
    throw error; // Rethrow unknown errors
  }
}

// export const ensureCurrentUser = async (queryClient: QueryClient) => {
//   await queryClient.fetchQuery({
//     queryKey: AUTH_QUERY_KEY,
//     queryFn: getCurrentUser,
//     staleTime: 1000 * 60 * 30,
//   });
// }

export const fetchCurrentUser = async (queryClient: QueryClient): Promise<User> => {
  return await queryClient.fetchQuery({
    queryKey: AUTH_QUERY_KEY,
    queryFn: getCurrentUser,
    staleTime: 1000 * 60 * 30,
  });
}

// This loader on the root route will fetch our current user for the queryCache
// so that subsequent auth checks can simply use the cached value
// Because the MainLayout subscribes to the current user query (via the 
// AuthenticationBoundary component), our current user data (including permissions)
// will always be up to date.
const loadAuth = async (queryClient: QueryClient) => {
  try {
    await fetchCurrentUser(queryClient);
  } catch (error) {
    console.error("Unknown error fetching current user - could not authenticate.");
    throw error;
  }
}

const getCurrentUserQueryOptions = () => {
  return queryOptions({
    queryKey: AUTH_QUERY_KEY,
    queryFn: getCurrentUser,
    staleTime: 1000 * 60 * 30, // 30 minutes
    gcTime: 1000 * 60 * 30, // 30 minutes cache garbage collection
    retry: false,
  })
}

const useCurrentUser = () => {
  const resp = useQuery({
    ...getCurrentUserQueryOptions(),
  });
  return resp;
}

const useCurrentUserSuspense = (): User => {
  const { data: currentUser } = useSuspenseQuery(getCurrentUserQueryOptions());
  if(!currentUser) throw Error("Could not load current user! Mayday!");
  return currentUser;
}

export { loadAuth, useCurrentUserSuspense, useCurrentUser, AUTH_QUERY_KEY}
