include platform.mk

.PHONY: all skynet clean

LUA_CLIB_PATH ?= luaclib

CFLAGS = -g -O2 -Wall $(MYCFLAGS)

LUA_CLIB = skiplist cjson
LUA_INC = skynet/3rd/lua

SKYNET_PATH = skynet

all : skynet

skynet/Makefile :
	git clone https://github.com/cloudwu/skynet.git
	
skynet : skynet/Makefile
	cd skynet && $(MAKE) $(PLAT) && cd ..

all : \
  $(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so)

$(LUA_CLIB_PATH) :
	mkdir $(LUA_CLIB_PATH)

$(LUA_CLIB_PATH)/cjson.so : | $(LUA_CLIB_PATH)
	cd lualib-src/lua-cjson && $(MAKE) LUA_INCLUDE_DIR=../../$(LUA_INC) CC=$(CC) CJSON_LDFLAGS="$(SHARED)" && cd ../.. && cp lualib-src/lua-cjson/cjson.so $@

$(LUA_CLIB_PATH)/skiplist.so : | $(LUA_CLIB_PATH)
	cd lualib-src/lua-zset && $(MAKE) LUA_INCLUDE_DIR=../../$(LUA_INC) CFLAGS="$(CFLAGS)" SHARED="$(SHARED)" && cd ../.. && cp lualib-src/lua-zset/skiplist.so $@ && cp lualib-src/lua-zset/zset.lua ./common/zset.lua

# $(LUA_CLIB_PATH)/https.so : | $(LUA_CLIB_PATH)
	# cd lualib-src/lua-https && $(MAKE) LUA_INCLUDE_DIR=../../$(LUA_INC) CFLAGS="$(CFLAGS)" SHARED="$(SHARED)" && cd ../.. && cp lualib-src/lua-https/https.so $@

clean :
	cd skynet && $(MAKE) clean
	
