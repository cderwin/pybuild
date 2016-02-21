

python27.version := 2.7.10
python27.dir := Python-2.7.10
python27.tgz := Python-2.7.10.tar.xz
python27.url := https://www.python.org/ftp/python/2.7.10/Python-2.7.10.tar.xz

.python27.fetch:
	mkdir -p $(CWD)/dists && cd $(CWD)/dists && wget --quiet -N $(python27.url) -O $(python27.tgz)
#	cd R2_DISTS && curl -s -o $(R2_PKG.tgz) -C - -L $(R2_PKG.url)
	touch -a $(CWD)/.python27.fetch

.python27.unpack: .python27.fetch shasums/python27.sha1
	cd $(CWD)/dists && $(SHASUM) -c $(CWD)/shasums/python27.sha1
	mkdir -p build && cd $(CWD)/build && tar xvf $(CWD)/dists/$(python27.tgz) && touch $(CWD)/.python27.unpack

.python27.clean:
	rm -rf build/$(python27.dir) .python27.* submakes/python27.mak
GLOBAL_CLEAN += .python27.clean

.python27.distclean:
	rm -f dists/$(python27.tgz)

GLOBAL_DISTCLEAN += .python27.distclean



.python27.args := \
	--prefix=$(pfx)

.python27.patch: .python27.unpack
	cd build/$(python27.dir) && \
	patch -p1 < ../../patches/python-ssl.diff && \
	touch $(CWD)/$@

.python27.config: .python27.patch .libffi.install .bzip2.install .openssl.install .readline.install .ncurses.install .gdbm.install .sqlite.install
	cd build/$(python27.dir) && \
	export PYTHON_OPENSSL=$(pfx) && \
	CC=$(CC) \
	CXX=$(CXX) \
	LDFLAGS="$(LDFLAGS)" \
	LDSHARED=$(LDSHARED) \
	DYLD_LIBRARY_PATH=$(DYLD_LIBRARY_PATH) \
	CFLAGS="$(CFLAGS) -I$(pfx)/include/ncurses -I$(pfx)/include" \
	CXXFLAGS="$(CFLAGS)" && \
	echo "bz2 bz2module.c -I$(pfx)/include -L$(pfx)/lib -lbz2" >> Modules/Setup.local && \
	echo "readline readline.c  -I$(pfx)/include -L$(pfx)/lib  -lreadline -lncursesw" >> Modules/Setup.local && \
	echo "gdbm gdbmmodule.c -I$(pfx)/include -L$(pfx)/lib -lgdbm" >> Modules/Setup.local && \
	echo "dbm dbmmodule.c -DHAVE_GDBM_H=1 -I$(pfx)/include -L$(pfx)/lib -lgdbm_compat" >> Modules/Setup.local && \
	echo "_sqlite  -I$(pfx)/include -L$(pfx)/lib -I$$(srcdir)/Modules/_sqlite _sqlite/cache.c _sqlite/cursor.c _sqlite/module.c _sqlite/row.c _sqlite/util.c _sqlite/connection.c _sqlite/microprotocols.c _sqlite/prepare_protocol.c _sqlite/statement.c  -lsqlite3 -DMODULE_NAME=sqlite3" >> Modules/Setup.local && \
	 ./configure $(.python27.args)  && \
	touch $(CWD)/$@

#	patch -p1 < ../../patches/python-readline.diff && \

# Need to iron out the ndbm header detection crap here


.python27.make: .python27.config
	cd build/$(python27.dir) && \
	export PYTHON_OPENSSL=$(pfx) && \
	CFLAGS="$(CFLAGS) -I$(pfx)/include/ncurses -I$(pfx)/include -D__PTHREAD_SPINS=0" \
	DYLD_LIBRARY_PATH=$(DYLD_LIBRARY_PATH) $(MAKE) -j4  && \
	touch $(CWD)/.python27.make

.python27.install: .python27.make
	cd build/$(python27.dir) && \
	export PYTHON_OPENSSL=$(pfx) && \
	DYLD_LIBRARY_PATH=$(DYLD_LIBRARY_PATH) \
	make install $(DEST) && \
	touch $(CWD)/.python27.install

