GO ?= go
GO_TOOL := $(GO) -C ./tools run -mod=mod

ROOT = spec
DIST = dist
SPEC = openapi.yaml
OUTPUT = /tmp/swagger.yaml

REDOCLY := npx @redocly/cli
REDOCLY_BUNDLE_FLAGS := --remove-unused-components
REDOCLY_DOCS_FLAGS := --disableGoogleFont

SCHEMAS := $(shell find $(ROOT)/schemas -type f)
SCHEMAS_SOURCES = $(shell find $(ROOT) -maxdepth 1 -name '*.yaml')
SCHEMAS_FINAL = $(SCHEMAS_SOURCES:$(ROOT)/%.yaml=$(DIST)/specs/%.yaml)

GOMPLATE = github.com/hairyhenderson/gomplate/v4/cmd/gomplate
GOMPLATE_TEMPLATE = spec/templates/resource.yaml.tpl
GOMPLATE_SOURCES = $(shell find $(ROOT)/resources -type f -name '*.yaml')
GOMPLATE_FINAL = $(GOMPLATE_SOURCES:$(ROOT)/resources/%.yaml=$(ROOT)/%.yaml)

VACUUM = github.com/daveshanley/vacuum
VACUUM_LINT_FLAGS := -r $(CURDIR)/config/ruleset-recommended.yaml -b

BLUE  = \033[1;34m
GREEN = \033[1;32m
YELLOW = \033[1;33m
RESET = \033[0m

.PHONY: all build resource-apis lint clean tag

all: clean build lint

build: $(DIST) resource-apis $(SCHEMAS_FINAL)

resource-apis:
	@echo "$(BLUE)Generating OpenAPI resources with gomplate...$(RESET)"
	@for f in $(GOMPLATE_SOURCES); do \
		group="$$($(GO_TOOL) $(GOMPLATE) -d spec=$(CURDIR)/$$f -i '{{ (ds "spec").group }}')"; \
		name="$$($(GO_TOOL) $(GOMPLATE) -d spec=$(CURDIR)/$$f -i '{{ (ds "spec").name }}' | tr '[:upper:]' '[:lower:]' | tr -d ' -')"; \
		version="$$($(GO_TOOL) $(GOMPLATE) -d spec=$(CURDIR)/$$f -i '{{ (ds "spec").version }}')"; \
		out="$(ROOT)/$${group}.$${name}.$${version}.yaml"; \
		echo "$(GREEN)→ $$out$(RESET) from $$f"; \
		$(GO_TOOL) $(GOMPLATE) -d spec=$(CURDIR)/$$f -f $(CURDIR)/$(GOMPLATE_TEMPLATE) -o $(CURDIR)/$$out; \
	done

$(DIST):
	@mkdir -p $(DIST)

$(ROOT)/%.yaml: $(ROOT)/resources/%.yaml $(GOMPLATE_TEMPLATE) $(SCHEMAS) | resource-apis
	@$(GO_TOOL) $(GOMPLATE) -d spec=$(CURDIR)/$< -f $(CURDIR)/$(GOMPLATE_TEMPLATE) -o $(CURDIR)/$@

$(DIST)/specs/%.yaml: $(ROOT)/%.yaml $(SCHEMAS)
	@mkdir -p $(dir $@)
	@$(REDOCLY) bundle $(REDOCLY_BUNDLE_FLAGS) $< --output=$@

lint: resource-apis
	@echo "$(YELLOW)Linting OpenAPI specs...$(RESET)"
	@$(MAKE) $(SCHEMAS_FINAL)
	@SCHEMAS="$$(find $(CURDIR)/$(DIST)/specs -type f -name '*.yaml')"; \
	if [ -z "$$SCHEMAS" ]; then \
		echo "$(YELLOW)⚠️  No OpenAPI specs found to lint.$(RESET)"; \
		exit 1; \
	fi; \
	$(GO_TOOL) $(VACUUM) lint $(VACUUM_LINT_FLAGS) -d $$SCHEMAS --fail-severity warn

clean:
	@echo "$(BLUE)Cleaning up...$(RESET)"
	@rm -rf $(DIST) $(OUTPUT) $(ROOT)/*.yaml

tag:
	@if [ -z "$(VERSION)" ]; then \
		echo "ERROR: VERSION is required. Usage: make tag VERSION=v0.1.0"; \
		exit 1; \
	fi
	@echo "Tagging $(VERSION)..."
	git tag $(VERSION)
	git push origin $(VERSION)
