# NTIL REBUS-GROK Makefile
# One-command operations for development and deployment

.PHONY: help setup dev test build deploy clean

# Default target
help:
	@echo "╔════════════════════════════════════════════════════════╗"
	@echo "║ NTIL REBUS-GROK Build System                           ║"
	@echo "╚════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Available commands:"
	@echo " make setup                - Initial project setup"
	@echo " make dev                  - Start development environment"
	@echo " make test                 - Run all tests"
	@echo " make build                - Build production artifacts"
	@echo " make deploy-staging       - Deploy to staging"
	@echo " make deploy-production    - Deploy to production"
	@echo " make clean                - Clean build artifacts"
	@echo ""

# Initial setup
setup:
	@echo "Setting up NTIL REBUS-GROK..."
	@cp -n .env.example .env || true
	@cd backend && mvn dependency:resolve -q
	@cd frontend && npm install
	@docker compose -f deploy/docker-compose.yml pull
	@echo "✅ Setup complete. Edit .env with your configuration."

# Development environment
dev:
	@echo "Starting development environment..."
	@docker compose -f deploy/docker-compose.dev.yml up -d postgres redis
	@echo "Waiting for services..."
	@sleep 5
	@cd backend && mvn spring-boot:run & 
	@cd frontend && npm start

# Run tests
test:
	@echo "Running tests..."
	@cd backend && mvn verify
	@cd frontend && npm test -- --watchAll=false

# Build production
build:
	@echo "Building production artifacts..."
	@cd backend && mvn clean package -DskipTests
	@cd frontend && npm run build
	@docker build -t ghcr.io/ntil/rebus-grok/backend:latest ./backend
	@docker build -t ghcr.io/ntil/rebus-grok/frontend:latest ./frontend
	@echo "✅ Build complete"

# Deploy staging
deploy-staging:
	@echo "Deploying to staging..."
	@./deploy/scripts/deploy.sh staging

# Deploy production
deploy-production:
	@echo "Deploying to production..."
	@./deploy/scripts/deploy.sh production

# Clean
clean:
	@echo "Cleaning build artifacts..."
	@cd backend && mvn clean
	@cd frontend && rm -rf build node_modules
	@docker compose -f deploy/docker-compose.yml down -v
	@echo "✅ Clean complete"
