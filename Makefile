.PHONY: help install lint test run server-info docker-build docker-run compose-up compose-down compose-logs ansible-check ansible-dry ansible-run

GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
RESET  := $(shell tput -Txterm sgr0)

help: ## Show this help message
	@echo 'Usage:'
	@echo '  ${YELLOW}make <target>${RESET}'
	@echo ''
	@echo 'Targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2}'

install: ## Install Python dependencies
	pip install -r app/requirements.txt

lint: ## Lint Python and Bash code
	@echo "Linting Python with flake8..."
	flake8 app/*.py app/tests/*.py || true
	@echo "Linting Bash scripts with shellcheck..."
	shellcheck scripts/*.sh

test: ## Run pytest
	pytest app/tests/ -v

run: ## Run Flask app locally
	python app/main.py

server-info: ## Run server diagnostics (no URL checks)
	./scripts/server-info.sh

docker-build: ## Build Docker image
	docker build -t simple-app:latest .

docker-run: ## Run Docker container
	docker run -d --name simple-app -p 5000:5000 simple-app:latest
	@echo "Container started. Logs: docker logs -f simple-app"

compose-up: ## Start services with Docker Compose
	docker compose up -d

compose-down: ## Stop Docker Compose services
	docker compose down

compose-logs: ## View logs from Docker Compose
	docker compose logs -f

ansible-check: ## Check Ansible playbook syntax
	ansible-playbook --syntax-check -i ansible/inventory.ini ansible/playbook.yml

ansible-dry: ## Dry-run Ansible playbook
	ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --check

ansible-run: ## Run Ansible playbook
	ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
