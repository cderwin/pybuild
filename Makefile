#########################################################################################
# The name of this project. Will be used as the tag for the container, if one is created
#########################################################################################
ME := maps
CWD := $(CURDIR)
pfx := $(CWD)/$(ME)_server

#########################################################################################
# You shouldnt need change things here
#########################################################################################

SHASUM := sha1sum
ROOT:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
THISDIR = $(shell basename $(ROOT))
BUILDDIR := $(ROOT)/build
NONDISTSRC := setup.py setup.cfg

#########################################################################################
# This project's specific Variables
#########################################################################################
MIGRATIONS := $(wildcard $(ME)/*/migrations/*.py)
SRC := $(filter-out $(MIGRATIONS), $(shell find $(ME) -name "*.py" -type f))
CFGSRC := $(wildcard config/*)
CONFIG := $(addprefix $(pfx)/, $(CFGSRC))
SUPERVISOR := $(addprefix $(pfx)/, $(wildcard supervisor/*.conf))

ifndef DJANGO_SETTINGS_MODULE
	DJANGO_SETTINGS_MODULE="$(ME).settings"
endif

################################################################################
# Python flags for Virtualenv
################################################################################

SHELL := bash
VENVDIR := $(pfx)
VPYTHON := $(VENVDIR)/bin/python
ACTIVATE := source env.sh
PYTHONUSERBASE=$(VENVDIR)
PIP := $(pfx)/bin/pip
PYUSERFLAGS :=
PIPUSERFLAGS := --cache-dir $(HOME)/.pipcache
# Enabling python wheels will cause problems since we build our
# dedicated python interpreters without --enable-shared. Since wheel
# files are dynamically linked with libpython.so, any shared objects
# from wheels will wind up linking with /usr/local/lib/libpython.so,
# the symbols for which are already in our python binary.
PIPFLAGS := $(PIPUSERFLAGS) --no-binary :all:
PEP8 := $(pfx)/bin/pep8
PYLINT := $(pfx)/bin/pylint
COVERAGE := $(pfx)/bin/coverage


################################################################################
# Targets
################################################################################

all: .install.ts .collectstatic.ts $(EXTRAS) $(SUPERVISOR) $(CONFIG) lint r2.deps .uwsgi.install

.installdeps.ts: build.deps
	cat build.deps | sudo xargs yum -y install
	touch $@

.testdeps.ts: build.deps
	cat build.deps | xargs rpm -q && \
	touch $@

$(PEP8): .installpackages.ts

$(COVERAGE): .installpackages.ts

$(VPYTHON): .python27.install

$(PYLINT): .installpackages.ts
$(PIP): .pip.install
$(PEP8): .installpackages.ts
$(NOSETESTS): .installpackages.ts

.installpackages.ts: $(PIP) requirements.txt env.sh
	$(ACTIVATE) && \
	export PKG_CONFIG_PATH=$(pfx)/lib/pkgconfig && \
	$(PIP) install $(PYPIURL) -r requirements.txt $(PIPFLAGS) && \
	touch $@

.install.ts: $(PIP) .installdeps.ts .installpackages.ts
	$(ACTIVATE) && \
	$(PIP) install . --upgrade && \
	touch $@

.develop.ts: .installpackages.ts
	$(ACTIVATE) && \
	$(VPYTHON) setup.py develop $(PYUSERFLAGS) && \
	touch $@

.collectstatic.ts: .installpackages.ts .tests.ts
	$(ACTIVATE) && \
	export DJANGO_SETTINGS_MODULE=$(ME).settings && \
	$(VPYTHON) $(ME)/manage.py collectstatic --noinput && \
	touch $@

.tests.ts: $(SRC) $(NONDISTSRC) $(COVERAGE)
	$(ACTIVATE) && \
	cd $(ME) && \
	export DJANGO_SETTINGS_MODULE=$(DJANGO_SETTINGS_MODULE) && \
	$(COVERAGE) run manage.py test -a '!slow' --nocapture --noinput --nomigrations && \
	cd .. && \
	touch $@

.alltests.ts: $(SRC) $(NONDISTSRC) $(COVERAGE)
	$(ACTIVATE) && \
	cd $(ME) && \
	export DJANGO_SETTINGS_MODULE=$(DJANGO_SETTINGS_MODULE) && \
	$(COVERAGE) run manage.py test --noinput --nomigrations && \
	cd .. && \
	touch $@

coverage.xml: .tests.ts
	$(ACTIVATE) && \
	$(COVERAGE) xml -i

htmlcov/%:
	$(ACTIVATE) && \
	$(COVERAGE) html -i

.coverage.ts: coverage.xml htmlcov/index.html

.pep8.ts: $(PEP8) $(NONDISTSRC)
.pep8.ts: $(SRC)
	$(ACTIVATE) && \
	$(PEP8) $(filter %.py, $?) && \
	touch $@

.pylint.ts: $(PYLINT) $(NONDISTSRC) .installpackages.ts
.pylint.ts: $(SRC)
	@$(ACTIVATE) && \
	echo $(PYLINT) --rcfile=pylintrc $(filter %.py, $?) && \
	touch $@

autopep8: .installpackages.ts .autopep8.ts
.autopep8.ts: $(SRC)
	$(ACTIVATE) && \
	for i in $(filter %.py, $?); do autopep8 -i $$i; done && \
	touch $@

lint: .pep8.ts .pylint.ts

test: lint .tests.ts

alltest: lint .alltests.ts

clean:
	@rm -f .*.ts env.sh && \
	find . -name "*.pyc" -delete

distclean: $(GLOBAL_CLEAN) clean
	rm -fv .*.{config,make,fetch,install,unpack,patch}
	rm -rf $(pfx)
	rm -rf $(BUILDDIR) dist
	rm -rf dists
	rm -f submakes/*.mak config.m4


$(pfx)/config/%: config/%
	mkdir -p $(@D)
	cp $< $@

$(pfx)/supervisor/%.conf: supervisor/%.conf
	mkdir -p $(@D)
	cp $< $@

$(ME).tar.gz: MANIFEST.sha1
	tar cvzf $@ $(ME)_server

MANIFEST.sha1: all
	find $(ME)_server -type f -exec $(SHASUM) {} \; > $@

release: all $(ME).tar.gz

################################################################################
# Helpers for managing the databases
################################################################################
PGBIN :=  psql -U postgres -h /var/run/postgresql
MANAGE := PYTHONUSERBASE=$(PYTHONUSERBASE) $(VPYTHON) $(ME)/manage.py

dropdb:
	$(PGBIN) <<< "DROP DATABASE $(ME);"
	rm -f \
	.roles.ts \
	.migrate.ts \
	.flush.ts \
	.truncate.ts \
	.loadseed.ts \
	.createdb.ts \
	.makemigrations.ts \
	.migrate.ts

.createdb.ts:
	sudo -u postgres createdb $(ME) -h /var/run/postgresql || /bin/true && \
	touch $@

.roles.ts: .develop.ts roles.sh
	./roles.sh && \
	touch $@

.makemigrations.ts: $(SRC)
	$(MANAGE) makemigrations && \
	touch $@

.migrate.ts: .roles.ts
	$(MANAGE) migrate && \
	touch $@

.flush.ts: .migrate.ts
	$(MANAGE) sqlflush | $(MANAGE) dbshell && \
	touch $@

.truncate.ts: .flush.ts
	echo 'TRUNCATE django_content_type CASCADE;' | $(MANAGE) dbshell && \
	touch $@

.loadseed.ts: .roles.ts .develop.ts env.sh
	$(ACTIVATE) && \
	./tools/copy_database.sh dev && \
	touch $@

.loadseedlocal.ts: .roles.ts .develop.ts
	$(ACTIVATE) && \
	./tools/copy_database.sh -f /tmp/db.dump dev

createdb: .createdb.ts

loadseed: .loadseed.ts

loadseedlocal: .loadseedlocal.ts

makemigrations: .makemigrations.ts

migrate: .migrate.ts

run:
	$(ACTIVATE) && \
	export DJANGO_SETTINGS_MODULE=$(DJANGO_SETTINGS_MODULE) && \
	$(VPYTHON) $(ME)/manage.py runserver 0.0.0.0:7745

altrun:
	$(ACTIVATE) && \
	export DJANGO_SETTINGS_MODULE=$(DJANGO_SETTINGS_MODULE) && \
	$(VPYTHON) $(ME)/manage.py runserver 0.0.0.0:6644

debug:
	$(ACTIVATE) && \
	$(VPYTHON) -mpdb $(ME)/manage.py runserver 0.0.0.0:7743

shell:
	$(ACTIVATE) && \
	$(MANAGE) shell_plus

dbshell:
	$(ACTIVATE) && \
	$(MANAGE) dbshell


#########################################################################################
# Submakes
#########################################################################################
DEST :=
SUBMAKES := $(wildcard submakes/*.mak.in)

include $(SUBMAKES:mak.in=mak)

LD_LIBRARY_PATH := $(pfx)/lib
PKG_CONFIG_PATH := $(pfx)/lib/pkgconfig
PATH := $(pfx)/bin:$(PATH)
OS := $(shell uname)

ifeq "$(OS)" "Darwin"
	DYLD_LIBRARY_PATH := $(pfx)/lib
	SHASUM := shasum
	PATH := $(pfx)/bin:/usr/local/opt:$(PATH)
	LDSHARED='$(CC) $(ARCHFLAGS) -dynamiclib -undefined suppress -flat_namespace'
endif

CFLAGS := -I$(pfx)/include $(ARCHFLAGS)
CPPFLAGS := -I$(pfx)/include $(ARCHFLAGS)
CXXFLAGS := -I$(pfx)/include $(ARCHFLAGS)
LDFLAGS := -L$(pfx)/lib $(ARCHFLAGS)

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

m4deps :=
ifeq "$(OS)" "Darwin"
	SHASUM := shasum
	m4deps :=
else
	SHASUM := sha1sum
endif

%.sh: config.m4 %.sh.in
	m4 $^ > $@
	chmod +x $@

hooks: .git/hooks/pre-push .git/hooks/pre-commit

.git/hooks/%:
	chmod 755 githooks/makelint
	ln -s ../../githooks/makelint $@
