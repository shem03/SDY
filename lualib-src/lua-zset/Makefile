all: skiplist.so

CC ?= gcc
LUA_INCLUDE_DIR ?= /usr/local/include
SHARED ?= -fPIC --shared
CFLAGS ?= -g3 -O0 -Wall
DEFS = -DLUA_COMPAT_5_3

skiplist.so: skiplist.c lua-skiplist.c
	$(CC)  $(CFLAGS) $(SHARED) -I$(LUA_INCLUDE_DIR) $^ -o $@

test:
	lua test_sl.lua

clean:
	-rm skiplist.so
