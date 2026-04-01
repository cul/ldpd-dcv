import { useQuery } from '@tanstack/react-query';

import { api } from '@/lib/api-client';
import { ApiError, User } from '@/types/api';


const AUTH_QUERY_KEY = ['authenticated-user'];

async function getCurrentUser(): Promise<User | null> {
  try {
    const response = await api.get<{ user: User }>('/users/_self');
    console.log('get current user api response:')
    console.log(response)
    return response?.user ?? null;
  } catch (error: unknown) {
    console.error('Error fetching current user:', error);
    if (error instanceof ApiError && error.status === 401) return null;
    throw error; // Rethrow unknown errors
  }
}

function useCurrentUser() {
  const resp = useQuery({
    queryKey: AUTH_QUERY_KEY,
    queryFn: getCurrentUser,
    staleTime: 1000 * 60 * 30, // 30 minutes
    gcTime: 1000 * 60 * 30, // 30 minutes cache garbage collection
    retry: false,
  });
  return resp
}

export { useCurrentUser, AUTH_QUERY_KEY}
