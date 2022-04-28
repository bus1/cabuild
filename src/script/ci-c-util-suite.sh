#!/bin/bash

#
# C-Util CI Suite Scheduler
#
# This script assembles the job-array to run by the C-Util CI. It integrates
# with the CI-workflow (see its definition for details), parses the provided
# parameters and assembles an array of jobs to be run.
#

set -e

#
# Variable Definitions
#

CAB_JOBS=()
CAB_M32="false"
CAB_MESONARGS=""
CAB_SOURCE="."
CAB_VALGRIND="false"

#
# Job Definitions
#

CAB_JOBS+=("c-util-gcc")
CAB_JOBS+=("c-util-gcc-debug")
CAB_JOBS+=("c-util-gcc-ndebug")
CAB_JOBS+=("c-util-gcc-optimized")
CAB_JOBS+=("c-util-llvm")

#
# Argument Parsers
#

if [[ ${CTX_INPUTS_M32} == "true" ]] ; then
        CAB_M32="true"
fi

if [[ ${CTX_INPUTS_VALGRIND} == "true" ]] ; then
        CAB_VALGRIND="true"
fi

CAB_MESONARGS=$(jq -cRs . < <(printf "%s" "${CTX_INPUTS_MESONARGS}"))
CAB_SOURCE=$(jq -cRs . < <(printf "%s" "${CTX_INPUTS_SOURCE}"))

#
# Job-list Assembly
#

CAB_JSON="["
for CAB_I in "${CAB_JOBS[@]}" ; do
        CAB_JSON+="{"
        CAB_JSON+="\"job\":\"${CAB_I}\""
        CAB_JSON+=",\"m32\":${CAB_M32}"
        CAB_JSON+=",\"mesonargs\":${CAB_MESONARGS}"
        CAB_JSON+=",\"source\":${CAB_SOURCE}"
        CAB_JSON+=",\"valgrind\":${CAB_VALGRIND}"
        CAB_JSON+="},"
done
CAB_JSON=${CAB_JSON::-1} # drop last comma
CAB_JSON+="]"

#
# Output Generator
#

echo "::set-output name=jobs::${CAB_JSON}"
