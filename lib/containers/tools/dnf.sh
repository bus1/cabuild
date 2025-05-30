#!/bin/bash

#
# This script is a DNF package and comp-group install helper for container
# images. It takes packages and comp-groups as arguments and then installs
# them via `dnf`.
#

set -eox pipefail

CAB_IFS=$IFS

#
# Parse command-line arguments into local variables. We accept:
#   @1: Comma-separated list of packages to install.
#   @2: Comma-separated list of comp-groups to install.
#

if (( $# > 0 )) ; then
        IFS=',' read -r -a CAB_PACKAGES <<< "$1"
        IFS=$CAB_IFS
fi
if (( $# > 1 )) ; then
        IFS=',' read -r -a CAB_GROUPS <<< "$2"
        IFS=$CAB_IFS
fi
if (( $# > 2 )) ; then
        echo >&2 "ERROR: invalid number of arguments"
        exit 1
fi

#
# Clean all caches so we force a metadata refresh. Then make sure to update
# the system to avoid unsynchronized installs. Note that we force a metadata
# refresh so all our installs share the same metadata. This gets as close to
# deterministic RPM behavior as possible, without crazy workarounds. If
# immutable RPM repositories ever become available, we should switch to it.
#

dnf clean all
dnf -y upgrade

#
# Install the specified packages and groups. We install the groups as second
# step to keep the number of duplicate installs low.
#

if (( ${#CAB_PACKAGES[@]} )) ; then
        dnf -y \
                --nodocs \
                --setopt=fastestmirror=True \
                --setopt=install_weak_deps=False \
                install \
                        "${CAB_PACKAGES[@]}"
fi

if (( ${#CAB_GROUPS[@]} )) ; then
        dnf -y \
                --nodocs \
                --setopt=fastestmirror=True \
                --setopt=install_weak_deps=False \
                group install \
                        "${CAB_GROUPS[@]}"
fi

#
# As last step clean all the metadata again. It will at some point be outdated
# and refreshed at a random time. Hence, make sure to clear it so we avoid
# accidentally using it later on. We want all installs to happen in this script
# so we can rely on the content later on.
#

dnf clean all
