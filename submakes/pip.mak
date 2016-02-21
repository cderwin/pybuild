

pip.version := 8.0.2
pip.dir := pip-8.0.2
pip.tgz := pip-8.0.2.tar.gz
pip.url := https://pypi.python.org/packages/source/p/pip/pip-8.0.2.tar.gz

.pip.fetch:
	mkdir -p $(CWD)/dists && cd $(CWD)/dists && wget --quiet -N $(pip.url) -O $(pip.tgz)
#	cd R2_DISTS && curl -s -o $(R2_PKG.tgz) -C - -L $(R2_PKG.url)
	touch -a $(CWD)/.pip.fetch

.pip.unpack: .pip.fetch shasums/pip.sha1
	cd $(CWD)/dists && $(SHASUM) -c $(CWD)/shasums/pip.sha1
	mkdir -p build && cd $(CWD)/build && tar xvf $(CWD)/dists/$(pip.tgz) && touch $(CWD)/.pip.unpack

.pip.clean:
	rm -rf build/$(pip.dir) .pip.* submakes/pip.mak
GLOBAL_CLEAN += .pip.clean

.pip.distclean:
	rm -f dists/$(pip.tgz)

GLOBAL_DISTCLEAN += .pip.distclean



.pip.make: .pip.unpack .setuptools.install
	cd build/$(pip.dir) && \
	python setup.py build && \
	touch $(CWD)/.pip.make

.pip.install: .pip.make
	cd build/$(pip.dir) && \
	python setup.py install && \
	touch $(CWD)/.pip.install

