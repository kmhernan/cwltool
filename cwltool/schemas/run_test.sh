#!/bin/bash

read -rd "\000" helpmessage <<EOF
$(basename $0): Run common workflow tool description language conformance tests.

Syntax:
        $(basename $0) [RUNNER=/path/to/cwl-runner]

Options:
EOF

DRAFT=draft-2
TEST_N=""

while [[ -n "$1" ]]
do
    arg="$1"; shift
    case "$arg" in
        --help)
            echo >&2 "$helpmessage"
            echo >&2
            exit 1
            ;;
        -n*)
            TEST_N=$arg
            ;;
        *=*)
            eval $(echo $arg | cut -d= -f1)=\"$(echo $arg | cut -d= -f2-)\"
            ;;
    esac
done

runs=0
failures=0

checkexit() {
    if [[ "$?" != "0" ]]; then
        failures=$((failures+1))
    fi
}

runtest() {
    echo "--- Running conformance test $DRAFT on $1 ---"

    "$1" --version

    runs=$((runs+1))
    (cd $DRAFT
     python -mcwltool.cwltest --tool "$1" --test=conformance_test_$DRAFT.yaml $TEST_N --basedir $DRAFT
    )
    checkexit
}

runtest "$(readlink -f $RUNNER)"

# Final reporting

echo

if [[ $failures != 0 ]]; then
    echo "$failures tool tests failed"
else
    if [[ $runs == 0 ]]; then
        echo >&2 "$helpmessage"
        echo >&2
        exit 1
    else
        echo "All tool tests succeeded"
    fi
fi

exit $failures
