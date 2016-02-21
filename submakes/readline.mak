

readline.version := 6.3
readline.dir := readline-6.3
readline.tgz := readline-6.3.tar.gz
readline.url := ftp://ftp.gnu.org/pub/gnu/readline/readline-6.3.tar.gz

.readline.fetch:
	mkdir -p $(CWD)/dists && cd $(CWD)/dists && wget --quiet -N $(readline.url) -O $(readline.tgz)
#	cd R2_DISTS && curl -s -o $(R2_PKG.tgz) -C - -L $(R2_PKG.url)
	touch -a $(CWD)/.readline.fetch

.readline.unpack: .readline.fetch shasums/readline.sha1
	cd $(CWD)/dists && $(SHASUM) -c $(CWD)/shasums/readline.sha1
	mkdir -p build && cd $(CWD)/build && tar xvf $(CWD)/dists/$(readline.tgz) && touch $(CWD)/.readline.unpack

.readline.make: .readline.config
	cd build/$(readline.dir) && \
	DYLD_LIBRARY_PATH=$(DYLD_LIBRARY_PATH) $(MAKE) -j4 && \
	touch $(CWD)/.readline.make

.readline.install: .readline.make
	cd build/$(readline.dir) && \
	DYLD_LIBRARY_PATH=$(DYLD_LIBRARY_PATH) make install $(DEST) && \
	touch $(CWD)/.readline.install

.readline.clean:
	rm -rf build/$(readline.dir) .readline.* submakes/readline.mak
GLOBAL_CLEAN += .readline.clean

.readline.distclean:
	rm -f dists/$(readline.tgz)

GLOBAL_DISTCLEAN += .readline.distclean



.readline.args := \
	       --prefix=$(pfx) \
	       --enable-static \
	       --disable-shared \
	       --with-curses=$(pfx)

.readline.patch: .readline.unpack
	cd build/$(readline.dir) && \
	cat $(CWD)/patches/readline63-* | patch -p0 && \
	touch $(CWD)/$@

.readline.config: .readline.patch .ncurses.install
	cd build/$(readline.dir) && \
	CC=$(CC) CXX=$(CXX) LDFLAGS="$(LDFLAGS)" CFLAGS="$(CFLAGS) -fPIC" CXXFLAGS="$(CFLAGS)" LIBS="-lncursesw" ./configure $(.readline.args)  && \
	touch $(CWD)/$@
