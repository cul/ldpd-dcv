import { useQuery } from '@tanstack/react-query';

import { api } from '@/lib/api-client';
import { User } from '@/types/api';


const AUTH_QUERY_KEY = ['authenticated-user'];

async function getCurrentUser(): Promise<User | null> {
  try {
    const response = await api.get<{ user: User }>('/users/_self');
    return response?.user ?? null; // todo ? ??
  } catch (error) {
    console.error('Error fetching current user:', error);
    return null;
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
