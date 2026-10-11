#!/bin/bash

_evaluate_coredump_result() {
    local rc=$1
    local out="$2"
    if [[ $rc -eq 0 || $rc -eq 1 ]] && { [[ "$out" == "No coredumps found." ]] || [[ "$out" == "No match found." ]]; }; then
        echo "INFO: No core dumps found."
    else
        if [[ -n "$out" ]]; then
            echo "$out"
        fi
        if [[ $rc -ne 0 ]]; then
            echo "WARN: coredumpctl failed with exit code $rc."
        fi
    fi
}
