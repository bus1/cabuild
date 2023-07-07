#
# plumbing - Bus1 Plumbing Image
#
# This image is used by the project maintenance of bus1 and provides all
# required utilities for automatic operations.
#
# Arguments:
#
#   * CAB_FROM="docker.io/library/ubuntu:latest"
#       This controls the host container used as base for the CI image.
#
#   * CAB_APT_PACKAGES=""
#       Specify the packages to install into the container. Separate packages
#       by comma. By default, no package is pulled in.
#

ARG             CAB_FROM="docker.io/library/ubuntu:latest"
FROM            "${CAB_FROM}" AS target

#
# Import our build sources and prepare the target environment. When finished,
# we drop the build sources again, to keep the target image small.
#

WORKDIR         /cab
COPY            tools tools

ARG             CAB_APT_PACKAGES=""
RUN             ./tools/apt.sh "${CAB_APT_PACKAGES}"

RUN             git config --system --add safe.directory '*'

RUN             rm -rf /cab/tools

#
# Rebuild from scratch to drop all intermediate layers and keep the final image
# as small as possible. Then setup the entrypoint.
#

FROM            scratch
COPY            --from=target . .

WORKDIR         /cab/workdir
