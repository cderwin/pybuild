

zlib.version := 1.2.8
zlib.dir := zlib-1.2.8
zlib.tgz := zlib-1.2.8.tar.gz
zlib.url := http://zlib.net/zlib-1.2.8.tar.gz

.zlib.fetch:
	mkdir -p $(CWD)/dists && cd $(CWD)/dists && wget --quiet -N $(zlib.url) -O $(zlib.tgz)
#	cd R2_DISTS && curl -s -o $(R2_PKG.tgz) -C - -L $(R2_PKG.url)
	touch -a $(CWD)/.zlib.fetch

.zlib.unpack: .zlib.fetch shasums/zlib.sha1
	cd $(CWD)/dists && $(SHASUM) -c $(CWD)/shasums/zlib.sha1
	mkdir -p build && cd $(CWD)/build && tar xvf $(CWD)/dists/$(zlib.tgz) && touch $(CWD)/.zlib.unpack

.zlib.make: .zlib.config
	cd build/$(zlib.dir) && \
	DYLD_LIBRARY_PATH=$(DYLD_LIBRARY_PATH) $(MAKE) -j4 && \
	touch $(CWD)/.zlib.make

.zlib.install: .zlib.make
	cd build/$(zlib.dir) && \
	DYLD_LIBRARY_PATH=$(DYLD_LIBRARY_PATH) make install $(DEST) && \
	touch $(CWD)/.zlib.install

.zlib.clean:
	rm -rf build/$(zlib.dir) .zlib.* submakes/zlib.mak
GLOBAL_CLEAN += .zlib.clean

.zlib.distclean:
	rm -f dists/$(zlib.tgz)

GLOBAL_DISTCLEAN += .zlib.distclean



.zlib.args := \
	--prefix=$(pfx) \
        --static

.zlib.config: .zlib.unpack
	cd build/$(zlib.dir) && \
	CC=$(CC) CXX=$(CXX) LDFLAGS="$(LDFLAGS)" CFLAGS="$(CFLAGS) -fPIC" CXXFLAGS="$(CFLAGS)" ./configure $(.zlib.args)  && \
	touch $(CWD)/.zlib.config
