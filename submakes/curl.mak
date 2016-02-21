

curl.version := 7.43.0
curl.dir := curl-7.43.0
curl.tgz := curl-7.43.0.tar.bz2
curl.url := http://curl.haxx.se/download/curl-7.43.0.tar.bz2

.curl.fetch:
	mkdir -p $(CWD)/dists && cd $(CWD)/dists && wget --quiet -N $(curl.url) -O $(curl.tgz)
#	cd R2_DISTS && curl -s -o $(R2_PKG.tgz) -C - -L $(R2_PKG.url)
	touch -a $(CWD)/.curl.fetch

.curl.unpack: .curl.fetch shasums/curl.sha1
	cd $(CWD)/dists && $(SHASUM) -c $(CWD)/shasums/curl.sha1
	mkdir -p build && cd $(CWD)/build && tar xvf $(CWD)/dists/$(curl.tgz) && touch $(CWD)/.curl.unpack

.curl.make: .curl.config
	cd build/$(curl.dir) && \
	DYLD_LIBRARY_PATH=$(DYLD_LIBRARY_PATH) $(MAKE) -j4 && \
	touch $(CWD)/.curl.make

.curl.install: .curl.make
	cd build/$(curl.dir) && \
	DYLD_LIBRARY_PATH=$(DYLD_LIBRARY_PATH) make install $(DEST) && \
	touch $(CWD)/.curl.install

.curl.clean:
	rm -rf build/$(curl.dir) .curl.* submakes/curl.mak
GLOBAL_CLEAN += .curl.clean

.curl.distclean:
	rm -f dists/$(curl.tgz)

GLOBAL_DISTCLEAN += .curl.distclean



.curl.args := \
	--prefix=$(pfx) \
        --with-ssl=$(pfx)

.curl.config: .curl.unpack .openssl.install
	cd build/$(curl.dir) && \
	PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
        CFLAGS="$(CFLAGS)" \
        CXXFLAGS="$(CFLAGS)" \
        LDFLAGS="$(LDFLAGS) -ldl" \
	LIBS="-ldl" \
        ./configure $(.curl.args)  && \
	touch $(CWD)/.curl.config

