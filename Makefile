# Licensed under the MIT License
# https://github.com/craigahobbs/tespo/blob/main/LICENSE

.DEFAULT_GOAL := help


# Node
NODE_IMAGE ?= node:current-slim
NODE_DOCKER := $(if $(NO_DOCKER),,docker run -i --rm -u `id -u`:`id -g` -v `pwd`:`pwd` -w `pwd` -e HOME=`pwd`/build $(NODE_IMAGE))


.PHONY: help
help:
	@echo "usage: make [clean|commit|gh-pages|test|superclean]"


.PHONY: clean
clean:
	rm -rf build/ node_modules/ package.json package-lock.json


.PHONY: superclean
superclean: clean
ifeq '$(NO_DOCKER)' ''
	-docker rmi -f $(NODE_IMAGE)
endif


.PHONY: test
test: build/npm.build
	$(NODE_DOCKER) npx bare -s *.mds test/*.mds
	$(NODE_DOCKER) npx bare -c 'include <markdownUp.bare>' test/runTests.mds


.PHONY: commit
commit: test


.PHONY: gh-pages
gh-pages:


build/npm.build:
ifeq '$(NO_DOCKER)' ''
	if [ "$$(docker images -q $(NODE_IMAGE))" = "" ]; then docker pull -q $(NODE_IMAGE); fi
endif
	echo '{"type":"module","devDependencies":{"bare-script":"*"}}' > package.json
	$(NODE_DOCKER) npm install
	mkdir -p $(dir $@)
	touch $@
