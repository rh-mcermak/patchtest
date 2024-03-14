#!/bin/bash

if [[ "$1" == "TCLIST" ]]; then
    # Empty list means to run all the testcases:
    exit 0
fi

set -xe

# It turns out that dg-extract-results.sh relies on the logfiles
# summary (# of expected passes, # of unexpected failures, etc.) and
# counts the summary values based on that.  This is is okay for the
# normal dg-extract-results.sh use-case where it combines together
# correct (per single testcase) logs coming from parallel GDB testcase
# runs, where each of the input logfiles has such summary.
#
# But in our case we are combining incomplete log snippets coming from
# various terminated/incomplete/partial testsuite runs (kernel
# stall/crash, watchdog termination etc), where the log snippets do not
# have that summary (with an exception of the very last one).  The
# result is that only the last of the log snippets gets properly
# counted, and the results from the other log snippets are ignored.
#
# rlRun "EXPECTED_PASSES=$(awk '/^# of expected passes/ {print $NF}' systemtap.sum)"
# rlRun "UNEXPECTED_FAILURES=$(awk '/^# of unexpected failures/ {print $NF}' systemtap.sum)"
#
# So we really need to count the PASSes and FAILs on our own:
#

EXPECTED_PASSES=$(grep -a '^PASS: ' systemtap.sum | wc -l)
UNEXPECTED_FAILURES=$(grep -a '^FAIL: ' systemtap.sum | wc -l)

#
# For this rough check, ignoring other states such as KFAIL and others
# should be good enough.

case `arch` in
    x86_64)
        EXPECTED_PASSES_TRESHOLD=9000
        # UNEXPECTED_FAILURES_TRESHOLD=800
        ;;
    ppc64*)
        EXPECTED_PASSES_TRESHOLD=8000
        # UNEXPECTED_FAILURES_TRESHOLD=750
        ;;
    *)
        EXPECTED_PASSES_TRESHOLD=8000
        # UNEXPECTED_FAILURES_TRESHOLD=500
        ;;
esac

# Make this check only fail if something is very wrong.  The detailed test results
# review happens elsewhere anyway (*).  Keeping this test as an infrastructure
# failure indicator, or a serious component breakage indicator.
#
# https://sourceware.org/git/gitweb.cgi?p=bunsen.git;a=summary
#
UNEXPECTED_FAILURES_TRESHOLD=2000

test 0${EXPECTED_PASSES} -ge 0${EXPECTED_PASSES_TRESHOLD}
test 0${UNEXPECTED_FAILURES} -le 0${UNEXPECTED_FAILURES_TRESHOLD}

set +xe
