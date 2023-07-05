#
# ci-c-util - C-Util CI Images
#
# This image provides the OS environment for the C-Util continuous integration
# on GitHub Actions. It is based on Fedora and includes all the required
# packages and utilities.
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
#   * CAB_DNF_PACKAGES_ALT=""
#       Like `CAB_DNF_PACKAGES` but installed in a second step.
#
#   * CAB_DNF_GROUPS=""
#       Specify the package groups to install into the container. Separate
#       groups by comma. By default, no group is pulled in.
#
#   * CAB_DNF_GROUPS_ALT=""
#       Like `CAB_DNF_GROUPS` but installed in a second step.
#
#   * CAB_PIP_PACKAGES=""
#       Specify the packages to install into the container via pip. Separate
#       packages by comma. By default, no package is pulled in.
#

ARG             CAB_FROM="docker.io/library/fedora:latest"
FROM            "${CAB_FROM}" AS target

#
# Import our build sources and prepare the target environment. When finished,
# we drop the build sources again, to keep the target image small.
#
# Note that we run a second `dnf.sh` run to allow installing alternative
# architecture packages. `dnf install` would otherwise merge requests for
# identical packages of different architectures (like `gcc` and `gcc.i686`).
#

WORKDIR         /cab
COPY            src src

ARG             CAB_DNF_PACKAGES=""
ARG             CAB_DNF_GROUPS=""
RUN             ./src/image-script/dnf.sh "${CAB_DNF_PACKAGES}" "${CAB_DNF_GROUPS}"

ARG             CAB_DNF_PACKAGES_ALT=""
ARG             CAB_DNF_GROUPS_ALT=""
RUN             ./src/image-script/dnf.sh "${CAB_DNF_PACKAGES_ALT}" "${CAB_DNF_GROUPS_ALT}"

ARG             CAB_PIP_PACKAGES=""
RUN             ./src/image-script/pip.sh "${CAB_PIP_PACKAGES}"

RUN             git config --system --add safe.directory '*'

RUN             rm -rf /cab/src

#
# Rebuild from scratch to drop all intermediate layers and keep the final image
# as small as possible. Then setup the entrypoint.
#

FROM            scratch
COPY            --from=target . .

WORKDIR         /cab/workdir
