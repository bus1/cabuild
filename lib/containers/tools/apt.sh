#!/bin/bash

#
# This script is a apt package install helper for container images. It takes
# packages as argument and then installs them via `apt`.
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
if (( $# > 2 )) ; then
        echo >&2 "ERROR: invalid number of arguments"
        exit 1
fi

#
# Configure the environment:
#  * Set `DEBIAN_FRONTEND` to `noninteractive` to prevent individual packages
#    from interacting with the user.
#

export DEBIAN_FRONTEND="noninteractive"

#
# Clean all caches so we force a metadata refresh. Then make sure to update
# the system to avoid unsynchronized installs. Note that we force a metadata
# refresh so all our installs share the same metadata. This gets as close to
# deterministic APT behavior as possible, without crazy workarounds. If
# immutable APT repositories ever become available, we should switch to it.
#

apt-get clean
apt-get update
apt-get upgrade -y

#
# Install the specified packages.
#

if (( ${#CAB_PACKAGES[@]} )) ; then
        apt-get install -y \
                --no-install-recommends \
                -- \
                        "${CAB_PACKAGES[@]}"
fi

#
# As last step clean all the metadata again. It will at some point be outdated
# and refreshed at a random time. Hence, make sure to clear it so we avoid
# accidentally using it later on. We want all installs to happen in this script
# so we can rely on the content later on.
#

apt-get clean
rm -rf /var/lib/apt/lists/*
