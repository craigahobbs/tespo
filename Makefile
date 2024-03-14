# Licensed under the MIT License
# https://github.com/craigahobbs/tespo/blob/main/LICENSE


# Download python-build
define WGET
ifeq '$$(wildcard $(notdir $(1)))' ''
$$(info Downloading $(notdir $(1)))
_WGET := $$(shell $(call WGET_CMD, $(1)))
endif
endef
WGET_CMD = if which wget; then wget -q -c $(1); else curl -f -Os $(1); fi
$(eval $(call WGET, https://raw.githubusercontent.com/craigahobbs/python-build/main/Makefile.tool))


# Include python-build
include Makefile.tool


# Development dependencies
TESTS_REQUIRE := bare-script


clean:
	rm -rf Makefile.tool


test: $(DEFAULT_VENV_BUILD)
	$(DEFAULT_VENV_BIN)/bare -c 'include <markdownUp.bare>' test/runTests.mds $(BARE_ARGS) $(if $(TEST),-v vTest "'$(TEST)'")


lint: $(DEFAULT_VENV_BUILD)
	$(DEFAULT_VENV_BIN)/bare -s *.mds test/*.mds
