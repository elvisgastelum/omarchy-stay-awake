PLUGIN_ID  := elvisgastelum.stay-awake
REPO_URL   := https://github.com/elvisgastelum/omarchy-stay-awake.git
PLUGIN_DIR := $(HOME)/.config/omarchy/plugins/$(PLUGIN_ID)

.DEFAULT_GOAL := help
.PHONY: help install update uninstall enable disable test validate check dev

help: ## Show this help
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  make %-10s %s\n", $$1, $$2}'

install: ## Install from GitHub and put it on the bar (omarchy plugin add)
	omarchy plugin add $(REPO_URL) --enable

update: ## Pull the latest version of the installed plugin
	omarchy plugin update $(PLUGIN_ID)

uninstall: ## Remove the plugin
	omarchy plugin remove $(PLUGIN_ID)

enable: ## Put the widget on the bar
	omarchy plugin enable $(PLUGIN_ID)

disable: ## Take the widget off the bar
	omarchy plugin disable $(PLUGIN_ID)

test: ## Run the model tests and check the JSON files parse
	node tests/model.test.mjs
	@for f in manifest.json i18n/*.json; do jq empty "$$f" || exit 1; done
	@echo "json ok"

validate: ## Validate the manifest against Omarchy's plugin schema
	omarchy plugin validate .

check: test validate ## Run test and validate

dev: check ## Copy this working tree over the installed plugin and restart the shell
	@test -d "$(PLUGIN_DIR)" || { echo "Not installed; run 'make install' first."; exit 1; }
	rsync -a --delete --exclude .git ./ "$(PLUGIN_DIR)/"
	omarchy restart shell
