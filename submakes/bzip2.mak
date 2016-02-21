

bzip2.version := 1.0.6
bzip2.dir := bzip2-1.0.6
bzip2.tgz := bzip2-1.0.6.tar.gz
bzip2.url := http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz

.bzip2.fetch:
	mkdir -p $(CWD)/dists && cd $(CWD)/dists && wget --quiet -N $(bzip2.url) -O $(bzip2.tgz)
#	cd R2_DISTS && curl -s -o $(R2_PKG.tgz) -C - -L $(R2_PKG.url)
	touch -a $(CWD)/.bzip2.fetch

.bzip2.unpack: .bzip2.fetch shasums/bzip2.sha1
	cd $(CWD)/dists && $(SHASUM) -c $(CWD)/shasums/bzip2.sha1
	mkdir -p build && cd $(CWD)/build && tar xvf $(CWD)/dists/$(bzip2.tgz) && touch $(CWD)/.bzip2.unpack


.bzip2.config: .bzip2.unpack 
	cd build/$(bzip2.dir) && \
#	CC=$(CC) CXX=$(CXX) CFLAGS="$(CFLAGS) -fPIC" CXXFLAGS="$(CFLAGS)" ./Configure $(.bzip2.args)  && \
	touch $(CWD)/$@

.bzip2.make: .bzip2.config
	cd build/$(bzip2.dir) && \
	$(MAKE) && \
	touch $(CWD)/$@

# the install target includes install_doc, which is fucked up
.bzip2.install: .bzip2.make
	cd build/$(bzip2.dir) && \
	make install PREFIX=$(pfx) && \
	touch $(CWD)/.bzip2.install

.bzip2.clean:
	rm -rf build/$(bzip2.dir) .bzip2.*
GLOBAL_CLEAN += .bzip2.clean

.bzip2.distclean:
	rm -f dists/$(bzip2.tgz)

GLOBAL_DISTCLEAN += .bzip2.distclean
