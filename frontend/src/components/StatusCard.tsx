import { useEffect, useState } from 'react'
import { api, formatTimestamp } from '@/utils/api'
import type { HealthResponse } from '@/types/api'

interface StatusCardProps {
  title: string
  className?: string
}

export function StatusCard({ title, className = '' }: StatusCardProps) {
  const [health, setHealth] = useState<HealthResponse | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchHealth = async () => {
    try {
      setLoading(true)
      setError(null)
      const data = await api.getHealth()
      setHealth(data)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch status')
      setHealth(null)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchHealth()
    // Auto-refresh every 30 seconds
    const interval = setInterval(fetchHealth, 30000)
    return () => clearInterval(interval)
  }, [])

  const getStatusColor = () => {
    if (loading) return 'bg-gray-100'
    if (error || !health) return 'bg-red-50 border-red-200'
    if (health.status === 'ok') return 'bg-green-50 border-green-200'
    return 'bg-yellow-50 border-yellow-200'
  }

  const getStatusIcon = () => {
    if (loading) return '🔄'
    if (error || !health) return '❌'
    if (health.status === 'ok') return '✅'
    return '⚠️'
  }

  return (
    <div className={`border rounded-lg p-6 ${getStatusColor()} ${className}`}>
      <div className=\"flex items-center justify-between mb-4\">
        <h2 className=\"text-xl font-semibold text-gray-800\">{title}</h2>
        <span className=\"text-2xl\">{getStatusIcon()}</span>
      </div>

      {loading && (
        <div className=\"text-gray-600\">
          <p>서버 상태를 확인하는 중...</p>
        </div>
      )}

      {error && (
        <div className=\"text-red-600\">
          <p className=\"font-medium\">연결 실패</p>
          <p className=\"text-sm mt-1\">{error}</p>
          <button
            onClick={fetchHealth}
            className=\"mt-2 px-3 py-1 text-sm bg-red-100 hover:bg-red-200 rounded transition-colors\"
          >
            다시 시도
          </button>
        </div>
      )}

      {health && !loading && (
        <div className=\"space-y-2 text-sm\">
          <div className=\"flex justify-between\">
            <span className=\"text-gray-600\">상태:</span>
            <span className={`font-medium ${
              health.status === 'ok' ? 'text-green-600' : 'text-yellow-600'
            }`}>
              {health.status === 'ok' ? '정상' : '제한적'}
            </span>
          </div>
          
          <div className=\"flex justify-between\">
            <span className=\"text-gray-600\">데이터베이스:</span>
            <span className={`font-medium ${
              health.database === 'ok' ? 'text-green-600' : 'text-red-600'
            }`}>
              {health.database === 'ok' ? '정상' : '실패'}
            </span>
          </div>

          <div className=\"flex justify-between\">
            <span className=\"text-gray-600\">버전:</span>
            <span className=\"font-mono text-xs\">{health.version}</span>
          </div>

          <div className=\"flex justify-between\">
            <span className=\"text-gray-600\">시각:</span>
            <span className=\"text-xs\">{formatTimestamp(health.time)}</span>
          </div>

          <div className=\"pt-2 border-t\">
            <button
              onClick={fetchHealth}
              disabled={loading}
              className=\"w-full py-2 text-sm bg-blue-100 hover:bg-blue-200 disabled:bg-gray-100 rounded transition-colors\"
            >
              {loading ? '확인 중...' : '상태 새로고침'}
            </button>
          </div>
        </div>
      )}
    </div>
  )
}