# LICENSE : GPL v3  : see LICENSE file
# Author: Nikolay Fiykov

LUA_FILES			 							:= $(wildcard lua/*.lua)
LUA_TEST_CASES 							:= $(wildcard test/*est*.lua)

# dir where file module would read and write
NODEMCU_MOCKS_SPIFFS_DIR   	?= vendor/tests-spiffs
NODEMCU_LFS_FILES						?=

.PHONY: help 
.PHONY: clean
.PHONY: mock_spiffs_dir
.PHONY: $(LUA_TEST_CASES)
.PHONY: lint
.PHONY: test
.PHONY: coverage

##############################################
##############################################

help:                                                                                                   ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nExample:\n  \033[36mmake test\033[0m\n  Run unit tests.\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
 
clean:
	rm -rf vendor

##############################################
##############################################

vendor/hererocks:
	@mkdir -p vendor/hererocks
	curl -sLo vendor/hererocks/hererocks.py https://github.com/mpeterv/hererocks/raw/master/hererocks.py
	python vendor/hererocks/hererocks.py vendor/lua53 -l5.3 -rlatest
	export PATH="vendor/lua53/bin:${PATH}" \
		&& luarocks install luacheck \
		&& luarocks install luacov \
		&& luarocks install luacov-console

mock_spiffs_dir:
	@mkdir -p $(NODEMCU_MOCKS_SPIFFS_DIR)
	@rm -rf $(NODEMCU_MOCKS_SPIFFS_DIR)/*

##############################################
##############################################

test/%:
	@echo [INFO] : Running tests in ${*} ...
	export LUA_PATH="$(LUA_PATH);vendor/lua53/share/lua/5.3/?.lua;vendor/lua53/share/lua/5.3/?/init.lua;;lua/?.lua;lua/?.lua" \
		&& export LUA_CPATH="vendor/lua53/lib/lua/5.3/?.so;vendor/lua53/lib/lua/5.3/loadall.so;./?.so" \
		&& export NODEMCU_MOCKS_SPIFFS_DIR="$(NODEMCU_MOCKS_SPIFFS_DIR)" \
		&& export NODEMCU_LFS_FILES="$(NODEMCU_LFS_FILES)" \
		&& export PATH="vendor/lua53/bin:${PATH}" \
		&& lua -lluacov "${*}"

test: vendor/hererocks mock_spiffs_dir $(LUA_TEST_CASES:%=test/%) coverage	## run unit tests

##############################################
##############################################

lint/%: 
	@echo [INFO] : Running lint for ${*} ...
	export PATH="vendor/lua53/bin:${PATH}" \
		&& luacheck -g "${*}"

lint/lua/luaunit.lua:
	@echo "ignore linting for ${*}"
lint/lua/JSON.lua: 
	@echo "ignore linting for ${*}"
lint/lua/sha2.lua:
	@echo "ignore linting for ${*}"

lint: vendor/hererocks ${LUA_FILES:%=lint/%} ${LUA_TEST_CASES:%=lint/%} ## lint all lua files

##############################################
##############################################

coverage:               ## prints coverage report, collected when running tests
	export PATH="vendor/lua53/bin:${PATH}" \
		&& luacov-console lua -s

##############################################
##############################################
