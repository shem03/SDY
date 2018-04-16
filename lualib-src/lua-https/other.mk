all : openssl curl
.PHONY : openssl curl

openssl/Makefile :
	test -d openssl || (yum install openssl-devel -y && git clone https://github.com/openssl/openssl.git)
	
openssl : openssl/Makefile
	echo "success openssl"

curl/Makefile :
	test -d curl || (yum -y install libtool && yum -y install automake && git clone https://github.com/curl/curl.git)
	
curl : curl/Makefile
	cd curl && ./buildconf && ./configure --with-ssl=/usr --disable-shared --enable-static && $(MAKE) && $(MAKE) install && cd ..
