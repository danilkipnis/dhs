# index.html derives the whole network from the JSON tables in this directory.
# Most are transcribed by hand and read as-is; the three table-vi files are
# generated, so they can fall out of step with their source.

PY      ?= python3
PORT    ?= 8000

# The publish repo (git remote "essay5") holds only what the page needs to run,
# on a history unrelated to this one -- so it cannot be a second push target and
# is instead synced one-way by `make publish`. Its URL is read from the remote so
# it is not spelled out twice.
PUBLISH_URL    ?= $(shell git remote get-url essay5 2>/dev/null)
PUBLISH_BRANCH ?= main
PUBLISH_DIR    ?= .publish
PUBLISH_PUSH   ?= yes

# Generated from table-vi.json by convert-table-vi.py.
GENERATED := ms.json ms-membership.json table-vi-dharmas.json

# Read directly by index.html, no build step.
SOURCES := table-iii.json table-iv.json table-v.json table-v-content.json \
           table-v-content-footnotes.json table-v-mental.json \
           table-v-objects.json table-v-sphere.json table-v-thought.json \
           table-v-trancic.json table-vii.json Table-viii.json

# Everything index.html fetches at runtime, plus table-vi.json for reference.
# This is exactly the published file set -- build tooling and the table-*.html
# renderings stay in this repo only.
RUNTIME := index.html table-vi.json $(SOURCES) $(GENERATED)

.PHONY: all check serve clean publish help
.DEFAULT_GOAL := help

all: $(GENERATED)  ## Regenerate the table-vi files if table-vi.json is newer

# One recipe produces all three, so hang it off a stamp: without this make would
# run the converter once per target when several are out of date.
$(GENERATED): .table-vi.stamp
.table-vi.stamp: table-vi.json convert-table-vi.py
	$(PY) convert-table-vi.py
	@touch $@

check: ## Fail if the committed table-vi files differ from a fresh conversion
	@tmp=$$(mktemp -d) && trap 'rm -rf "$$tmp"' EXIT; \
	for f in $(GENERATED); do cp "$$f" "$$tmp/$$f" 2>/dev/null || true; done; \
	$(PY) convert-table-vi.py >/dev/null || exit 1; \
	status=0; \
	for f in $(GENERATED); do \
	  if ! diff -q "$$tmp/$$f" "$$f" >/dev/null 2>&1; then \
	    echo "STALE: $$f differs from a fresh convert-table-vi.py run"; status=1; \
	  fi; \
	done; \
	for f in $(SOURCES) table-vi.json index.html; do \
	  test -f "$$f" || { echo "MISSING: $$f"; status=1; }; \
	done; \
	if [ $$status -eq 0 ]; then echo "up to date: $(words $(GENERATED)) generated, $(words $(SOURCES)) source tables"; fi; \
	for f in $(GENERATED); do cp "$$tmp/$$f" "$$f" 2>/dev/null || true; done; \
	exit $$status

serve: all ## Serve over HTTP (fetch() is blocked on file:// URLs)
	@echo "http://localhost:$(PORT)/index.html"
	$(PY) -m http.server $(PORT)

publish: all check ## Sync the runtime files to the publish repo and push
	@test -n "$(PUBLISH_URL)" || { echo "no 'essay5' remote; set PUBLISH_URL="; exit 1; }
	@if [ ! -d $(PUBLISH_DIR)/.git ]; then \
	  echo "cloning $(PUBLISH_URL) -> $(PUBLISH_DIR)"; \
	  git clone --quiet --branch $(PUBLISH_BRANCH) $(PUBLISH_URL) $(PUBLISH_DIR); \
	fi
	@# "origin" here is the publish clone's own remote, not this repo's.
	@git -C $(PUBLISH_DIR) fetch --quiet origin $(PUBLISH_BRANCH)
	@git -C $(PUBLISH_DIR) checkout --quiet -B $(PUBLISH_BRANCH) origin/$(PUBLISH_BRANCH)
	@# Drop every tracked file, then copy the set back, so a file removed here is
	@# removed there too rather than lingering in the published tree.
	@git -C $(PUBLISH_DIR) rm -rq --ignore-unmatch .
	@cp $(RUNTIME) $(PUBLISH_DIR)/
	@git -C $(PUBLISH_DIR) add -A
	@if git -C $(PUBLISH_DIR) diff --cached --quiet; then \
	  echo "publish: already up to date ($(words $(RUNTIME)) files)"; \
	else \
	  git -C $(PUBLISH_DIR) diff --cached --stat | tail -n 12; \
	  git -C $(PUBLISH_DIR) commit -q -m "sync from dhs $$(git rev-parse --short HEAD)"; \
	  if [ "$(PUBLISH_PUSH)" = yes ]; then \
	    git -C $(PUBLISH_DIR) push --quiet origin $(PUBLISH_BRANCH) && \
	    echo "publish: pushed $$(git -C $(PUBLISH_DIR) rev-parse --short HEAD) to $(PUBLISH_BRANCH)"; \
	  else \
	    echo "publish: committed locally, not pushed (PUBLISH_PUSH=$(PUBLISH_PUSH))"; \
	  fi; \
	fi

clean: ## Remove the generated table-vi files and the stamp
	rm -f $(GENERATED) .table-vi.stamp

help: ## List targets
	@grep -hE '^[a-z.-]+:.*##' $(MAKEFILE_LIST) \
	  | sed -e 's/:.*## /\t/' | sort | awk -F'\t' '{printf "  %-8s %s\n", $$1, $$2}'
