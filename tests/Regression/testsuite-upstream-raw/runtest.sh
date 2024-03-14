#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/systemtap/Regression/testsuite-upstream-raw
#   Description: testsuite-upstream-raw
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

# # What part of the testsuite should we run (and then check for errors)?
# _WHAT=${_WHAT:-DEFAULT}
# 
# export AVC_ERROR='+no_avc_check'
# touch /tmp/disable-qe-abrt
# 
# unset DEBUGINFOD_PROGRESS
# if test $(rpm --eval "0%{rhel}") -ge 9; then
#     # Allow use of debuginfod
#     export DEBUGINFOD_URLS=http://debuginfod.usersys.redhat.com:3632/
#     # export DEBUGINFOD_PROGRESS=1
# else
#     unset DEBUGINFOD_URLS
# fi
# 
# mypid=$$
# 
# trap '' SIGHUP SIGINT SIGQUIT SIGABRT
# 
# ORIGPWD=$( pwd )
# 
# PKGMGR="yum --skip-broken --nogpgcheck"
# rpm -q dnf && PKGMGR="dnf --setopt=strict=0 --nogpgcheck"
# 
# STARTDATE=$(date +%Y-%m-%d-%H-%M-%S)
# STAPSRPM=$(rpm -qif `which stap` | awk '/Source RPM/ {print $NF}' | sort -u | sed 's/\.src\.rpm//')
# SUITERPM=$(rpm --queryformat '%{name}\n' -qf `which stap` | grep -o '.*systemtap' | sort -u)-testsuite
# SUITELOC=$(rpm -ql $SUITERPM | grep -o '.*systemtap\/testsuite/' | sort -u)
# 
# test_primary_arch_only ()
# {
#     echo "=== TESTING PRIMARY ARCH ONLY ==="
#     sed -i '/^proc arch_compile_flags/,/^}/d' $SUITELOC/lib/compile_flags.exp
#     echo 'proc arch_compile_flags {} { return 1 }' >> $SUITELOC/lib/compile_flags.exp
# }
# 
# kill_chldrn () {
#     local ppid=$1
#     local chldrn=$(pgrep -P $ppid)
# 
#     for pid in $chldrn; do
#         kill_chldrn $pid
#         kill $pid
#     done
# }
# 
# 
# # For devtoolset, compat arch support was dropped for non-x86_64 arches.  Ref: bz1493500
# if echo $SUITELOC | grep -q toolset && arch | egrep -q '^(ppc64|s390x)$'; then
#     test_primary_arch_only
# elif test $(rpm -E '0%{rhel}') -ge 8 -a "$(arch)" != "x86_64"; then
#     test_primary_arch_only
# fi
# 
# # Currently the Makefile overrides what was set in the env via
# # http://pkgs.devel.redhat.com/cgit/rpms/devtoolset-7/commit/?h=devtoolset-7.1-rhel-7&id=e305f5912a13bd2ca04ac319afca50bfab6f4aea
# # And actually if the base rhel dyninst is installed, the dts testsuite runs against it rather than agains
# # the dts-stap - producing irrelevant test results.
# #
# # A real fix on the stap side might be:
# # -LD_LIBRARY_PATH=$(DESTDIR)$(libdir)/systemtap
# # +LD_LIBRARY_PATH=$(DESTDIR)$(libdir)/systemtap:$(DESTDIR)$(libdir)/dyninst
# # in the Makefile.am etc, but let's work this around for now in a way that we simply use the
# # LD_LIBRARY_PATH taken directly from the env:
# if echo $SUITELOC | grep -q toolset; then
#     sed -i 's/^LD_LIBRARY_PATH/# LD_LIBRARY_PATH/' $SUITELOC/Makefile
# fi
# 


SUITERPM=${SUITERPM:-systemtap-testsuite}
SUITELOC=${SUITELOC:-/usr/share/systemtap/testsuite/}
PKGMGR=${PKGMGR:-dnf}

rlJournalStart
    rlPhaseStart WARN "Install"
        # Try to free disk space by uninstalling unneeded kernel packages
        rlRun "rpm -qa | grep ^kernel | grep -v `uname -r` | xargs rpm -e --nodeps" 0-255
        # https://github.com/teemtee/tmt/issues/2762
        rlRun "$PKGMGR -y install --setopt=multilib_policy=all libstdc++ libgcc glibc-devel gcc-c++ libstdc++-devel"
        rlRun "stap-prep"
    rlPhaseEnd

    rlPhaseStartSetup
        rlServiceStop firewalld
        rlServiceStop iptables
        rlServiceStop ip6tables
        rlServiceStop kdump
        rlServiceStart avahi-daemon
        rlRun "sysctl -w kernel.panic=1"
        rlRun "sysctl -w kernel.panic_on_oops=1"
    rlPhaseEnd

    rlPhaseStart WARN "Info"
        rlLogInfo "SUITERPM=${SUITERPM}"
        rlLogInfo "SUITELOC=${SUITELOC}"
        rlLogInfo "PKGMGR=${PKGMGR}"
        # rlRun "uname -a"
        # rlRun "rpm -q $SUITERPM"
        # rlRun "cat /etc/os-release"
        rlRun "stap-report"
    rlPhaseEnd

