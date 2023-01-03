# LICENSE : GPL v3  : see LICENSE file
# Author: Nikolay Fiykov

PRJ_DIR := $(shell pwd)
PRJ_SRC_DIR := $(PRJ_DIR)/lua

LUA_PATH := $(PRJ_SRC_DIR)/?.lua

LUA_TEST_CASES := $(wildcard $(PRJ_DIR)/test/*est*.lua)

# dir where file module would read and write
NODEMCU_MOCKS_SPIFFS_DIR   	?=  target/tests-spiffs
NODEMCU_LFS_FILES			?=

.PHONY: help mock_spiffs_dir $(LUA_TEST_CASES)

help:
	@echo type: make clean
	@echo type: make test
	@echo type: make dist

mock_spiffs_dir:
	@mkdir -p $(NODEMCU_MOCKS_SPIFFS_DIR)
	@rm -rf $(NODEMCU_MOCKS_SPIFFS_DIR)/*

$(LUA_TEST_CASES): mock_spiffs_dir
	@echo [INFO] : Running tests in $@ ...
	@export LUA_PATH=$(LUA_PATH) \
		&& export NODEMCU_MOCKS_SPIFFS_DIR="$(NODEMCU_MOCKS_SPIFFS_DIR)" \
		&& export NODEMCU_LFS_FILES="$(NODEMCU_LFS_FILES)" \
		&& lua5.3 $@

test: $(LUA_TEST_CASES)
