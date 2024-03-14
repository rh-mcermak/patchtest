#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/systemtap/Install/upstream-head
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

# Include Beaker environment
. /usr/share/beakerlib/beakerlib.sh || exit 1

ORIGPWD=$( pwd )

# Allow use of debuginfod
# export DEBUGINFOD_URLS=http://debuginfod.usersys.redhat.com:3632/
# export DEBUGINFOD_PROGRESS=1

# if [[ `arch` == *aarch* ]] || [[ `arch` == *s390* ]]; then
#     # Definitely do not use debuginfod on aarch64 and s390
#     unset DEBUGINFOD_URLS
# fi

export CLONE_CMD='git clone git://sourceware.org/git/systemtap.git'

PKGMGR="yum --nogpgcheck --enablerepo=\*"
rpm -q dnf && PKGMGR="dnf --setopt=clean_requirements_on_remove=false --setopt=metadata_expire=99999999 --nobest --setopt=strict=0 --nogpgcheck --enablerepo=\*"

rlJournalStart
    rlPhaseStartSetup
        rlRun "MY_USER=stapbuilduser"
        rlRun "getent passwd ${MY_USER} >/dev/null || useradd ${MY_USER}"
        # Work around bz1936469
        rlRun "rpm -q python-unversioned-command && rpm -e python-unversioned-command ||:"
    rlPhaseEnd

    rlPhaseStart FAIL "Install deps"
        rlRun "$PKGMGR clean all"
        # rlRun "$PKGMGR -y update"
        # rlRun "$PKGMGR -y install $RPM_REQS"
        rlRun "$PKGMGR -y install --setopt=multilib_policy=all libgcc glibc-devel gcc-c++ libstdc++-devel"
    rlPhaseEnd

    rlPhaseStart FAIL "Build RPMs and install them"
        MY_HOME="/home/${MY_USER}"
        MY_BUILD="${MY_HOME}/build"
        rm -rf /tmp/stap-buildlog /tmp/stap-specfile /tmp/stap-rpms /tmp/stap-git-log
cat > ${MY_BUILD} <<-EOF
set -xe
echo '%_unpackaged_files_terminate_build 0' > ~/.rpmmacros
rm -rf systemtap
( echo attempt-1; $CLONE_CMD) || \
( echo attempt-2; sleep 20; $CLONE_CMD ) || \
( echo attempt-3; sleep 90; $CLONE_CMD )
cd systemtap
if test -n "${CHECKOUT_COMMIT}"; then
    echo "### ATTEMPTING TO CHECK OUT ${CHECKOUT_COMMIT} ###"
    git checkout ${CHECKOUT_COMMIT} || exit 1
else
    echo "### NOT ATTEMPTING TO CHECK OUT SPECIFIC COMMIT ###"
fi
LASTCOMMIT=\$( git log -1 --format=format:'%ct.%h' )
git log -20 --oneline > /tmp/stap-git-log
sed -i "s/%{?dist}/\.qetst\.\${LASTCOMMIT}%{?dist}/" systemtap.spec
sed -i "s/%{?release_override}//" systemtap.spec
sed -i 's/with_publican\ 1/with_publican\ 0/g' systemtap.spec
sed -i 's/with_docs\ 1/with_docs\ 0/g' systemtap.spec
sed -i 's/with_emacsvim\ 1/with_emacsvim\ 0/' systemtap.spec
if [[ $(rpm --eval 0%{rhel}) -eq 7 ]]; then
    # The upstream specfile tries to require dyninst-devel >= 10.1 on rhel7, which
    # is not good for base rhel-7 package (devtoolset-9-dyninst is a special case).
    # https://sourceware.org/git/gitweb.cgi?p=systemtap.git;a=blob;f=systemtap.spec;h=670e4010141f5c51e749743bace01815b5585213;hb=HEAD#l134
    sed -i 's/^BuildRequires: dyninst-devel.*/BuildRequires: dyninst-devel/' systemtap.spec
    # RHEL-7 doesn't have dyninst on arches other than ppc64 (big endian) and x86_64.
    if ! (arch | egrep -q '^(x86_64|ppc64)$'); then
        # https://sourceware.org/git/gitweb.cgi?p=systemtap.git;a=blob;f=systemtap.spec;h=670e4010141f5c51e749743bace01815b5585213;hb=HEAD#l18
        sed -i 's/%{!?with_dyninst: %global with_dyninst 0.*/%{!?with_dyninst: %global with_dyninst 0}/' systemtap.spec
    fi
