# index.html derives the whole network from the JSON tables in this directory.
# Most are transcribed by hand and read as-is; the three table-vi files are
# generated, so they can fall out of step with their source.

PY      ?= python3
PORT    ?= 8000

# Generated from table-vi.json by convert-table-vi.py.
GENERATED := ms.json ms-membership.json table-vi-dharmas.json

# Read directly by index.html, no build step.
SOURCES := table-iii.json table-iv.json table-v.json table-v-content.json \
           table-v-content-footnotes.json table-v-mental.json \
           table-v-objects.json table-v-sphere.json table-v-thought.json \
           table-v-trancic.json table-vii.json Table-viii.json

.PHONY: all check serve clean help
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

clean: ## Remove the generated table-vi files and the stamp
	rm -f $(GENERATED) .table-vi.stamp

help: ## List targets
	@grep -hE '^[a-z.-]+:.*##' $(MAKEFILE_LIST) \
	  | sed -e 's/:.*## /\t/' | sort | awk -F'\t' '{printf "  %-8s %s\n", $$1, $$2}'
