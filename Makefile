PYTHON ?= python3

# Colors
GREEN := \033[0;32m
NC := \033[0m

.PHONY: help setup validate test preset health install update uninstall build-images analyze-structure

help: ## Show this help message
	@echo ''
	@echo "$(GREEN)═══════════════════════════════════════════════════════════════════$(NC)"
	@echo "$(GREEN)                    CYBERPOT MAKEFILE COMMANDS                     $(NC)"
	@echo "$(GREEN)═══════════════════════════════════════════════════════════════════$(NC)"
	@echo ''
	@echo "$(GREEN)Basic Commands:$(NC)"
	@echo "  $(GREEN)make install$(NC)       - Run the install workflow"
	@echo "  $(GREEN)make update$(NC)        - Run the update workflow"
	@echo "  $(GREEN)make uninstall$(NC)     - Run the uninstall workflow"
	@echo "  $(GREEN)make health$(NC)        - Check system health"
	@echo ''
	@echo "$(GREEN)Development Commands:$(NC)"
	@echo "  $(GREEN)make setup$(NC)        - Set up development environment"
	@echo "  $(GREEN)make validate$(NC)      - Validate repository structure"
	@echo "  $(GREEN)make test$(NC)          - Run unit tests"
	@echo "  $(GREEN)make analyze-structure$(NC) - Analyze project structure"
	@echo ''
	@echo "$(GREEN)Docker Commands:$(NC)"
	@echo "  $(GREEN)make preset$(NC)        - Select a compose preset"
	@echo "    Usage: make preset PRESET=standard OUTPUT=./docker-compose.yml"
	@echo "  $(GREEN)make build-images$(NC)  - Build Docker images"
	@echo "    Usage: make build-images TARGET=cyberpot OUTPUT_DIR=./build/images"
	@echo ''
	@echo "$(GREEN)═══════════════════════════════════════════════════════════════════$(NC)"
	@echo ''

setup: ## Set up development environment
	bash scripts/setup_env.sh -p $(PYTHON)

validate: ## Validate repository structure
	$(PYTHON) scripts/validate_repo.py

analyze-structure: ## Analyze project structure
	$(PYTHON) scripts/analyze_project_structure.py

test: ## Run unit tests
	$(PYTHON) -m unittest discover -s tests -p 'test_*.py'

preset: ## Select a compose preset (requires PRESET and OUTPUT)
	@if [ -z "$(PRESET)" ]; then echo "Usage: make preset PRESET=standard OUTPUT=./docker-compose.yml"; exit 2; fi
	@if [ -z "$(OUTPUT)" ]; then echo "Usage: make preset PRESET=standard OUTPUT=./docker-compose.yml"; exit 2; fi
	$(PYTHON) scripts/select_compose_preset.py --preset $(PRESET) --output $(OUTPUT)

health: ## Check system health
	$(PYTHON) scripts/check_health.py --compose-file $(if $(COMPOSE_FILE),$(COMPOSE_FILE),docker-compose.yml)

install: ## Run the install workflow
	@echo "Running CyberPot install workflow..."
	@bash ./install.sh

update: ## Run the update workflow
	@echo "Running CyberPot update workflow..."
	@bash ./update.sh -y

uninstall: ## Run the uninstall workflow
	@echo "Running CyberPot uninstall workflow..."
	@bash ./uninstall.sh

build-images: ## Build Docker images (requires TARGET)
	$(PYTHON) scripts/build_images.py --target $(TARGET) --output-dir $(if $(OUTPUT_DIR),$(OUTPUT_DIR),./build/images) --dry-run

default: help

.DEFAULT_GOAL := help