fi
git config --global user.name "Martin Cermak"
git config --global user.email mcermak@redhat.com
git commit -am 'Disable publican and emacs, tweak Release.'
cat systemtap.spec > /tmp/stap-specfile
./configure --prefix=/dev/null
make rpm 2>&1 | tee /tmp/stap-buildlog
set +xe
EOF
        rlRun "chown ${MY_USER}:${MY_USER} ${MY_BUILD}"
        rlRun "su - ${MY_USER} -c 'bash ${MY_BUILD}'" || exit 1
        rlRun "RPMS=\"$( find ${MY_HOME}/rpmbuild/RPMS -type f -name '*rpm' -printf '%p ' )\""
        rlRun "mkdir -p /tmp/stap-rpms /home/stap-rpms"
        rlRun "cp $RPMS /tmp/stap-rpms/"
        rlRun "cp $RPMS /home/stap-rpms/"
        rlRun "$PKGMGR remove -y systemtap-runtime-java systemtap-runtime-virthost \
            systemtap-testsuite systemtap-devel systemtap systemtap-initscript \
            systemtap-runtime systemtap-server systemtap-runtime-virtguest \
            systemtap-sdt-devel systemtap-client systemtap-debuginfo" 0,1
        rlRun "rm -rf /usr/share/systemtap"
        rlRun "$PKGMGR clean all"
        rlRun "$PKGMGR install -y ${RPMS}"
        rlRun "rpm -qa | grep systemtap | sort"
        # Test https://bugzilla.redhat.com/show_bug.cgi?id=2012907
        rlRun "rpm -V systemtap-runtime"
        RPMVER=$(echo $RPMS | grep -o 'systemtap-[0-9]\+[^\ ]*' | grep -o '.*\.el[0-9]\+')
        RPMDIR=/home/.systemtap-upstream-head-rpms/$RPMVER
        rm -rf ${RPMDIR}; mkdir -p ${RPMDIR};
        rlRun "cp ${RPMS} ${RPMDIR}/" 0 "Keep built PRMS in ${RPMDIR}"
    rlPhaseEnd

    rlPhaseStart WARN "Run stap-prep"
        rlRun "rpm -qa | grep ^kernel | grep -v `uname -r` | xargs rpm -e --nodeps" 0-255
        # Following should work because we use DEBUGINFOD_URLS set above
        # Even for kernel-rt.
        # rlRun "$ORIGPWD/stap-prep" 0-255
        rlRun "stap-prep" 0-255
    rlPhaseEnd

#     # stap-prep doesn't play well with kernel-rt
#     if ! (uname -r | fgrep -q '.rt'); then
#         rlPhaseStart WARN "Run stap-prep"
#             rlRun "rpm -qa | grep ^kernel | grep -v `uname -r` | xargs rpm -e --nodeps" 0-255
#             rlRun "$ORIGPWD/stap-prep" 0,127 ||
#                 rlRun "./stap-prep-nfs"
#         rlPhaseEnd
#     fi

    rlPhaseStart FAIL "Sanity Check"
        rlRun "stap --version"
        rlRun "which stap"
        rlRun "stap -vve 'probe kernel.function(\"vfs_read\"){ log(\"hey!\"); exit() }'"
    rlPhaseEnd

    rlPhaseStart WARN "Submit interesting bits"
        rlFileSubmit '/tmp/stap-buildlog'
            rlRun 'tar cf /tmp/stap-upstream-rpms.tar /tmp/stap-rpms'
            rlRun 'xz /tmp/stap-upstream-rpms.tar'
        rlFileSubmit '/tmp/stap-upstream-rpms.tar.xz'
            rlRun "rm -rf /tmp/stap-upstream-rpms.tar.xz"
        rlFileSubmit '/tmp/stap-specfile'
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "userdel -f ${MY_USER}"
        rlRun "rm -rf ${MY_HOME}"
    rlPhaseEnd

rlJournalPrintText
rlJournalEnd
