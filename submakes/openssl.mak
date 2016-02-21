


openssl.version := 1.0.2f
openssl.dir := openssl-1.0.2f
openssl.tgz := openssl-1.0.2f.tar.gz
openssl.url := ftp://ftp.openssl.org/source/openssl-1.0.2f.tar.gz

.openssl.fetch:
	mkdir -p $(CWD)/dists && cd $(CWD)/dists && wget --quiet -N $(openssl.url) -O $(openssl.tgz)
#	cd R2_DISTS && curl -s -o $(R2_PKG.tgz) -C - -L $(R2_PKG.url)
	touch -a $(CWD)/.openssl.fetch

.openssl.unpack: .openssl.fetch shasums/openssl.sha1
	cd $(CWD)/dists && $(SHASUM) -c $(CWD)/shasums/openssl.sha1
	mkdir -p build && cd $(CWD)/build && tar xvf $(CWD)/dists/$(openssl.tgz) && touch $(CWD)/.openssl.unpack


UNAME := $(shell uname)

EXTRA_CFG=linux-x86_64
ifeq ($(UNAME), Darwin)
     EXTRA_CFG=shared darwin64-x86_64-cc
endif

.openssl.args := \
	$(EXTRA_CFG) \
	--prefix=$(pfx) \
	--openssldir=$(pfx)/openssl \
	no-shared \
	-fPIC

#.openssl.config: .openssl.unpack .zlib.install
#	cd R2_BUILD/$(openssl.dir) && \
#	CC=$(CC) CXX=$(CXX) CFLAGS="$(CFLAGS)" CXXFLAGS="$(CFLAGS)" ./config $(.openssl.args)  && \
#	touch $(CWD)/$@

.openssl.config: .openssl.unpack .zlib.install
	cd build/$(openssl.dir) && \
#	CC=$(CC) CXX=$(CXX) CFLAGS="$(CFLAGS) -fPIC" CXXFLAGS="$(CFLAGS)" ./config $(.openssl.args)  && \
	CC=$(CC) CXX=$(CXX) CFLAGS="$(CFLAGS) -fPIC" CXXFLAGS="$(CFLAGS)" ./Configure $(.openssl.args)  && \
	touch $(CWD)/$@

.openssl.make: .openssl.config
	cd build/$(openssl.dir) && \
	$(MAKE) -j4 && \
	touch $(CWD)/$@

# the install target includes install_doc, which is fucked up
.openssl.install: .openssl.make
	cd build/$(openssl.dir) && \
	make install_sw $(DEST) && \
	touch $(CWD)/.openssl.install

.openssl.clean:
	rm -rf build/$(openssl.dir) .openssl.*
GLOBAL_CLEAN += .openssl.clean

.openssl.distclean:
	rm -f dists/$(openssl.tgz)

GLOBAL_DISTCLEAN += .openssl.distclean
