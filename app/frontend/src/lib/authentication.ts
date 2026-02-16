import { useQuery } from '@tanstack/react-query';

import { api } from '@/lib/api-client';
import { User } from '@/types/api';


const AUTH_QUERY_KEY = ['authenticated-user'];

async function getCurrentUser(): Promise<User | null> {
  try {
    const response = await api.get<{ user: User }>('/users/_self');
    console.log('api')
    console.log(response)
    return response.user;
  } catch (error) {
    console.error('Error fetching current user:', error);
    return null; //  Should I throw? TODO
  }
}

function useCurrentUser() {
  console.log("use current user entered")
  const resp = useQuery({
    queryKey: AUTH_QUERY_KEY,
    queryFn: getCurrentUser,
    staleTime: 1000 * 60 * 5, // 5 minutes
    gcTime: 1000 * 60 * 30, // 30 minutes cache garbage collection
    retry: false,
  });
  return resp
}

export { useCurrentUser, AUTH_QUERY_KEY}