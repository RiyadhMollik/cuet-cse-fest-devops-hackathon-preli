.PHONY: help up down build logs restart shell ps dev-up dev-down dev-build dev-logs dev-restart dev-shell dev-ps backend-shell gateway-shell mongo-shell prod-up prod-down prod-build prod-logs prod-restart backend-build backend-install backend-type-check backend-dev db-reset db-backup clean clean-all clean-volumes status health

# Default mode is development
MODE ?= dev
SERVICE ?= backend
ARGS ?=

# Docker Compose file selection
ifeq ($(MODE),prod)
	COMPOSE_FILE = docker/compose.production.yaml
	COMPOSE_ENV = production
else
	COMPOSE_FILE = docker/compose.development.yaml
	COMPOSE_ENV = development
endif

# Docker Compose command
DC = docker compose -f $(COMPOSE_FILE) --env-file .env

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

#=============================================================================
# Help
#=============================================================================

help: ## Display this help message
	@echo "$(GREEN)╔══════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║         CUET CSE Fest DevOps Hackathon - Makefile Help          ║$(NC)"
	@echo "$(GREEN)╚══════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)Docker Services:$(NC)"
	@echo "  make up [MODE=dev|prod] [ARGS='--build']  - Start services"
	@echo "  make down [MODE=dev|prod] [ARGS='--volumes'] - Stop services"
	@echo "  make build [MODE=dev|prod]                - Build containers"
	@echo "  make logs [SERVICE=name] [MODE=dev|prod]  - View logs"
	@echo "  make restart [MODE=dev|prod]              - Restart services"
	@echo "  make shell [SERVICE=backend|gateway] [MODE=dev|prod] - Open shell"
	@echo "  make ps [MODE=dev|prod]                   - Show running containers"
	@echo ""
	@echo "$(YELLOW)Development Aliases:$(NC)"
	@echo "  make dev-up           - Start development environment"
	@echo "  make dev-down         - Stop development environment"
	@echo "  make dev-build        - Build development containers"
	@echo "  make dev-logs         - View development logs"
	@echo "  make dev-restart      - Restart development services"
	@echo "  make dev-shell        - Open shell in backend container"
	@echo "  make backend-shell    - Open shell in backend container"
	@echo "  make gateway-shell    - Open shell in gateway container"
	@echo "  make mongo-shell      - Open MongoDB shell"
	@echo ""
	@echo "$(YELLOW)Production Aliases:$(NC)"
	@echo "  make prod-up          - Start production environment"
	@echo "  make prod-down        - Stop production environment"
	@echo "  make prod-build       - Build production containers"
	@echo "  make prod-logs        - View production logs"
	@echo "  make prod-restart     - Restart production services"
	@echo ""
	@echo "$(YELLOW)Backend Commands:$(NC)"
	@echo "  make backend-build    - Build backend TypeScript"
	@echo "  make backend-install  - Install backend dependencies"
	@echo "  make backend-type-check - Type check backend code"
	@echo "  make backend-dev      - Run backend in development mode (local)"
	@echo ""
	@echo "$(YELLOW)Database Commands:$(NC)"
	@echo "  make db-reset [MODE=dev|prod] - Reset MongoDB database (WARNING: deletes all data)"
	@echo "  make db-backup [MODE=dev|prod] - Backup MongoDB database"
	@echo ""
	@echo "$(YELLOW)Cleanup Commands:$(NC)"
	@echo "  make clean            - Remove containers and networks"
	@echo "  make clean-all        - Remove containers, networks, volumes, and images"
	@echo "  make clean-volumes    - Remove all volumes"
	@echo ""
	@echo "$(YELLOW)Utility Commands:$(NC)"
	@echo "  make status [MODE=dev|prod] - Show container status"
	@echo "  make health [MODE=dev|prod] - Check service health"
	@echo ""

#=============================================================================
# Docker Services
#=============================================================================

up: ## Start services
	@echo "$(GREEN)Starting $(COMPOSE_ENV) environment...$(NC)"
	@$(DC) up -d $(ARGS)
	@echo "$(GREEN)Services started successfully!$(NC)"
	@echo "$(YELLOW)Gateway available at: http://localhost:5921$(NC)"

down: ## Stop services
	@echo "$(YELLOW)Stopping $(COMPOSE_ENV) environment...$(NC)"
	@$(DC) down $(ARGS)
	@echo "$(GREEN)Services stopped successfully!$(NC)"

build: ## Build containers
	@echo "$(GREEN)Building $(COMPOSE_ENV) containers...$(NC)"
	@$(DC) build $(ARGS)
	@echo "$(GREEN)Build completed successfully!$(NC)"

logs: ## View logs
	@$(DC) logs -f $(SERVICE)

restart: ## Restart services
	@echo "$(YELLOW)Restarting $(COMPOSE_ENV) services...$(NC)"
	@$(DC) restart $(ARGS)
	@echo "$(GREEN)Services restarted successfully!$(NC)"

shell: ## Open shell in container
	@echo "$(GREEN)Opening shell in $(SERVICE) container...$(NC)"
	@$(DC) exec $(SERVICE) sh

ps: ## Show running containers
	@$(DC) ps

#=============================================================================
# Development Aliases
#=============================================================================

dev-up: ## Start development environment
	@$(MAKE) up MODE=dev

dev-down: ## Stop development environment
	@$(MAKE) down MODE=dev

dev-build: ## Build development containers
	@$(MAKE) build MODE=dev

dev-logs: ## View development logs
	@$(MAKE) logs MODE=dev

dev-restart: ## Restart development services
	@$(MAKE) restart MODE=dev

