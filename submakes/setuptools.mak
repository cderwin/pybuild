# define(`R2_VERSION', `R2_VERSION_MAJOR.2')dnl


setuptools.version := 20.0
setuptools.dir := setuptools-20.0
setuptools.tgz := setuptools-20.0.tar.gz
setuptools.url := https://pypi.python.org/packages/source/s/setuptools/setuptools-20.0.tar.gz

.setuptools.fetch:
	mkdir -p $(CWD)/dists && cd $(CWD)/dists && wget --quiet -N $(setuptools.url) -O $(setuptools.tgz)
#	cd R2_DISTS && curl -s -o $(R2_PKG.tgz) -C - -L $(R2_PKG.url)
	touch -a $(CWD)/.setuptools.fetch

.setuptools.unpack: .setuptools.fetch shasums/setuptools.sha1
	cd $(CWD)/dists && $(SHASUM) -c $(CWD)/shasums/setuptools.sha1
	mkdir -p build && cd $(CWD)/build && tar xvf $(CWD)/dists/$(setuptools.tgz) && touch $(CWD)/.setuptools.unpack

.setuptools.clean:
	rm -rf build/$(setuptools.dir) .setuptools.* submakes/setuptools.mak
GLOBAL_CLEAN += .setuptools.clean

.setuptools.distclean:
	rm -f dists/$(setuptools.tgz)

GLOBAL_DISTCLEAN += .setuptools.distclean



.setuptools.make: .setuptools.unpack .python27.install
	cd build/$(setuptools.dir) && \
	python setup.py build && \
	touch $(CWD)/.setuptools.make

.setuptools.install: .setuptools.make
	cd build/$(setuptools.dir) && \
	python setup.py install && \
	touch $(CWD)/.setuptools.install

