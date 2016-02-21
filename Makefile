SHELL := bash
ME := maps
CWD := $(CURDIR)
pfx := $(CWD)/$(ME)_server

SHASUM := sha1sum
ROOT:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
BUILDDIR := $(ROOT)/build

DEST :=
SUBMAKES := $(wildcard submakes/*.mak.in)

include $(SUBMAKES:mak.in=mak)

LD_LIBRARY_PATH := $(pfx)/lib
PKG_CONFIG_PATH := $(pfx)/lib/pkgconfig
PATH := $(pfx)/bin:$(PATH)
OS := $(shell uname)

m4deps :=
ifeq "$(OS)" "Darwin"
	DYLD_LIBRARY_PATH := $(pfx)/lib
	SHASUM := shasum
	PATH := $(pfx)/bin:/usr/local/opt:$(PATH)
	LDSHARED='$(CC) $(ARCHFLAGS) -dynamiclib -undefined suppress -flat_namespace'
else
	SHASUM := sha1sum
endif

CFLAGS := -I$(pfx)/include $(ARCHFLAGS)
CPPFLAGS := -I$(pfx)/include $(ARCHFLAGS)
CXXFLAGS := -I$(pfx)/include $(ARCHFLAGS)
LDFLAGS := -L$(pfx)/lib $(ARCHFLAGS)

################################################################################
# Targets
################################################################################

all: r2.deps .uwsgi.install

clean:
	@rm -f .*.ts env.sh && \
	find . -name "*.pyc" -delete

distclean: $(GLOBAL_CLEAN) clean
	rm -fv .*.{config,make,fetch,install,unpack,patch}
	rm -rf $(pfx)
	rm -rf $(BUILDDIR) dist
	rm -rf dists
	rm -f submakes/*.mak config.m4


$(ME).tar.gz: MANIFEST.sha1
	tar cvzf $@ $(ME)_server

MANIFEST.sha1: all
	find $(ME)_server -type f -exec $(SHASUM) {} \; > $@

release: all $(ME).tar.gz

# M4 build

%.mak: %.mak.in r2.m4
	m4 $< > $@

%/.exist:
	mkdir -p $(@D)
	chmod 755 $(@D)
	touch $@

r2.deps: dists/.exist build/.exist $(OSDEPS) env.sh

env.sh: config.m4 env.sh.in
	m4 $^ > $@
	chmod 755 $@

config.m4:
	echo "define(\`ROOT', \`$(PWD)')" > $@
	echo "define(\`DYLD_VALUE', \`$(DYLD_LIBRARY_PATH)')" >> $@

%.sh: config.m4 %.sh.in
	m4 $^ > $@
	chmod +x $@
