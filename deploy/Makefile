# Makefile for mono-class-platform
# Usage: make [target] [ENV=dev|prod]

# Default environment
ENV ?= dev
COMPOSE_FILE = docker-compose.yml
ENV_FILE = .env.$(ENV)
PROJECT_DIR = ..

# Check if environment file exists
check-env:
	@if [ ! -f "$(ENV_FILE)" ]; then \
		echo "❌ Environment file $(ENV_FILE) not found!"; \
		echo "📋 Available commands:"; \
		echo "   make setup-dev  # Create development environment"; \
		echo "   make setup-prod # Create production environment"; \
		exit 1; \
	fi
	@echo "✅ Using environment: $(ENV) ($(ENV_FILE))"

# Environment setup
setup-dev:
	@echo "🔧 Setting up development environment..."
	@if [ ! -f ".env.dev" ]; then \
		echo "❌ .env.dev not found in repository!"; \
		exit 1; \
	fi
	@echo "✅ Development environment ready"
	@echo "📝 Run 'make up ENV=dev' to start services"

setup-prod:
	@echo "🔧 Setting up production environment..."
	@if [ ! -f ".env.prod" ]; then \
		if [ -f ".env.prod.example" ]; then \
			cp .env.prod.example .env.prod; \
			echo "📝 Created .env.prod from template"; \
			echo "⚠️  IMPORTANT: Edit .env.prod with actual values!"; \
			echo "   - Change POSTGRES_PASSWORD"; \
			echo "   - Set TUNNEL_ID and TUNNEL_TOKEN"; \
			echo "   - Verify PUBLIC_DOMAIN"; \
		else \
			echo "❌ .env.prod.example not found!"; \
			exit 1; \
		fi \
	fi
	@echo "🔍 Checking production configuration..."
	@./env-check.sh prod || exit 1
	@echo "✅ Production environment ready"

# Docker operations
build: check-env
	@echo "🔨 Building services..."
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) build

up: check-env
	@echo "🚀 Starting services in $(ENV) mode..."
	@./env-check.sh $(ENV)
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) up -d
	@echo "✅ Services started"
	@make status

up-with-redis: check-env
	@echo "🚀 Starting services with Redis in $(ENV) mode..."
	@./env-check.sh $(ENV)
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) --profile with-redis up -d
	@echo "✅ Services with Redis started"
	@make status

down: check-env
	@echo "🛑 Stopping services..."
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) down

down-volumes: check-env
	@echo "🗑️  Stopping services and removing volumes..."
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) down -v

restart: check-env
	@echo "🔄 Restarting services..."
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) restart

# Service management
logs: check-env
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) logs -f

logs-backend: check-env
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) logs -f backend

logs-proxy: check-env
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) logs -f proxy

logs-db: check-env
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) logs -f db

status: check-env
	@echo "📊 Service Status:"
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) ps

health: check-env
	@echo "🏥 Health Check:"
	@docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

# Development helpers
shell-backend: check-env
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) exec backend /bin/bash

shell-db: check-env
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) exec db psql -U $(shell grep POSTGRES_USER $(ENV_FILE) | cut -d'=' -f2) -d $(shell grep POSTGRES_DB $(ENV_FILE) | cut -d'=' -f2)

# Testing
test-local:
	@echo "🧪 Running comprehensive local tests..."
	@./test-local.sh

test-local-build:
	@echo "🧪 Running local tests with build..."
	@./test-local.sh --build

test-local-clean:
	@echo "🧪 Running local tests with cleanup..."
	@./test-local.sh --cleanup --build

test-endpoints: check-env
	@echo "🧪 Testing endpoints..."
	@source $(ENV_FILE) && \
	PORT=$${PROXY_HTTP_PORT:-80} && \
	echo "Testing http://localhost:$$PORT/healthz" && \
	curl -s "http://localhost:$$PORT/healthz" | jq . || echo "❌ /healthz failed" && \
	echo "Testing http://localhost:$$PORT/api/version" && \
	curl -s "http://localhost:$$PORT/api/version" | jq . || echo "❌ /api/version failed"

# Maintenance
clean:
	@echo "🧹 Cleaning up..."
	docker system prune -f
	docker volume prune -f

backup-db: check-env
	@echo "💾 Backing up database..."
	@source $(ENV_FILE) && \
	mkdir -p ../backups && \
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) exec -T db pg_dump \
		-U $$POSTGRES_USER -d $$POSTGRES_DB > ../backups/db-backup-$$(date +%Y%m%d_%H%M%S).sql
	@echo "✅ Database backup completed"

# Cloudflare Tunnel
tunnel-setup:
	@echo "🌐 Setting up Cloudflare Tunnel..."
	@cd cloudflared && ./setup-tunnel.sh

tunnel-start:
	@echo "🚀 Starting Cloudflare Tunnel..."
	@cd cloudflared && ./manage-tunnel.sh start

