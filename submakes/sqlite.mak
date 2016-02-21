

sqlite.version := 3090200
sqlite.dir := sqlite-autoconf-3090200
sqlite.tgz := sqlite-autoconf-3090200.tar.gz
sqlite.url := http://www.sqlite.org/2015/sqlite-autoconf-3090200.tar.gz

.sqlite.fetch:
	mkdir -p $(CWD)/dists && cd $(CWD)/dists && wget --quiet -N $(sqlite.url) -O $(sqlite.tgz)
#	cd R2_DISTS && curl -s -o $(R2_PKG.tgz) -C - -L $(R2_PKG.url)
	touch -a $(CWD)/.sqlite.fetch

.sqlite.unpack: .sqlite.fetch shasums/sqlite.sha1
	cd $(CWD)/dists && $(SHASUM) -c $(CWD)/shasums/sqlite.sha1
	mkdir -p build && cd $(CWD)/build && tar xvf $(CWD)/dists/$(sqlite.tgz) && touch $(CWD)/.sqlite.unpack

.sqlite.make: .sqlite.config
	cd build/$(sqlite.dir) && \
	DYLD_LIBRARY_PATH=$(DYLD_LIBRARY_PATH) $(MAKE) -j4 && \
	touch $(CWD)/.sqlite.make

.sqlite.install: .sqlite.make
	cd build/$(sqlite.dir) && \
	DYLD_LIBRARY_PATH=$(DYLD_LIBRARY_PATH) make install $(DEST) && \
	touch $(CWD)/.sqlite.install

.sqlite.clean:
	rm -rf build/$(sqlite.dir) .sqlite.* submakes/sqlite.mak
GLOBAL_CLEAN += .sqlite.clean

.sqlite.distclean:
	rm -f dists/$(sqlite.tgz)

GLOBAL_DISTCLEAN += .sqlite.distclean



sqlite.args := \
	--prefix=$(pfx) \
	--with-pkg-config-libdir=$(PKG_CONFIG_PATH) \
	--enable-static \
	--without-shared \
	--disable-shared

.sqlite.config: .sqlite.unpack
	cd build/$(sqlite.dir) && \
	CXX=$(CXX) CC=$(CC) CFLAGS="$(CFLAGS) -fPIC" CXXFLAGS="$(CFLAGS) -fPIC" ./configure $(sqlite.args)  && \
	touch $(CWD)/.sqlite.config

