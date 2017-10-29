# LICENSE : GPL v3  : see LICENSE file
# Author: Nikolay Fiykov

PRJ_DIR := $(shell pwd)
PRJ_SRC_DIR := $(PRJ_DIR)/src/main/lua
PRJ_CONTRIB_SRC_DIR := $(PRJ_DIR)/src/contrib/lua

GIT_ROOT_DIR := $(shell cd $(PRJ_DIR)/../.. && pwd)

LUA_PATH := $(PRJ_SRC_DIR)/?.lua\;$(PRJ_CONTRIB_SRC_DIR)/?.lua

LUA_TEST_CASES := $(wildcard $(PRJ_DIR)/src/test/lua/*est*.lua)

define assert-lualib-exists =
	@if [ $$(/usr/bin/luarocks list --porcelain $(1) | wc -l) -eq 0 ] ; then \
		echo "[ERROR] : $(1) is not installed. type: luarocks install $(1)" ; \
		return 1 ; \
	fi
endef

.PHONY: help clean test dist upload-rock $(LUA_TEST_CASES)

help:
	@echo type: make clean
	@echo type: make test
	@echo type: make dist

clean:
	rm -rf $(PRJ_DIR)/target

$(LUA_TEST_CASES):
	@echo [INFO] : Running tests in $@ ...
	LUA_PATH=$(LUA_PATH) export LUA_PATH && eval $$(luarocks path --append) && env | grep LUA && lua $@

$(PRJ_DIR)/target:
	mkdir -p $(PRJ_DIR)/target
	$(call assert-lualib-exists,luaunit)

test: $(PRJ_DIR)/target $(LUA_TEST_CASES)

dist: test
	mkdir -p $(PRJ_DIR)/target/dist
	cp $(PRJ_SRC_DIR)/* $(PRJ_CONTRIB_SRC_DIR)/* $(PRJ_DIR)/target/dist/

VER := $(shell grep -E "^version =" nodemculuamocks-tmpl.rockspec | awk '{print $$3}' | sed 's/"//g')
upload-rock: dist
	@if [ -z "$(KEY)" ] ; then \
	    echo "Luarocks api key not defined. Use make KEY=[key] upload-rock to execute." ; \
	    exit 1 ; \
    fi
	cp nodemculuamocks-tmpl.rockspec target/nodemculuamocks-$(VER).rockspec
	cd target && echo luarocks upload nodemculuamocks-$(VER).rockspec --api-key=$(KEY)
