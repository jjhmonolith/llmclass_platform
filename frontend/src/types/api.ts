// API response types
export interface HealthResponse {
  status: 'ok' | 'degraded'
  time: string
  version: string
  build_ts: string
  timezone: string
  database: 'ok' | 'failed'
}

export interface VersionResponse {
  version: string
  build_ts: string
  project: string
  timezone: string
  environment: string
}

export interface PingResponse {
  message: string
  timestamp: string
  request_id: string
  client_ip: string
  user_agent: string
  version: string
  environment: string
}

export interface ErrorResponse {
  detail: string
  error_code?: string
  request_id?: string
  timestamp?: string
}