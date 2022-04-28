#!/bin/bash

#
# Runner for C-Util CI Jobs
#
# This script runs a single continuous integration job of the C-Util CI suite.
# A selection of jobs is pre-defined in this script, but you can always run
# your own.
#

set -e

#
# Configuration
#

CAB_COMMAND=${CAB_COMMAND:-""}
CAB_JOB="none"
CAB_M32="false"
CAB_MESONARGS=""
CAB_NL=$'\n'
CAB_SOURCE="."
CAB_SOURCE_RAW="."
CAB_VALGRIND="false"

#
# Generic Helpers
#

failexit() { printf "==> ERROR: $1\n" "${@:2}"; exit 1; } >&2

#
# Argument Parsers
#

CAB_JOB=$(jq -r .job < <(printf "%s" "${CTX_MATRIX_JOB}"))
CAB_M32=$(jq -r .m32 < <(printf "%s" "${CTX_MATRIX_JOB}"))
CAB_MESONARGS=$(jq -r .mesonargs < <(printf "%s" "${CTX_MATRIX_JOB}"))
CAB_SOURCE_RAW=$(jq -r .source < <(printf "%s" "${CTX_MATRIX_JOB}"))
CAB_VALGRIND=$(jq -r .valgrind < <(printf "%s" "${CTX_MATRIX_JOB}"))

CAB_SOURCE="$(readlink -f "./source/${CAB_SOURCE_RAW}/")"
if [[ ! -d "${CAB_SOURCE}" ]] ; then
        failexit '%s: non-existant source directory -- '\''%s'\' "${0##*/}" "${CAB_SOURCE_RAW}"
fi

#
# Job Definition
#
# We support many built-in configurations to run the C-Util CI. These are all
# customized to the C-Util requirements and coding-style. Feel free to add
# further jobs here to suit your needs.
#
# Note that you can easily allow the caller to use `none` as job and then
# make sure all environment variables are inherited, thus giving full control
# to the caller.
#

CAB_LIB_ENV=()
CAB_LIB_CFLAGS=()
CAB_LIB_CFLAGS_CLANG=()
CAB_LIB_CFLAGS_GCC=()

CAB_LIB_CFLAGS+=("-g")
CAB_LIB_CFLAGS+=("-Werror")

if [[ ${CAB_M32} == "true" ]] ; then
        CAB_LIB_CFLAGS+=("-m32")
        CAB_LIB_ENV+=("PKG_CONFIG_LIBDIR='/usr/lib/pkgconfig:/usr/share/pkgconfig'")
fi

CAB_JOB_LLVM=(
        "CC=clang"
        "CFLAGS='${CAB_LIB_CFLAGS[*]} ${CAB_LIB_CFLAGS_CLANG[*]} -O2'"
        "${CAB_LIB_ENV[@]}"
)
CAB_JOB_GCC=(
        "CC=gcc"
        "CFLAGS='${CAB_LIB_CFLAGS[*]} ${CAB_LIB_CFLAGS_GCC[*]} -O2'"
        "${CAB_LIB_ENV[@]}"
)
CAB_JOB_GCC_DEBUG=(
        "CC=gcc"
        "CFLAGS='${CAB_LIB_CFLAGS[*]} ${CAB_LIB_CFLAGS_GCC[*]} -O0'"
        "${CAB_LIB_ENV[@]}"
)
CAB_JOB_GCC_OPTIMIZED=(
        "CC=gcc"
        "CFLAGS='${CAB_LIB_CFLAGS[*]} ${CAB_LIB_CFLAGS_GCC[*]} -O3'"
        "${CAB_LIB_ENV[@]}"
)
CAB_JOB_GCC_NDEBUG=(
        "CC=gcc"
        "CFLAGS='${CAB_LIB_CFLAGS[*]} ${CAB_LIB_CFLAGS_GCC[*]} -O2 -DNDEBUG'"
        "${CAB_LIB_ENV[@]}"
)

#
# Job Selection
#

