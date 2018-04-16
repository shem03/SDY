
.PHONY: all

PLAT ?= linux
SHARED := -fPIC --shared

CFLAGS = -g -O2 -Wall

all : test

test : test_curl.c
	gcc $(CFLAGS) $^ -o $@ -lcurl -lcrypto -lz -lssl
	
