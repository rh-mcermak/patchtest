# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Makefile of /tools/systemtap/Install/upstream-head
#   Description: create RPMs from the upstream head and install them
#   Author: Martin Cermak <mcermak@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2014 Red Hat, Inc.
#
#   This program is free software: you can redistribute it and/or
#   modify it under the terms of the GNU General Public License as
#   published by the Free Software Foundation, either version 2 of
#   the License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE.  See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program. If not, see http://www.gnu.org/licenses/.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

export TEST=/tools/systemtap/Install/upstream-head
export TESTVERSION=1.0
export RPM_REQS=libstdc++ libstdc++-devel libstdc++-devel.x86_64 libgcc glibc-devel gcc-c++ \
       kernel-devel kernel-headers git curl tar dejagnu \
       elfutils-devel gettext gettext-devel nss-devel avahi-devel \
       dyninst-devel libselinux-devel sqlite-devel json-c-devel ncurses-devel \
       crash-devel rpm-devel emacs jpackage-utils java-devel libvirt-devel \
       libxml2-devel readline-devel python-devel python3-devel rpm-build \
       python-setuptools python2-setuptools python2-pyparsing dyninst-devel \
       elfutils-debuginfod-client-devel

BUILT_FILES=

FILES=$(METADATA) runtest.sh Makefile PURPOSE stap-prep-nfs stap-prep

.PHONY: all install download clean

run: $(FILES) build
	./runtest.sh

build: $(BUILT_FILES)
	test -x runtest.sh || chmod a+x runtest.sh
	test -x stap-prep || chmod a+x stap-prep

clean:
	rm -f *~ $(BUILT_FILES)

up:
	ssh liver2.lab.eng.brq.redhat.com /var/www/html/mcermak/systemtap/gitcache/update.sh && \
	echo "Systemtap git cache updated."

reqs:
	echo $(RPM_REQS)



include /usr/share/rhts/lib/rhts-make.include

$(METADATA): Makefile
	@echo "Owner:           Martin Cermak <mcermak@redhat.com>" > $(METADATA)
	@echo "Name:            $(TEST)" >> $(METADATA)
	@echo "TestVersion:     $(TESTVERSION)" >> $(METADATA)
	@echo "Path:            $(TEST_DIR)" >> $(METADATA)
	@echo "Description:     Build fresh systemtap RPMs from the upstream git and install them." >> $(METADATA)
	@echo "Type:            Install" >> $(METADATA)
	@echo "TestTime:        8h" >> $(METADATA)
	@echo "RunFor:          nothing" >> $(METADATA)
	$(foreach  package, $(RPM_REQS), echo "Requires:        $(package)" >> $(METADATA);)
	@echo "Priority:        Normal" >> $(METADATA)
	@echo "License:         GPLv2+" >> $(METADATA)
	@echo "Confidential:    no" >> $(METADATA)
	@echo "Destructive:     no" >> $(METADATA)

	rhts-lint $(METADATA)
