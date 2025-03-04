# Licensed under the MIT License
# https://github.com/craigahobbs/tespo/blob/main/LICENSE


# Download python-build
PYTHON_BUILD_DIR ?= ../python-build
define WGET
ifeq '$$(wildcard $(notdir $(1)))' ''
$$(info Downloading $(notdir $(1)))
_WGET := $$(shell [ -f $(PYTHON_BUILD_DIR)/$(notdir $(1)) ] && cp $(PYTHON_BUILD_DIR)/$(notdir $(1)) . || $(call WGET_CMD, $(1)))
endif
endef
WGET_CMD = if which wget; then wget -q -c $(1); else curl -f -Os $(1); fi
$(eval $(call WGET, https://craigahobbs.github.io/python-build/Makefile.tool))


# Include python-build
include Makefile.tool


# Development dependencies
TESTS_REQUIRE := bare-script


clean:
	rm -rf Makefile.tool


test: $(DEFAULT_VENV_BUILD)
	$(DEFAULT_VENV_BIN)/bare -m test/runTests.mds $(BARE_ARGS) $(if $(TEST),-v vTest "'$(TEST)'")


lint: $(DEFAULT_VENV_BUILD)
	$(DEFAULT_VENV_BIN)/bare -s *.mds test/*.mds
