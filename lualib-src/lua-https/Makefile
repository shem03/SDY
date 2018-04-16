include other.mk

all: https.so

CC ?= gcc
LUA_INCLUDE_DIR ?= /usr/local/include
SHARED ?= -fPIC --shared
CFLAGS ?= -g3 -O0 -Wall

https.so: lua-https.c
	$(CC)  $(CFLAGS) $(SHARED) -I$(LUA_INCLUDE_DIR) $^ -o $@ -lcurl -lcrypto -lz -lssl

clean:
	-rm client_https.so
