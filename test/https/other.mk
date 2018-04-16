.PHONY: all openssl curl

all : openssl curl

openssl/Makefile :
	git clone https://github.com/openssl/openssl.git
	
openssl : openssl/Makefile
	yum install openssl-devel -y

curl/Makefile :
	git clone https://github.com/curl/curl.git
	
curl : curl/Makefile
	cd curl && ./buildconf && ./configure --with-ssl=/usr --disable-shared --enable-static && $(MAKE) && $(MAKE) install && cd ..
