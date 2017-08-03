SHELL=/bin/bash

LUA_PATH="target/lua/?.lua"

.PHONY : all
all : compile

prepare-contrib : | target/lua target/lua/luaunit.lua lua-contrib 
#target/lua/mockagne.lua
target/lua :
	mkdir -p target/lua
target/lua/luaunit.lua : target/git/luaunit.git target/lua
	cp target/git/luaunit.git/luaunit.lua target/lua/luaunit.lua
target/git/luaunit.git :
	mkdir -p target/git 
	git clone https://github.com/bluebird75/luaunit.git target/git/luaunit.git
lua-contrib :
	cp src/contrib/lua/*.lua target/lua/
#target/lua/mockagne.lua : target/git/mockagne.git target/lua
#	cp target/git/mockagne.git/mockagne.lua target/lua/mockagne.lua
#target/git/mockagne.git :
#	mkdir -p target/git 
#	git clone https://github.com/vertti/mockagne.git target/git/mockagne.git

prepare-sources : prepare-contrib
	cp src/main/lua/*.lua target/lua/
prepare-resources : prepare-contrib
	echo 'src/main/resources empty'
	#@if [ "$$(ls -A src/main/resources)" ] ; then cp -R src/main/resources/* target/lua/ ; fi ;
compile : prepare-sources prepare-resources

prepare-test-sources : prepare-contrib
	cp src/test/lua/*.lua target/lua/
prepare-test-resources : prepare-contrib
	echo 'src/test/resources empty'
	#@if [ "$$(ls -A src/test/resources)" ] ; then cp -R src/test/resources/* target/lua/ ; fi ;
test_files = $(wildcard target/lua/test*.lua)
.PHONY: $(test_files)
test: compile prepare-test-resources prepare-test-sources $(test_files)
$(test_files) :
	LUA_PATH=$(LUA_PATH) lua $@

dist : compile
	rm -rf target/dist
	mkdir -p target/dist
	cp target/lua/* target/dist/

clean :
	rm -rf target

