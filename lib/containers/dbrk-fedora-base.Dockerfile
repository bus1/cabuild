#
# dbrk-fedora-base - DBus Broker Fedora Test Image
#
# A small fedora-based image to be used by dbus-broker for integration tests
# of new builds.
#
# Arguments:
#
#   * CAB_FROM="docker.io/library/fedora:latest"
#       This controls the host container used as base for the CI image.
#
#   * CAB_DNF_PACKAGES=""
#       Specify the packages to install into the container. Separate packages
#       by comma. By default, no package is pulled in.
#
#   * CAB_DNF_GROUPS=""
#       Specify the package groups to install into the container. Separate
#       groups by comma. By default, no group is pulled in.
#

ARG             CAB_FROM="docker.io/library/fedora:latest"
FROM            "${CAB_FROM}" AS target

#
# Import our build sources and prepare the target environment. When finished,
# we drop the build sources again, to keep the target image small.
#

WORKDIR         /cab
COPY            tools tools

ARG             CAB_DNF_PACKAGES=""
ARG             CAB_DNF_GROUPS=""
RUN             ./tools/dnf.sh "${CAB_DNF_PACKAGES}" "${CAB_DNF_GROUPS}"

RUN             useradd -ms /bin/bash -g root -G wheel test
RUN             chpasswd <<<"root:"
RUN             chpasswd <<<"test:"

RUN             rm -rf /cab/tools

#
# Rebuild from scratch to drop all intermediate layers and keep the final image
# as small as possible. Then setup the entrypoint.
#

FROM            scratch
COPY            --from=target . .

WORKDIR         /cab/workdir
CMD             ["/sbin/init"]
