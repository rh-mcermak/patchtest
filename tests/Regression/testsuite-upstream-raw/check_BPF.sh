#!/bin/bash

# Show the testcase list on demand.
if [[ "$1" == "TCLIST" ]]; then
    if [[ "$(arch)" == "s390x" ]]; then
        # Save the s390x machine time (regardless the rhel major):
        # Almost all the testcases are failing there, and those, that
        # do not, are flaky.
        echo -n "notest.exp"
    else
        echo -n "bpf-asm.exp bpf.exp"
    fi
    exit 0
fi

_LOG=systemtap.check
cp systemtap.sum $_LOG

_cleanup()
{
    rm $_LOG
}
trap _cleanup EXIT

set -xe

EXPECTED_PASSES_TRESHOLD=-1

if test $(rpm --eval '0%{rhel}') -eq 8; then
    # systemtap-4.0-7.el8, kernel-4.18.0-64.el8
    case `arch` in
        x86_64)
            EXPECTED_PASSES_TRESHOLD=55
            sed -i '/FAIL: bigmap1.stp/d' $_LOG || :
            sed -i '/FAIL: cast_op_tracepoint.stp/d' $_LOG || :
            sed -i '/FAIL: logging1.stp/d' $_LOG || :
            sed -i '/FAIL: perf1.stp/d' $_LOG || :
            sed -i '/FAIL: pr23875_loop.stp/d' $_LOG || :
            sed -i '/FAIL: pr23875_smash.stp/d' $_LOG || :
            sed -i '/FAIL: reg_alloc3.stp/d' $_LOG || :
            sed -i '/FAIL: string3.stp/d' $_LOG || :
            sed -i '/FAIL: timer1.stp/d' $_LOG || :
            sed -i '/FAIL: timer2.stp/d' $_LOG || :
            sed -i '/FAIL: tracepoint1.stp/d' $_LOG || :
            sed -i '/FAIL: tracepoint1.stp/d' $_LOG || :
        ;;
        aarch64)
            EXPECTED_PASSES_TRESHOLD=58
            sed -i '/FAIL: bigmap1.stp/d' $_LOG || :
            sed -i '/FAIL: logging1.stp/d' $_LOG || :
            sed -i '/FAIL: perf1.stp/d' $_LOG || :
            sed -i '/FAIL: perf2.stp/d' $_LOG || :
            sed -i '/FAIL: pr23875_loop.stp/d' $_LOG || :
            sed -i '/FAIL: pr23875_smash.stp/d' $_LOG || :
            sed -i '/FAIL: reg_alloc3.stp/d' $_LOG || :
            sed -i '/FAIL: string3.stp/d' $_LOG || :
            sed -i '/FAIL: timer2.stp/d' $_LOG || :
            sed -i '/FAIL: tracepoint1.stp/d' $_LOG || :
        ;;
        ppc64le)
            EXPECTED_PASSES_TRESHOLD=53
            sed -i '/FAIL: array.stp/d' $_LOG || :
            sed -i '/FAIL: array_preinit.stp/d' $_LOG || :
            sed -i '/FAIL: context_vars1.stp/d' $_LOG || :
            sed -i '/FAIL: context_vars2.stp/d' $_LOG || :
            sed -i '/FAIL: context_vars2.stp/d' $_LOG || :
            sed -i '/FAIL: context_vars3.stp/d' $_LOG || :
            sed -i '/FAIL: globals2.stp/d' $_LOG || :
            sed -i '/FAIL: globals3.stp/d' $_LOG || :
            sed -i '/FAIL: kprobes.stp/d' $_LOG || :
            sed -i '/FAIL: logging1.stp/d' $_LOG || :
            sed -i '/FAIL: perf1.stp/d' $_LOG || :
            sed -i '/FAIL: perf2.stp/d' $_LOG || :
            sed -i '/FAIL: pr23875_loop.stp/d' $_LOG || :
            sed -i '/FAIL: pr23875_loop.stp/d' $_LOG || :
            sed -i '/FAIL: pr23875_smash.stp/d' $_LOG || :
            sed -i '/FAIL: reg_alloc3.stp/d' $_LOG || :
            sed -i '/FAIL: string3.stp/d' $_LOG || :
            sed -i '/FAIL: timer2.stp/d' $_LOG || :
            sed -i '/FAIL: tracepoint1.stp/d' $_LOG || :
        ;;
        s390x)
            # Many testcases fail for s390x, many of them are flaky
            # Not worth testing at all at this stage at all probably.
            echo "INFO: UNSUPPORTED RHEL7 ARCHITECTIRE ($(arch))"
            exit 0
        ;;
        *)
            echo "ERROR: UNSUPPORTED RHEL8 ARCHITECTIRE"
            exit 1
        ;;
    esac