CAB_CMD_SETUP="meson setup"
CAB_CMD_SETUP+=" --buildtype debugoptimized"
CAB_CMD_SETUP+=" --warnlevel 2"

if [[ ! -z "${CAB_MESONARGS}" ]] ; then
        CAB_CMD_SETUP+=" ${CAB_MESONARGS[@]}"
fi

CAB_CMD_BUILD="ninja -v"

CAB_CMD_TEST_BASIC="meson test --print-errorlogs"

CAB_CMD_DEFAULT="${CAB_CMD_SETUP} . ${CAB_SOURCE}"
CAB_CMD_DEFAULT+="${CAB_NL}${CAB_NL}"
CAB_CMD_DEFAULT+="${CAB_CMD_BUILD}"
CAB_CMD_DEFAULT+="${CAB_NL}${CAB_NL}"
CAB_CMD_DEFAULT+="${CAB_CMD_TEST_BASIC}"

if [[ ${CAB_VALGRIND} == "true" ]] ; then
        CAB_CMD_DEFAULT+="${CAB_NL}${CAB_NL}"
        CAB_CMD_DEFAULT+="CAB_VALGRIND=1"
        CAB_CMD_DEFAULT+=" meson test"
        CAB_CMD_DEFAULT+=" --print-errorlogs"
        CAB_CMD_DEFAULT+=" --timeout-multiplier=16"
        CAB_CMD_DEFAULT+=" --wrapper="

        CAB_CMD_DEFAULT+="\""
        CAB_CMD_DEFAULT+="valgrind"
        CAB_CMD_DEFAULT+=" --gen-suppressions=all"
        CAB_CMD_DEFAULT+=" --trace-children=yes"
        CAB_CMD_DEFAULT+=" --leak-check=full"
        CAB_CMD_DEFAULT+=" --error-exitcode=1"
        CAB_CMD_DEFAULT+="\""
fi

case "${CAB_JOB}" in
c-util-llvm)
        CAB_COMMAND="export ${CAB_JOB_LLVM[*]}"
        CAB_COMMAND+="${CAB_NL}${CAB_NL}"
        CAB_COMMAND+="${CAB_CMD_DEFAULT}"
        ;;
c-util-gcc)
        CAB_COMMAND="export ${CAB_JOB_GCC[*]}"
        CAB_COMMAND+="${CAB_NL}${CAB_NL}"
        CAB_COMMAND+="${CAB_CMD_DEFAULT}"
        ;;
c-util-gcc-debug)
        CAB_COMMAND="export ${CAB_JOB_GCC_DEBUG[*]}"
        CAB_COMMAND+="${CAB_NL}${CAB_NL}"
        CAB_COMMAND+="${CAB_CMD_DEFAULT}"
        ;;
c-util-gcc-optimized)
        CAB_COMMAND="export ${CAB_JOB_GCC_OPTIMIZED[*]}"
        CAB_COMMAND+="${CAB_NL}${CAB_NL}"
        CAB_COMMAND+="${CAB_CMD_DEFAULT}"
        ;;
c-util-gcc-ndebug)
        CAB_COMMAND="export ${CAB_JOB_GCC_NDEBUG[*]}"
        CAB_COMMAND+="${CAB_NL}${CAB_NL}"
        CAB_COMMAND+="${CAB_CMD_DEFAULT}"
        ;;
none)
        # Nothing to do, full environment was inherited from the caller.
        ;;
*)
        failexit '%s: invalid job -- '\''%s'\' "${0##*/}" "${CAB_JOB}"
        ;;
esac

#
# Export Configuration
#

if [[ ${CAB_M32} == "true" ]] ; then
        export CAB_M32
fi

#
# Job Execution
#

(
        mkdir "build"
        cd "build"

        echo "-- DUMP RUN ----------------------------------------------------"
        echo
        echo "$CAB_COMMAND"
        echo
        echo "-- BEGIN RUN ---------------------------------------------------"
        echo
        eval "$CAB_COMMAND"
        echo
        echo "-- END RUN -----------------------------------------------------"
)
