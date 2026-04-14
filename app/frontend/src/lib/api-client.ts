import { ApiError } from "@/types/errors";


const BASE_URL = '/api/v1';

async function request<T>(endpoint: string, options?: RequestInit, skipHeaders = false): Promise<T> {
  const config: RequestInit = {
    ...options,
    credentials: 'include',
  };

  if (!skipHeaders) {
    config.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...options?.headers,
    };
  }

  const response = await fetch(`${BASE_URL}${endpoint}`, config);

  if (!response.ok) {
    // Catch expired user session and redirect to login
    if (response.status === 403) {
      const returnTo = `${window.location.href}`;
      window.location.replace(`/auth/redirect?return_to=${returnTo}`);
      // The redirect will happen, but throw in meantime
      throw new Error('Session expired, redirecting to login...');
    }

    const errorBody = await response.json().catch(() => null);
    const message = errorBody?.message ?? errorBody?.error ?? response.statusText ?? 'API Error';
    const error = new ApiError(message, response.status);

    console.error(error);
    
    throw error;
  }

  return response.json();
}

export const api = {
  get: <T>(endpoint: string) =>
    request<T>(endpoint, { method: 'GET' }),

  // post: <T>(endpoint: string, data?: unknown) =>
  //   request<T>(endpoint, {
  //     method: 'POST',
  //     body: JSON.stringify(data)
  //   }),
  // put: <T>(endpoint: string, data?: unknown) =>
  //   request<T>(endpoint, {
  //     method: 'PUT',
  //     body: JSON.stringify(data)
  //   }),

  patch: <T>(endpoint: string, data?: unknown) =>
    request<T>(endpoint, {
      method: 'PATCH',
      body: JSON.stringify(data)
    }),

  // For when we want to use form data without converting to JSON
  patchRaw: <T>(endpoint: string, data?: FormData) =>
    request<T>(endpoint, {
      method: 'PATCH',
      body: data,
    },
      true // skipHeaders - we want the browser to set this for FormData
    ),

  delete: <T>(endpoint: string) =>
    request<T>(endpoint, { method: 'DELETE' }),
};
