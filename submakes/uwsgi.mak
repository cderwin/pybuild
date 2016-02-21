


uwsgi.version := 2.0.8
uwsgi.dir := uwsgi-2.0.8
uwsgi.tgz := uwsgi-2.0.8.tar.gz
uwsgi.url := http://projects.unbit.it/downloads/uwsgi-2.0.8.tar.gz

.uwsgi.fetch:
	mkdir -p $(CWD)/dists && cd $(CWD)/dists && wget --quiet -N $(uwsgi.url) -O $(uwsgi.tgz)
#	cd R2_DISTS && curl -s -o $(R2_PKG.tgz) -C - -L $(R2_PKG.url)
	touch -a $(CWD)/.uwsgi.fetch

.uwsgi.unpack: .uwsgi.fetch shasums/uwsgi.sha1
	cd $(CWD)/dists && $(SHASUM) -c $(CWD)/shasums/uwsgi.sha1
	mkdir -p build && cd $(CWD)/build && tar xvf $(CWD)/dists/$(uwsgi.tgz) && touch $(CWD)/.uwsgi.unpack

.uwsgi.clean:
	rm -rf build/$(uwsgi.dir) .uwsgi.* submakes/uwsgi.mak
GLOBAL_CLEAN += .uwsgi.clean

.uwsgi.distclean:
	rm -f dists/$(uwsgi.tgz)

GLOBAL_DISTCLEAN += .uwsgi.distclean



.uwsgi.patch: .uwsgi.unpack
	cd build/$(uwsgi.dir) && \
	patch -p0 -N < $(CWD)/patches/python-uwsgi.diff && \
	touch $(CWD)/$@

.uwsgi.make: .uwsgi.patch .setuptools.install .python27.install .gdbm.install
	cd build/$(uwsgi.dir) && \
	export CFLAGS=$(CFLAGS) && \
	export LDFLAGS=$(LDFLAGS) && \
	export LIBS="-lreadline -lncursesw -lgdbm -lgdbm_compat" && \
	CC=gcc CPP=g++ python uwsgiconfig.py --build && \
	touch $(CWD)/.uwsgi.make

.uwsgi.install: .uwsgi.make
	cd build/$(uwsgi.dir) && \
	python setup.py install && \
	touch $(CWD)/.uwsgi.install

