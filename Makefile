# pgschema Demo Makefile
# Provides convenient commands for running the demo

.PHONY: help setup start stop clean demo test install-pgschema check-deps

# Default target
help: ## Show this help message
	@echo "pgschema PostgreSQL Community Demo"
	@echo "=================================="
	@echo ""
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

setup: check-deps ## Set up the demo environment
	@echo "🚀 Setting up pgschema demo environment..."
	@cp .env.example .env 2>/dev/null || true
	@docker-compose up -d
	@echo "⏳ Waiting for PostgreSQL to be ready..."
	@sleep 10
	@docker-compose exec -T postgres pg_isready -U demo -d demo
	@echo "✅ Demo environment ready!"

start: ## Start PostgreSQL database
	@echo "🐘 Starting PostgreSQL database..."
	@docker-compose up -d
	@echo "⏳ Waiting for database to be ready..."
	@sleep 5
	@docker-compose exec -T postgres pg_isready -U demo -d demo
	@echo "✅ Database is ready!"

stop: ## Stop PostgreSQL database
	@echo "🛑 Stopping PostgreSQL database..."
	@docker-compose stop

clean: ## Clean up demo environment (removes all data)
	@echo "🧹 Cleaning up demo environment..."
	@docker-compose down -v
	@docker system prune -f
	@echo "✅ Cleanup complete!"

demo: setup ## Run the interactive demo
	@echo "🎬 Starting pgschema demo..."
	@chmod +x demo.sh
	@./demo.sh

test: setup ## Run demo tests
	@echo "🧪 Running demo tests..."
	@chmod +x test.sh
	@./test.sh

install-pgschema: ## Install pgschema CLI tool
	@echo "📦 Installing pgschema..."
	@go install github.com/pgschema/pgschema@latest
	@echo "✅ pgschema installed!"
	@pgschema --version

check-deps: ## Check if required dependencies are installed
	@echo "🔍 Checking dependencies..."
	@command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required but not installed. Please install Docker first."; exit 1; }
	@command -v docker-compose >/dev/null 2>&1 || { echo "❌ Docker Compose is required but not installed. Please install Docker Compose first."; exit 1; }
	@command -v go >/dev/null 2>&1 || { echo "❌ Go is required but not installed. Please install Go 1.21+ first."; exit 1; }
	@echo "✅ All dependencies are installed!"

status: ## Show status of demo environment
	@echo "📊 Demo Environment Status"
	@echo "========================="
	@echo ""
	@echo "Docker containers:"
	@docker-compose ps
	@echo ""
	@echo "PostgreSQL connection test:"
	@docker-compose exec -T postgres pg_isready -U demo -d demo || echo "❌ Database not ready"
	@echo ""
	@echo "pgschema version:"
	@pgschema --version 2>/dev/null || echo "❌ pgschema not installed"

logs: ## Show PostgreSQL logs
	@docker-compose logs -f postgres

psql: ## Connect to PostgreSQL with psql
	@docker-compose exec postgres psql -U demo -d demo

reset: clean setup ## Reset the entire demo environment
	@echo "🔄 Demo environment has been reset!"

# Development targets
dev-setup: setup install-pgschema ## Set up development environment
	@echo "🛠️  Development environment ready!"

quick-demo: ## Run demo without setup (assumes environment is ready)
	@chmod +x demo.sh
	@./demo.sh