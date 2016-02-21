

gdbm.version := 1.9.1
gdbm.dir := gdbm-1.9.1
gdbm.tgz := gdbm-1.9.1.tar.gz
gdbm.url := ftp://ftp.gnu.org/pub/gnu/gdbm/gdbm-1.9.1.tar.gz

.gdbm.fetch:
	mkdir -p $(CWD)/dists && cd $(CWD)/dists && wget --quiet -N $(gdbm.url) -O $(gdbm.tgz)
#	cd R2_DISTS && curl -s -o $(R2_PKG.tgz) -C - -L $(R2_PKG.url)
	touch -a $(CWD)/.gdbm.fetch

.gdbm.unpack: .gdbm.fetch shasums/gdbm.sha1
	cd $(CWD)/dists && $(SHASUM) -c $(CWD)/shasums/gdbm.sha1
	mkdir -p build && cd $(CWD)/build && tar xvf $(CWD)/dists/$(gdbm.tgz) && touch $(CWD)/.gdbm.unpack

.gdbm.make: .gdbm.config
	cd build/$(gdbm.dir) && \
	DYLD_LIBRARY_PATH=$(DYLD_LIBRARY_PATH) $(MAKE) -j4 && \
	touch $(CWD)/.gdbm.make

.gdbm.install: .gdbm.make
	cd build/$(gdbm.dir) && \
	DYLD_LIBRARY_PATH=$(DYLD_LIBRARY_PATH) make install $(DEST) && \
	touch $(CWD)/.gdbm.install

.gdbm.clean:
	rm -rf build/$(gdbm.dir) .gdbm.* submakes/gdbm.mak
GLOBAL_CLEAN += .gdbm.clean

.gdbm.distclean:
	rm -f dists/$(gdbm.tgz)

GLOBAL_DISTCLEAN += .gdbm.distclean



.gdbm.args := \
	       --prefix=$(pfx) \
	       --enable-libgdbm-compat \
	       --enable-static \
	       --disable-shared

.gdbm.config: .gdbm.unpack .ncurses.install
	cd build/$(gdbm.dir) && \
	CC=$(CC) CXX=$(CXX) LDFLAGS="$(LDFLAGS)" CFLAGS="$(CFLAGS) -fPIC" CXXFLAGS="$(CFLAGS)" ./configure $(.gdbm.args)  && \
	touch $(CWD)/.gdbm.config
