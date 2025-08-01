import type { HealthResponse, VersionResponse, PingResponse } from '@/types/api'

const API_BASE = import.meta.env.VITE_API_BASE || ''

// Generic fetch wrapper with error handling
async function fetchApi<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const url = `${API_BASE}${endpoint}`
  
  const response = await fetch(url, {
    headers: {
      'Content-Type': 'application/json',
      ...options.headers,
    },
    ...options,
  })

  if (!response.ok) {
    const error = await response.json().catch(() => ({
      detail: `HTTP ${response.status}: ${response.statusText}`,
    }))
    throw new Error(error.detail || 'API request failed')
  }

  return response.json()
}

// API functions
export const api = {
  // Health check
  async getHealth(): Promise<HealthResponse> {
    return fetchApi<HealthResponse>('/api/healthz')
  },

  // Version info
  async getVersion(): Promise<VersionResponse> {
    return fetchApi<VersionResponse>('/api/version')
  },

  // Dev ping
  async devPing(): Promise<PingResponse> {
    return fetchApi<PingResponse>('/api/dev/ping')
  },

  // Dev error (for testing)
  async devError(): Promise<never> {
    return fetchApi<never>('/api/dev/error')
  },
}

// Utility for formatting timestamps
export function formatTimestamp(isoString: string): string {
  return new Date(isoString).toLocaleString('ko-KR', {
    timeZone: 'Asia/Seoul',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  })
}