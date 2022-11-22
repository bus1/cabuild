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

CAB_JOBS_LINUX=()
CAB_JOBS_MACOS=()
CAB_JOBS_WINDOWS=()
CAB_LINUX="false"
CAB_M32="false"
CAB_MACOS="false"
CAB_MATRIX_M32=()
CAB_MATRIXMODE="false"
CAB_MESONARGS=""
CAB_SOURCE="."
CAB_VALGRIND="false"
CAB_WINDOWS="false"

#
# Job Definitions
#

CAB_JOBS_LINUX+=("c-util-gcc")
CAB_JOBS_LINUX+=("c-util-gcc-debug")
CAB_JOBS_LINUX+=("c-util-gcc-ndebug")
CAB_JOBS_LINUX+=("c-util-gcc-optimized")
CAB_JOBS_LINUX+=("c-util-llvm")

CAB_JOBS_MACOS+=("c-util-llvm")

CAB_JOBS_WINDOWS+=("c-util-msvc")

#
# Argument Parsers
#

if [[ ${CTX_INPUTS_LINUX} == "true" ]] ; then
        CAB_LINUX="true"
fi

if [[ ${CTX_INPUTS_M32} == "true" ]] ; then
        CAB_M32="true"
fi

if [[ ${CTX_INPUTS_MACOS} == "true" ]] ; then
        CAB_MACOS="true"
fi

if [[ ${CTX_INPUTS_MATRIXMODE} == "true" ]] ; then
        CAB_MATRIXMODE="true"
fi

if [[ ${CTX_INPUTS_VALGRIND} == "true" ]] ; then
        CAB_VALGRIND="true"
fi

if [[ ${CTX_INPUTS_WINDOWS} == "true" ]] ; then
        CAB_WINDOWS="true"
fi

CAB_MESONARGS=$(jq -cRs . < <(printf "%s" "${CTX_INPUTS_MESONARGS}"))
CAB_SOURCE=$(jq -cRs . < <(printf "%s" "${CTX_INPUTS_SOURCE}"))

CAB_MATRIX_M32=("${CAB_M32}")
if [[ ${CAB_MATRIXMODE} == "true" && ${CAB_M32} == "true" ]] ; then
        CAB_MATRIX_M32=("false" "true")
fi

#
# Linux Job-list Assembly
#

CAB_JSON="["
for CAB_J in "${CAB_MATRIX_M32[@]}" ; do
        for CAB_I in "${CAB_JOBS_LINUX[@]}" ; do
                CAB_JSON+="{"
                CAB_JSON+="\"job\":\"${CAB_I}\""
                CAB_JSON+=",\"m32\":${CAB_J}"
                CAB_JSON+=",\"mesonargs\":${CAB_MESONARGS}"
                CAB_JSON+=",\"source\":${CAB_SOURCE}"
                CAB_JSON+=",\"valgrind\":${CAB_VALGRIND}"
                CAB_JSON+="},"
        done
done
CAB_JSON=${CAB_JSON::-1} # drop last comma
CAB_JSON+="]"

if [[ ${CAB_LINUX} == "true" ]] ; then
        echo "jobs_linux=${CAB_JSON}" >>$GITHUB_OUTPUT
else
        echo "jobs_linux=[]" >>$GITHUB_OUTPUT
fi

#
# MacOS Job-list Assembly
#

CAB_JSON="["
for CAB_J in "${CAB_MATRIX_M32[@]}" ; do
        for CAB_I in "${CAB_JOBS_MACOS[@]}" ; do
                CAB_JSON+="{"
                CAB_JSON+="\"job\":\"${CAB_I}\""
                CAB_JSON+=",\"m32\":${CAB_J}"
                CAB_JSON+=",\"mesonargs\":${CAB_MESONARGS}"
                CAB_JSON+=",\"source\":${CAB_SOURCE}"
                CAB_JSON+=",\"valgrind\":${CAB_VALGRIND}"
                CAB_JSON+="},"
        done
done
CAB_JSON=${CAB_JSON::-1} # drop last comma
CAB_JSON+="]"

if [[ ${CAB_MACOS} == "true" ]] ; then
        echo "jobs_macos=${CAB_JSON}" >>$GITHUB_OUTPUT
else
        echo "jobs_macos=[]" >>$GITHUB_OUTPUT
fi

#
# Windows Job-list Assembly
#

CAB_JSON="["
for CAB_J in "${CAB_MATRIX_M32[@]}" ; do
        for CAB_I in "${CAB_JOBS_WINDOWS[@]}" ; do
                CAB_JSON+="{"
                CAB_JSON+="\"job\":\"${CAB_I}\""
                CAB_JSON+=",\"m32\":${CAB_J}"
                CAB_JSON+=",\"mesonargs\":${CAB_MESONARGS}"
                CAB_JSON+=",\"source\":${CAB_SOURCE}"
                CAB_JSON+=",\"valgrind\":${CAB_VALGRIND}"
                CAB_JSON+="},"
        done
done
CAB_JSON=${CAB_JSON::-1} # drop last comma
CAB_JSON+="]"

if [[ ${CAB_WINDOWS} == "true" ]] ; then
        echo "jobs_windows=${CAB_JSON}" >>$GITHUB_OUTPUT
else
        echo "jobs_windows=[]" >>$GITHUB_OUTPUT
fi
