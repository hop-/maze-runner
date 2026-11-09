# Maze Runner build automation. Run `make` or `make help` for the targets.
#
# Builds are single-file exports (PCK embedded) from export_presets.cfg.
# Variables: GODOT=/path/to/godot   BUILD=release|debug

SHELL := /bin/bash
.DEFAULT_GOAL := help

GODOT ?= godot
BUILD ?= release
NAME  := maze-runner

# "4.7.2.stable.arch_linux.ed1daf0bf" -> "4.7.2.stable" (templates folder name)
GODOT_VERSION := $(shell $(GODOT) --version 2>/dev/null | sed -E 's/^([0-9.]+[a-z]+[0-9]*)\..*/\1/')
# "4.7.2.stable" -> "4.7.2-stable" (GitHub release tag)
RELEASE_TAG   := $(shell echo '$(GODOT_VERSION)' | sed -E 's/\.([a-z]+[0-9]*)$$/-\1/')
TEMPLATES_DIR := $(or $(XDG_DATA_HOME),$(HOME)/.local/share)/godot/export_templates/$(GODOT_VERSION)
TEMPLATES_URL := https://github.com/godotengine/godot/releases/download/$(RELEASE_TAG)/Godot_v$(RELEASE_TAG)_export_templates.tpz

OUT_DIR     := build/$(BUILD)
LINUX_BIN   := $(OUT_DIR)/linux/$(NAME)
WINDOWS_BIN := $(OUT_DIR)/windows/$(NAME).exe
LINUX_PKG   := $(OUT_DIR)/$(NAME)-linux-x86_64.tar.gz
WINDOWS_PKG := $(OUT_DIR)/$(NAME)-windows-x86_64.zip

# Everything that ends up in the game; a change re-exports.
SOURCES := project.godot export_presets.cfg icon.svg $(shell find scenes scripts -type f 2>/dev/null)
IMPORT_STAMP := .godot/.make-imported

.PHONY: help run edit test linux windows all dist templates check-templates clean distclean

help: ## Show this help
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  \033[1m%-16s\033[0m %s\n", $$1, $$2}'
	@echo "  Godot $(or $(GODOT_VERSION),NOT FOUND)  BUILD=$(BUILD)  output: $(OUT_DIR)/"

run: ## Play the game
	$(GODOT) --path .

edit: ## Open the project in the Godot editor
	$(GODOT) --editor --path .

test: $(IMPORT_STAMP) ## Run the headless tests
	$(GODOT) --headless --path . --script res://tests/test_maze.gd

linux: $(LINUX_BIN) ## Export the Linux x86_64 build

windows: $(WINDOWS_BIN) ## Export the Windows x86_64 build

all: linux windows ## Export every target

dist: $(LINUX_PKG) $(WINDOWS_PKG) ## Export and package archives to share

templates: ## Download and install export templates for this Godot version (~1 GB)
	@test -n "$(GODOT_VERSION)" || { echo "error: '$(GODOT)' not found" >&2; exit 1; }
	@if [ -d "$(TEMPLATES_DIR)" ]; then echo "templates already installed: $(TEMPLATES_DIR)"; exit 0; fi; \
	tmp=$$(mktemp -d); trap 'rm -rf "$$tmp"' EXIT; \
	echo "downloading $(TEMPLATES_URL)"; \
	curl -fL --progress-bar -o "$$tmp/templates.tpz" "$(TEMPLATES_URL)"; \
	unzip -q "$$tmp/templates.tpz" -d "$$tmp"; \
	mkdir -p "$(dir $(TEMPLATES_DIR))"; \
	mv "$$tmp/templates" "$(TEMPLATES_DIR)"; \
	echo "installed: $(TEMPLATES_DIR)"

check-templates:
	@test -d "$(TEMPLATES_DIR)" || { \
		echo "error: export templates for Godot $(GODOT_VERSION) are missing." >&2; \
		echo "       run 'make templates', or install them in the editor:" >&2; \
		echo "       Editor > Manage Export Templates." >&2; exit 1; }

clean: ## Remove build output
	rm -rf build

distclean: clean ## Also remove Godot's import cache (.godot/)
	rm -rf .godot

# --- file targets --------------------------------------------------------------

# Builds the global class cache that --script runs (the tests) rely on.
$(IMPORT_STAMP): $(SOURCES)
	$(GODOT) --headless --path . --import
	@touch $@

$(LINUX_BIN): $(SOURCES) | check-templates
	@mkdir -p $(@D)
	$(GODOT) --headless --path . --export-$(BUILD) "Linux" $@

$(WINDOWS_BIN): $(SOURCES) | check-templates
	@mkdir -p $(@D)
	$(GODOT) --headless --path . --export-$(BUILD) "Windows" $@

$(LINUX_PKG): $(LINUX_BIN)
	tar -czf $@ -C $(<D) $(<F)

$(WINDOWS_PKG): $(WINDOWS_BIN)
	cd $(<D) && zip -q -9 $(abspath $@) $(<F)
