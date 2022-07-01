#!/bin/bash

#
# This script is a PIP package install helper for container images. It takes
# packages as arguments and then installs them via `pip`.
#

set -eox pipefail

CAB_IFS=$IFS

#
# Parse command-line arguments into local variables. We accept:
#   @1: Comma-separated list of packages to install.
#

if (( $# > 0 )) ; then
        IFS=',' read -r -a CAB_PACKAGES <<< "$1"
        IFS=$CAB_IFS
fi
if (( $# > 1 )) ; then
        echo >&2 "ERROR: invalid number of arguments"
        exit 1
fi

#
# Clean all caches so we force a metadata refresh.
#

pip cache purge

#
# Install the specified packages and groups. We install the groups as second
# step to keep the number of duplicate installs low.
#

if (( ${#CAB_PACKAGES[@]} )) ; then
        pip \
                install \
                -- \
                        "${CAB_PACKAGES[@]}"
fi

#
# As last step clean all the metadata again. It will at some point be outdated
# and refreshed at a random time. Hence, make sure to clear it so we avoid
# accidentally using it later on. We want all installs to happen in this script
# so we can rely on the content later on.
#

pip cache purge