elif test $(rpm --eval '0%{rhel}') -eq 7; then
    case `arch` in
        x86_64)
            # (rhel7) systemtap-3.3-3.el7.x86_64, kernel-3.10.0-993.el7.x86_64
            if test $(rpm -q --queryformat='%{version}\n' kernel | awk -F. '{print $1}') -eq 3; then
                EXPECTED_PASSES_TRESHOLD=32
                sed -i '/FAIL: cast_op_tracepoint.stp/d' $_LOG || :
                sed -i '/FAIL: perf2.stp/d' $_LOG || :
                sed -i '/FAIL: reg_alloc3.stp/d' $_LOG || :
                sed -i '/FAIL: tracepoint1.stp/d' $_LOG || :
            elif test $(rpm -q --queryformat='%{version}\n' kernel | awk -F. '{print $1}') -eq 4; then
            # (rhel-alt-7) systemtap-3.3-3.el7.x86_64, kernel-4.14.0-115.el7a.x86_64
                echo "ERROR: known bug on rhel-alt ('map entry 0: Function not implemented')"
                echo "<@fche> # CONFIG_BPF_SYSCALL is not set"
                exit 0
            else
                echo "ERROR: UNSUPPORTED RHEL7 KERNEL VERSION"
                exit 1
            fi
        ;;
    *)
        echo "INFO: UNSUPPORTED RHEL7 ARCHITECTIRE ($(arch))"
        exit 0
        ;;
    esac
elif test $(rpm --eval '0%{fedora}') -eq 29; then
    case `arch` in
        x86_64)
	    EXPECTED_PASSES_TRESHOLD=33
            sed -i '/FAIL: array.stp/d' $_LOG || :
            sed -i '/FAIL: bigmap1.stp/d' $_LOG || :
            sed -i '/FAIL: cast_op_tracepoint.stp/d' $_LOG || :
            sed -i '/FAIL: no_end.stp/d' $_LOG || :
            sed -i '/FAIL: printf.stp/d' $_LOG || :
            sed -i '/FAIL: reg_alloc3.stp/d' $_LOG || :
            sed -i '/FAIL: string1.stp/d' $_LOG || :
            sed -i '/FAIL: timer2.stp/d' $_LOG || :
            sed -i '/FAIL: tracepoint1.stp/d' $_LOG || :
        ;;
        *)
            # No test results for other arches yet
            true;
        ;;
    esac
else
    echo "ERROR: UNSUPPORTED RHELMAJOR"
    exit 1
fi

true _v_v_v_v_v_v_v_v_v_v_v_  UNEXPECTED FAILURES: _v_v_v_v_v_v_v_v_v_v_v_v_v_v_
fgrep 'FAIL: ' $_LOG || :
true -^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-


EXPECTED_PASSES=$(grep -a '^PASS: ' $_LOG | wc -l)
UNEXPECTED_FAILURES=$(grep -a '^FAIL: ' $_LOG | wc -l)

test ${EXPECTED_PASSES_TRESHOLD} -gt 1
test 0${EXPECTED_PASSES} -ge 0${EXPECTED_PASSES_TRESHOLD}
test 0${UNEXPECTED_FAILURES} -eq 0

rm $_LOG

set +xe