# 
# 
#     MYDMESGDIR=/root/mydmesg
#     mkdir -p $MYDMESGDIR
#     if strings $(which dmesg) | fgrep -q -- '-w'; then
#         rlPhaseStart FAIL "Run dmesg recorder."
#             MYTIMESTAMP=$(date +%s)
#             dmesg -wH > $MYDMESGDIR/dmesg$MYTIMESTAMP &
#             MYDMESGPID=$!
#             rlLogInfo "Dmesg recorder file: $MYDMESGDIR/dmesg$MYTIMESTAMP"
#             rlLogInfo "Dmesg PID: $MYDMESGPID"
#         rlPhaseEnd
#     fi
# 
    rlPhaseStart FAIL "sanity check"
        rlRun "stap -vve 'probe kernel.function(\"vfs_read\"){ log(\"hey!\"); exit() } probe timer.s(60){log(\"timeout\"); exit()}'"
        rlRun "stap -vvl 'process(\"/usr/sbin/fdisk\").function(\"main\")'" 0-255
    rlPhaseEnd
# 
#     if ! test -f $SUITELOC/systemtap.log; then
#         rlPhaseStart WARN "Apply blacklist"
#             # === RHEL7 ===
#             if rlIsRHEL 7; then
#                 if arch | grep -q s390; then
#                     true
#                     # PR17270
#                     #rlRun "rm -f systemtap.onthefly/hrtimer_onthefly.exp"
#                     #rlRun "rm -f systemtap.onthefly/uprobes_onthefly.exp"
#                     #rlRun "rm -f systemtap.onthefly/kprobes_onthefly.exp"
#                     # PR17140
#                     #rlRun "rm -f systemtap.examples/profiling/functioncallcount.stp"
#                 elif arch | grep -q ppc; then
#                     true
#                     # PR17270
#                     #rlRun "rm -f systemtap.onthefly/hrtimer_onthefly.exp"
#                     #rlRun "rm -f systemtap.onthefly/uprobes_onthefly.exp"
#                     #rlRun "rm -f systemtap.onthefly/kprobes_onthefly.exp"
#                     # PR17126
#                     #rlRun "rm -f systemtap.base/tracepoints.exp"
#                     # BZ1153082
#                     #rlRun "rm -f systemtap.clone/main_quiesce.exp"
#                 #elif rpm -q systemtap | grep -q '2.4-16.el7_0'; then
#                     # BZ1145958
#                     #rlRun "rm -f systemtap.base/process_resume.exp"
#                 fi
#             # === FEDORA ===
#             elif grep -qi fedora /etc/redhat-release; then
#                 # BZ1153082
#                 rlRun "rm -f systemtap.clone/main_quiesce.exp"
#             fi
# 
#             # Work around problem fixed in https://sourceware.org/git/gitweb.cgi?p=systemtap.git;a=commitdiff;h=a9b0aa4dbd1aa7a1c36eba8102e1445e8f2eb8b8
#             rlRun "sed -i 's/exit\ 0/return/' $(fgrep -ril 'exit 0' $(find . -type f -name '*.exp')) ||:"
#         rlPhaseEnd
#     else
#         rlPhaseStart FAIL "Post-process anticipated reboot"
#             # Sometimes the testsuite crashes the kernel or causes stall.
#             # In case --ignore-panic is set, the box gets rebooted (bz1155644).
#             # This shouldn't happen. It'd be nice to report it as FAIL, but that
#             # appears to be too pedantic.  We'll need this bell to ring when
#             # too many unexpected failures get reported by the upstream test driver.
#             # rlRun "false"
# 
#             # Remove testcases that have already been run
#             for tc in $( awk '/^Running.*exp\ \.\.\.$/ {print $2}' *systemtap.log ); do
#                 echo $tc | grep -q 'systemtap/notest.exp' && continue
#                 test -f $tc && rm -f $tc && rlLog "Removed $tc"
#             done
# 
#             #generate random hash
#             HASH=$(date | md5sum | cut -c 1-32 -)
# 
#             # save existing logs before creating new ones
#             rlRun "mv systemtap.log ${HASH}-systemtap.log"
#             rlRun "mv systemtap.sum ${HASH}-systemtap.sum"
# 
#             # clean up garbage incl. systemtap.log
#             rlRun "make clean"
#         rlPhaseEnd
#     fi
# 
    rlPhaseStartTest
