

libffi.version := 3.2.1
libffi.dir := libffi-3.2.1
libffi.tgz := libffi-3.2.1.tar.gz
libffi.url := ftp://sourceware.org/pub/libffi/libffi-3.2.1.tar.gz

.libffi.fetch:
	mkdir -p $(CWD)/dists && cd $(CWD)/dists && wget --quiet -N $(libffi.url) -O $(libffi.tgz)
#	cd R2_DISTS && curl -s -o $(R2_PKG.tgz) -C - -L $(R2_PKG.url)
	touch -a $(CWD)/.libffi.fetch

.libffi.unpack: .libffi.fetch shasums/libffi.sha1
	cd $(CWD)/dists && $(SHASUM) -c $(CWD)/shasums/libffi.sha1
	mkdir -p build && cd $(CWD)/build && tar xvf $(CWD)/dists/$(libffi.tgz) && touch $(CWD)/.libffi.unpack

.libffi.make: .libffi.config
	cd build/$(libffi.dir) && \
	DYLD_LIBRARY_PATH=$(DYLD_LIBRARY_PATH) $(MAKE) -j4 && \
	touch $(CWD)/.libffi.make

.libffi.install: .libffi.make
	cd build/$(libffi.dir) && \
	DYLD_LIBRARY_PATH=$(DYLD_LIBRARY_PATH) make install $(DEST) && \
	touch $(CWD)/.libffi.install

.libffi.clean:
	rm -rf build/$(libffi.dir) .libffi.* submakes/libffi.mak
GLOBAL_CLEAN += .libffi.clean

.libffi.distclean:
	rm -f dists/$(libffi.tgz)

GLOBAL_DISTCLEAN += .libffi.distclean



.libffi.args := \
	       --prefix=$(pfx) \
	       --enable-static \
	       --disable-shared \
	       --libdir=$(pfx)/lib \
	       --includedir=$(pfx)/include

.libffi.patch: .libffi.unpack
	cd build/$(libffi.dir) && \
	patch -p1 < ../../patches/libffi-3.2.1-no-lib64.patch && \
	touch $(CWD)/$@

.libffi.config: .libffi.patch
	cd build/$(libffi.dir) && \
	CC=$(CC) CXX=$(CXX) LDFLAGS="$(LDFLAGS)" CFLAGS="$(CFLAGS) -fPIC" CXXFLAGS="$(CFLAGS)" ./configure $(.libffi.args)  && \
	touch $(CWD)/$@