dev-shell: ## Open shell in backend container (dev)
	@$(MAKE) shell MODE=dev SERVICE=backend

dev-ps: ## Show running development containers
	@$(MAKE) ps MODE=dev

backend-shell: ## Open shell in backend container
	@$(MAKE) shell SERVICE=backend

gateway-shell: ## Open shell in gateway container
	@$(MAKE) shell SERVICE=gateway

mongo-shell: ## Open MongoDB shell
	@echo "$(GREEN)Opening MongoDB shell...$(NC)"
	@$(DC) exec mongo mongosh -u $$(grep MONGO_INITDB_ROOT_USERNAME .env | cut -d '=' -f2) -p $$(grep MONGO_INITDB_ROOT_PASSWORD .env | cut -d '=' -f2) --authenticationDatabase admin

#=============================================================================
# Production Aliases
#=============================================================================

prod-up: ## Start production environment
	@$(MAKE) up MODE=prod

prod-down: ## Stop production environment
	@$(MAKE) down MODE=prod

prod-build: ## Build production containers
	@$(MAKE) build MODE=prod

prod-logs: ## View production logs
	@$(MAKE) logs MODE=prod

prod-restart: ## Restart production services
	@$(MAKE) restart MODE=prod

#=============================================================================
# Backend Commands
#=============================================================================

backend-build: ## Build backend TypeScript
	@echo "$(GREEN)Building backend...$(NC)"
	@cd backend && npm run build
	@echo "$(GREEN)Backend built successfully!$(NC)"

backend-install: ## Install backend dependencies
	@echo "$(GREEN)Installing backend dependencies...$(NC)"
	@cd backend && npm install
	@echo "$(GREEN)Dependencies installed successfully!$(NC)"

backend-type-check: ## Type check backend code
	@echo "$(GREEN)Type checking backend...$(NC)"
	@cd backend && npm run type-check
	@echo "$(GREEN)Type check completed!$(NC)"

backend-dev: ## Run backend in development mode (local, not Docker)
	@echo "$(GREEN)Starting backend in development mode...$(NC)"
	@cd backend && npm run dev

#=============================================================================
# Database Commands
#=============================================================================

db-reset: ## Reset MongoDB database (WARNING: deletes all data)
	@echo "$(RED)WARNING: This will delete all data in the database!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "$(YELLOW)Resetting database...$(NC)"; \
		$(DC) exec mongo mongosh -u $$(grep MONGO_INITDB_ROOT_USERNAME .env | cut -d '=' -f2) -p $$(grep MONGO_INITDB_ROOT_PASSWORD .env | cut -d '=' -f2) --authenticationDatabase admin --eval "db.getSiblingDB('$$(grep MONGO_DATABASE .env | cut -d '=' -f2)').dropDatabase()"; \
		echo "$(GREEN)Database reset successfully!$(NC)"; \
	else \
		echo "$(YELLOW)Database reset cancelled.$(NC)"; \
	fi

db-backup: ## Backup MongoDB database
	@echo "$(GREEN)Creating database backup...$(NC)"
	@mkdir -p backups
	@$(DC) exec -T mongo mongodump --username $$(grep MONGO_INITDB_ROOT_USERNAME .env | cut -d '=' -f2) --password $$(grep MONGO_INITDB_ROOT_PASSWORD .env | cut -d '=' -f2) --authenticationDatabase admin --db $$(grep MONGO_DATABASE .env | cut -d '=' -f2) --archive > backups/mongodb-backup-$$(date +%Y%m%d-%H%M%S).archive
	@echo "$(GREEN)Backup created successfully in backups/ directory!$(NC)"

#=============================================================================
# Cleanup Commands
#=============================================================================

clean: ## Remove containers and networks (both dev and prod)
	@echo "$(YELLOW)Cleaning up containers and networks...$(NC)"
	@docker compose -f docker/compose.development.yaml down 2>/dev/null || true
	@docker compose -f docker/compose.production.yaml down 2>/dev/null || true
	@echo "$(GREEN)Cleanup completed!$(NC)"

clean-all: ## Remove containers, networks, volumes, and images
	@echo "$(RED)WARNING: This will remove all containers, networks, volumes, and images!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "$(YELLOW)Cleaning up everything...$(NC)"; \
		docker compose -f docker/compose.development.yaml down -v --rmi all 2>/dev/null || true; \
		docker compose -f docker/compose.production.yaml down -v --rmi all 2>/dev/null || true; \
		echo "$(GREEN)Full cleanup completed!$(NC)"; \
	else \
		echo "$(YELLOW)Cleanup cancelled.$(NC)"; \
	fi

clean-volumes: ## Remove all volumes
	@echo "$(RED)WARNING: This will remove all volumes and data!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "$(YELLOW)Removing volumes...$(NC)"; \
		docker compose -f docker/compose.development.yaml down -v 2>/dev/null || true; \
		docker compose -f docker/compose.production.yaml down -v 2>/dev/null || true; \
		echo "$(GREEN)Volumes removed!$(NC)"; \
	else \
		echo "$(YELLOW)Volume removal cancelled.$(NC)"; \
	fi

#=============================================================================
# Utility Commands
#=============================================================================

status: ps ## Alias for ps

health: ## Check service health
	@echo "$(GREEN)Checking service health...$(NC)"
	@echo ""
	@echo "$(YELLOW)Gateway Health:$(NC)"
	@curl -s http://localhost:5921/health | jq '.' || echo "$(RED)Gateway is not responding$(NC)"
	@echo ""
	@echo "$(YELLOW)Backend Health (via Gateway):$(NC)"
	@curl -s http://localhost:5921/api/health | jq '.' || echo "$(RED)Backend is not responding$(NC)"
	@echo ""