tunnel-stop:
	@echo "🛑 Stopping Cloudflare Tunnel..."
	@cd cloudflared && ./manage-tunnel.sh stop

tunnel-status:
	@echo "📊 Checking Cloudflare Tunnel status..."
	@cd cloudflared && ./manage-tunnel.sh status

tunnel-logs:
	@echo "📜 Showing Cloudflare Tunnel logs..."
	@cd cloudflared && ./manage-tunnel.sh logs

tunnel-restart:
	@echo "🔄 Restarting Cloudflare Tunnel..."
	@cd cloudflared && ./manage-tunnel.sh restart

# Auto-start setup
autostart-setup:
	@echo "🚀 Setting up auto-start services..."
	@cd launchd && ./setup-autostart.sh

autostart-status:
	@echo "📊 Checking auto-start services status..."
	@launchctl list | grep -E "(llmclass|cloudflared)" || echo "No auto-start services found"

autostart-logs:
	@echo "📜 Showing auto-start logs..."
	@echo "=== Services Log ==="
	@tail -20 logs/services.log 2>/dev/null || echo "No services log found"
	@echo ""
	@echo "=== Watchdog Log ==="
	@tail -20 logs/watchdog.log 2>/dev/null || echo "No watchdog log found"

# Deployment
deploy: setup-prod build
	@echo "🚀 Deploying to production..."
	@make up ENV=prod
	@sleep 10
	@make test-endpoints ENV=prod
	@echo "✅ Deployment completed"

# Frontend development
dev-frontend: check-env
	@echo "🚀 Starting frontend development server..."
	@cd ../frontend && npm install && npm run dev

dev-backend: check-env
	@echo "🚀 Starting backend + database for development..."
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) up -d db backend
	@echo "✅ Backend services started"
	@echo "📝 Frontend: cd ../frontend && npm run dev"
	@echo "📝 Backend: http://localhost:8000"
	@echo "📝 Database: localhost:5432"

dev-full: check-env
	@echo "🚀 Starting full development environment..."
	@make dev-backend ENV=$(ENV)
	@make dev-frontend ENV=$(ENV)

# Help
help:
	@echo "🚀 mono-class-platform Docker Commands"
	@echo ""
	@echo "Environment Setup:"
	@echo "  setup-dev     Setup development environment"
	@echo "  setup-prod    Setup production environment"
	@echo ""
	@echo "Service Management:"
	@echo "  up            Start services (default: ENV=dev)"
	@echo "  down          Stop services"
	@echo "  restart       Restart services"
	@echo "  build         Build services"
	@echo ""
	@echo "Development:"
	@echo "  dev-frontend  Start frontend dev server (Vite)"
	@echo "  dev-backend   Start backend + database only"
	@echo "  dev-full      Start full dev environment"
	@echo ""
	@echo "Monitoring:"
	@echo "  status        Show service status"
	@echo "  health        Show health status"
	@echo "  logs          Show all logs"
	@echo "  logs-backend  Show backend logs"
	@echo "  logs-proxy    Show proxy logs"
	@echo ""
	@echo "Development Tools:"
	@echo "  shell-backend Enter backend container"
	@echo "  shell-db      Enter database"
	@echo "  test-local     Run comprehensive local tests"
	@echo "  test-local-build Run local tests with image rebuild"
	@echo "  test-local-clean Run local tests with cleanup"
	@echo "  test-endpoints Test API endpoints"
	@echo ""
	@echo "Maintenance:"
	@echo "  backup-db     Backup database"
	@echo "  clean         Clean Docker resources"
	@echo ""
	@echo "Cloudflare Tunnel:"
	@echo "  tunnel-setup  Setup new Cloudflare Tunnel"
	@echo "  tunnel-start  Start tunnel"
	@echo "  tunnel-stop   Stop tunnel"
	@echo "  tunnel-status Check tunnel status"
	@echo "  tunnel-logs   Show tunnel logs"
	@echo "  tunnel-restart Restart tunnel"
	@echo ""
	@echo "Auto-start (macOS):"
	@echo "  autostart-setup  Setup auto-start services"
	@echo "  autostart-status Check auto-start status"
	@echo "  autostart-logs   Show auto-start logs"
	@echo ""
	@echo "Usage Examples:"
	@echo "  make dev-full ENV=dev   # Full development setup"
	@echo "  make up ENV=dev         # Start in development"
	@echo "  make up ENV=prod        # Start in production"
	@echo "  make logs ENV=prod      # View production logs"

.PHONY: check-env setup-dev setup-prod build up down restart logs status health test-local test-local-build test-local-clean test-endpoints clean backup-db tunnel-setup tunnel-start tunnel-stop tunnel-status tunnel-logs tunnel-restart autostart-setup autostart-status autostart-logs deploy dev-frontend dev-backend dev-full help