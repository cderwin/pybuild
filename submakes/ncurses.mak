

ncurses.version := 5.9
ncurses.dir := ncurses-5.9
ncurses.tgz := ncurses-5.9.tar.gz
ncurses.url := https://ftp.gnu.org/gnu/ncurses/ncurses-5.9.tar.gz

.ncurses.fetch:
	mkdir -p $(CWD)/dists && cd $(CWD)/dists && wget --quiet -N $(ncurses.url) -O $(ncurses.tgz)
#	cd R2_DISTS && curl -s -o $(R2_PKG.tgz) -C - -L $(R2_PKG.url)
	touch -a $(CWD)/.ncurses.fetch

.ncurses.unpack: .ncurses.fetch shasums/ncurses.sha1
	cd $(CWD)/dists && $(SHASUM) -c $(CWD)/shasums/ncurses.sha1
	mkdir -p build && cd $(CWD)/build && tar xvf $(CWD)/dists/$(ncurses.tgz) && touch $(CWD)/.ncurses.unpack

.ncurses.make: .ncurses.config
	cd build/$(ncurses.dir) && \
	DYLD_LIBRARY_PATH=$(DYLD_LIBRARY_PATH) $(MAKE) -j4 && \
	touch $(CWD)/.ncurses.make

.ncurses.install: .ncurses.make
	cd build/$(ncurses.dir) && \
	DYLD_LIBRARY_PATH=$(DYLD_LIBRARY_PATH) make install $(DEST) && \
	touch $(CWD)/.ncurses.install

.ncurses.clean:
	rm -rf build/$(ncurses.dir) .ncurses.* submakes/ncurses.mak
GLOBAL_CLEAN += .ncurses.clean

.ncurses.distclean:
	rm -f dists/$(ncurses.tgz)

GLOBAL_DISTCLEAN += .ncurses.distclean



.ncurses.args := \
	--prefix=$(pfx) \
	--with-shared \
	--with-pkg-config-libdir=$(PKG_CONFIG_PATH) \
	--enable-widec \
	--without-cxx \
	--without-cxx-binding \
	--enable-static \
	--enable-termcap \
	--without-shared


.ncurses.config: .ncurses.unpack
	cd build/$(ncurses.dir) && \
	CXX=$(CXX) CC=$(CC) CFLAGS="$(CFLAGS) -fPIC" CXXFLAGS="$(CFLAGS) -fPIC" ./configure $(.ncurses.args)  && \
	touch $(CWD)/.ncurses.config