#         # Start internal watchdog if running in beaker
#         if test -n $JOBID; then
#             rlLogInfo "Starting internal watchdog ..."
#             $ORIGPWD/internal-watchdog.sh "$SUITELOC/systemtap.sum" &
#             __WATCHDOG_PID=$!
#             sleep 3
#             if ps -p $__WATCHDOG_PID; then
#                 rlLogInfo "Internal watchdog running (pid $__WATCHDOG_PID)."
#             else
#                 rlFail "Problem starting the internal watchdog."
#             fi
#         fi
# 
#         # The _WHAT env var allows the test to only run selected subset of all
#         # the tests and perform specific checks on the resulting logs.
#         #
#         # Accepted values: BPF
# 
#         # Make sure we always have the system identification print_system_info()
#         # Work around removal of print_system_info() from environment_sanity.exp
#         rlRun "cp $ORIGPWD/my_environment_sanity.exp $SUITELOC/systemtap/"
# 
#         # run the testsuite (grab the list of testcases from the respective check* file)
# 	TESTCASES=$(bash ${ORIGPWD}/check_${_WHAT}.sh TCLIST)
#         rlRun "make RUNTESTFLAGS='$TESTCASES' installcheck 2>&1"
        rlRun "pushd $SUITELOC"
        rlRun "make installcheck 2>&1"
# 
#         # Kill internal watchdog if running in beaker
#         if ! test -z $JOBID; then
#             rlLogInfo "Killing internal watchdog ..."
#             kill -s TERM $__WATCHDOG_PID
#         fi
    rlPhaseEnd
# 
#     rlPhaseStart FAIL "Put all the log fragments together"
#         rlRun "$ORIGPWD/dg-extract-results.sh *systemtap.sum > big-systemtap.sum"
#         rlRun "$ORIGPWD/dg-extract-results.sh -L *systemtap.log > big-systemtap.log"
#         rlRun "mv --force big-systemtap.sum systemtap.sum"
#         rlRun "mv --force big-systemtap.log systemtap.log"
#         # remove the hash-prefixed fragments
#         # these are needed for the resume mode, but since we got to this point,
#         # we most likely processed all the testcases somehow, put all the pieces
#         # together and can start cleaning up and reporting
#         rlRun "rm -f *-systemtap.{log,sum}"
#     rlPhaseEnd
# 
#     rlPhaseStart FAIL "rlFileSubmit logs"
#         rlRun "xz --keep --force systemtap.log"
#         rlFileSubmit "systemtap.log.xz"
#         rlRun "xz --keep --force systemtap.sum"
#         rlFileSubmit "systemtap.sum.xz"
#         rlRun "rm systemtap.log.xz systemtap.sum.xz"
#     rlPhaseEnd
# 
#     if [[ "$_WHAT" == "DEFAULT" ]]; then
#     rlPhaseStart FAIL "save logs to /mnt/scratch"
#         MP=$( mktemp -d )
#         # Refer to /tools/systemtap/Install/upstream-head
#         SD=rhpkg; rpm -q systemtap | grep -q qetst && SD=upstream
#         rlRun "echo ${BEAKER}jobs/${JOBID} > job.txt"
#         rlRun "tar cf mydmesg.tar $MYDMESGDIR"
#         rlRun "xz mydmesg.tar"
#         rlRun "mount -o rw,nolock nfs.englab.brq.redhat.com:/scratch/mcermak $MP"
#         if test $(rpm --eval '0%{rhel}') -eq 8 && (! echo ${STAPSRPM} | grep '\.el8'); then
#             rlRun "LOGNAME=${MP}/testlogs/systemtap.${SD}/${STAPSRPM}.el8.$(uname -m)-${STARTDATE}"
#         else
#             rlRun "LOGNAME=${MP}/testlogs/systemtap.${SD}/${STAPSRPM}.$(uname -m)-${STARTDATE}"
#         fi
#         rlRun "mkdir -p $( dirname $LOGNAME )"
#         rlRun "tar cJf ${LOGNAME}.tar.xz systemtap.log systemtap.sum job.txt mydmesg.tar.xz"
# 
#         # # Upload logs to bunsen instance on tofan if running in beaker
#         # if ! test -z $JOBID; then
#         #     LOGFULLNAME="${LOGNAME}.tar.xz"
#         #     LOGBASENAME="$(basename $LOGFULLNAME)"
#         #     rlLogInfo "Uploading test log to bunsen..."
#         #     rlRun "cat $LOGFULLNAME | \
#         #                curl -X POST -F project=systemtap-qe \
#         #                    -F tarballname=$LOGBASENAME \
#         #                    -F 'tar=@-' \
#         #                    http://tofan.usersys.redhat.com:8013/bunsen-upload.py"
#         # fi
#         rlRun "umount -l $MP && sleep 3 && rm -rf $MP"
#     rlPhaseEnd
#     fi
# 
#     rlPhaseStart FAIL "Log checks ($_WHAT)"
#         rlRun "bash ${ORIGPWD}/check_${_WHAT}.sh"
#     rlPhaseEnd
# 
    rlPhaseStartCleanup
        rlServiceRestore firewalld
        rlServiceRestore iptables
        rlServiceRestore ip6tables
        rlServiceRestore kdump
        rlServiceRestore avahi-daemon
#         rlRun "echo $$"
#         rlRun "echo $BASHPID"
#         rlRun "pstree -p $$"
#         rlRun "kill_chldrn $mypid"
#         rlRun "pstree -p $$"
        rlRun popd
#         kill -9 $MYDMESGPID ||:
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
# 
# rm -f /tmp/disable-qe-abrt
