PYTHON ?= python3

.PHONY: validate test preset health install update uninstall build-images analyze-structure

validate:
	$(PYTHON) scripts/validate_repo.py

analyze-structure:
	$(PYTHON) scripts/analyze_project_structure.py

test:
	$(PYTHON) -m unittest discover -s tests -p 'test_*.py'

preset:
	@if [ -z "$(PRESET)" ]; then echo "Usage: make preset PRESET=standard OUTPUT=./docker-compose.yml"; exit 2; fi
	@if [ -z "$(OUTPUT)" ]; then echo "Usage: make preset PRESET=standard OUTPUT=./docker-compose.yml"; exit 2; fi
	$(PYTHON) scripts/select_compose_preset.py --preset $(PRESET) --output $(OUTPUT)

health:
	$(PYTHON) scripts/check_health.py --compose-file $(if $(COMPOSE_FILE),$(COMPOSE_FILE),docker-compose.yml)

install:
	@echo "Running CyberPot install workflow..."
	@bash ./install.sh

update:
	@echo "Running CyberPot update workflow..."
	@bash ./update.sh -y

uninstall:
	@echo "Running CyberPot uninstall workflow..."
	@bash ./uninstall.sh

build-images:
	$(PYTHON) scripts/build_images.py --target $(TARGET) --output-dir $(if $(OUTPUT_DIR),$(OUTPUT_DIR),./build/images) --dry-run
