/*
 * CAB_UNIQUEID - Unique Identifier
 *
 * If provided by the caller, this ID must be unique across all builds. It
 * is used to tag immutable images and make them available to external
 * users.
 *
 * If not provided (i.e., an empty string), no such unique tags will be pushed.
 *
 * A common way to generate this ID is to use UUIDs, or to use the current date
 * (e.g., `20210101`).
 *
 * Note that we strongly recommend external users to access images by digest
 * rather than this tag. We mostly use the unique tag to guarantee the image
 * stays available in the registry and is not garbage-collected.
 */

variable "CAB_UNIQUEID" {
        /*
         * XXX: This should be `null` instead of an empty string, but current
         *      `xbuild+HCL` does not support that.
         */
        default = ""
}

/*
 * Mirroring
 *
 * The custom `mirror()` function takes an image name, an image tag, an
 * optional tag-suffix, as well as an optional unique suffix. It then produces
 * an array of tags for all the configured hosts.
 *
 * If the unique suffix is not empty, an additional tag with the unique suffix
 * is added for each host (replacing the specified suffix). In other words,
 * this function concatenates the configured host with the specified image,
 * tag, "-" and suffix or unique-suffix. The dash is skipped if the suffix is
 * empty.
 */

function "mirror" {
        params = [image, tag, suffix, unique]

        result = flatten([
                for host in [
                        "ghcr.io/bus1",
                ] : concat(
                        notequal(suffix, "") ?
                                ["${host}/${image}:${tag}-${suffix}"] :
                                ["${host}/${image}:${tag}"],
                        notequal(unique, "") ?
                                ["${host}/${image}:${tag}-${unique}"] :
                                [],
                )
        ])
}

/*
 * Target Groups
 *
 * The following section defines some custom target groups, which we use in
 * the CI system to rebuild a given set of images.
 *
 *     all-images
 *         Build all "product" images. That is, all images that are part of
 *         the project release and thus used by external entities.
 */

group "all-images" {
        targets = [
                "all-ci-c-util",
                "all-dbrk-fedora-base",
                "all-fedpkg",
        ]
}

/*
 * Virtual Base Targets
 *
 * This section defines virtual base targets, which are shared across the
 * different dependent targets.
 */

target "virtual-default" {
        context = "."
        labels = {
                "org.opencontainers.image.source" = "https://github.com/bus1/cabuild",
        }
}

target "virtual-platforms" {
        platforms = [
                "linux/amd64",
        ]
}

/*
 * ci-c-util - C-Util CI Images
 *
 * The following groups and targets build the CI images used by c-util. They
 * build on the official fedora images.
 */

group "all-ci-c-util" {
        targets = [
                "ci-c-util-latest",
        ]
}

target "virtual-ci-c-util" {
        args = {
                CAB_DNF_PACKAGES = join(",", [
                        "audit-libs-devel",
                        "bash",
                        "binutils-devel",
                        "bison-devel",
                        "cargo",
                        "clang",
                        "clang-devel",
                        "coreutils",
                        "curl",
                        "dbus-daemon",
                        "dbus-devel",
                        "dnf",
                        "expat-devel",
                        "file",
                        "findutils",
                        "flex-devel",
                        "gawk",
                        "gcc",
                        "gdb",
                        "gettext",
                        "git",
                        "glib2-devel",
                        "glibc-devel",
                        "grep",
                        "groff",
                        "gzip",
                        "htop",
                        "iproute",
                        "jq",
                        "libasan",
                        "libcap-ng-devel",
                        "libselinux-devel",
                        "libubsan",
                        "lld",
                        "make",
                        "meson",
                        "ninja-build",
                        "patch",
                        "pkgconf",
                        "procps-ng",
                        "pylint",
                        "python3-clang",
                        "python3-docutils",
                        "python3-devel",
                        "python3-mako",
                        "python3-pip",
                        "python3-pylint",
                        "python3-pytest",
                        "python3-sphinx",
                        "python3-sphinx_rtd_theme",
                        "qemu-img",
                        "qemu-system-x86",
                        "rpm",
                        "rpm-build",
                        "rpmdevtools",
                        "rust",
                        "sed",
                        "strace",
                        "sudo",
                        "systemd",
                        "systemd-devel",
                        "tar",
                        "texinfo",
                        "util-linux",
                        "which",
                        "valgrind",
                        "vim",
                ]),
                CAB_DNF_PACKAGES_ALT = join(",", [
                        "audit-libs-devel.i686",
                        "dbus-devel.i686",
                        "expat-devel.i686",
                        "glibc-devel.i686",
                        "libcap-ng-devel.i686",
                        "libselinux-devel.i686",
                        "systemd-devel.i686",
                        "valgrind.i686",
                ]),
                CAB_DNF_GROUPS = join(",", [
                        "development-tools",
                ]),
                CAB_PIP_PACKAGES = join(",", [
                        "c-apidocs",
                        "hawkmoth",
                ]),
        }
        dockerfile = "src/image/ci-c-util.Dockerfile"
        inherits = [
                "virtual-default",
                "virtual-platforms",
        ]
}

target "ci-c-util-latest" {
        args = {
                CAB_FROM = "docker.io/library/fedora:latest",
        }
        inherits = [
                "virtual-ci-c-util",
        ]
        tags = concat(
                mirror("ci-c-util", "latest", "", CAB_UNIQUEID),
        )
}

/*
 * dbrk-fedora-base - DBus Broker Fedora Test Images
 *
 * The following groups and targets build test images used by dbus-broker. They
 * build on the official fedora images.
 */

group "all-dbrk-fedora-base" {
        targets = [
                "dbrk-fedora-base-latest",
        ]
}

target "virtual-dbrk-fedora-base" {
        args = {
                CAB_DNF_PACKAGES = join(",", [
                        "audit-libs-devel",
                        "binutils-devel",
                        "cargo",
                        "clang",
                        "coreutils",
                        "dbus-daemon",
                        "dbus-devel",
                        "expat-devel",
                        "gcc",
                        "gdb",
                        "git",
                        "glib2-devel",
                        "glibc-devel",
                        "htop",
                        "jq",
                        "libcap-ng-devel",
                        "libselinux-devel",
                        "lld",
                        "make",
                        "meson",
                        "ninja-build",
                        "patch",
                        "pkgconf",
                        "procps-ng",
                        "python3-docutils",
                        "rust",
                        "strace",
                        "sudo",
                        "systemd",
                        "systemd-devel",
                        "util-linux",
                        "valgrind",
                        "vim",
                ]),
                CAB_DNF_GROUPS = join(",", [
                        "development-tools",
                ]),
        }
        dockerfile = "src/image/dbrk-fedora-base.Dockerfile"
        inherits = [
                "virtual-default",
                "virtual-platforms",
        ]
}

target "dbrk-fedora-base-latest" {
        args = {
                CAB_FROM = "docker.io/library/fedora:latest",
        }
        inherits = [
                "virtual-dbrk-fedora-base",
        ]
        tags = concat(
                mirror("dbrk-fedora-base", "latest", "", CAB_UNIQUEID),
        )
}

/*
 * fedpkg - Fedora Package Management Images
 *
 * The fedpkg images build on Fedora with the `fedpkg` tools included, and are
 * tailored towards releasing packages into Fedora via a container.
 */

group "all-fedpkg" {
        targets = [
                "fedpkg-latest",
        ]
}

target "virtual-fedpkg" {
        args = {
                CAB_DNF_PACKAGES = join(",", [
                        "audit-libs-devel",
                        "bash",
                        "binutils-devel",
                        "cargo",
                        "clang",
                        "coreutils",
                        "curl",
                        "dnf",
                        "fedpkg",
                        "file",
                        "findutils",
                        "gawk",
                        "gcc",
                        "gdb",
                        "gettext",
                        "git",
                        "glibc-devel",
                        "grep",
                        "groff",
                        "gzip",
                        "htop",
                        "iproute",
                        "jq",
                        "krb5-workstation",
                        "lld",
                        "make",
                        "meson",
                        "ninja-build",
                        "patch",
                        "pkgconf",
                        "procps-ng",
                        "rpm",
                        "rpm-build",
                        "rpmdevtools",
                        "rust",
                        "sed",
                        "strace",
                        "sudo",
                        "systemd",
                        "systemd-devel",
                        "tar",
                        "texinfo",
                        "util-linux",
                        "which",
                        "valgrind",
                        "vim",
                ]),
                CAB_DNF_GROUPS = join(",", [
                        "development-tools",
                ]),
        }
        dockerfile = "src/image/fedpkg.Dockerfile"
        inherits = [
                "virtual-default",
                "virtual-platforms",
        ]
}

target "fedpkg-latest" {
        args = {
                CAB_FROM = "docker.io/library/fedora:latest",
        }
        inherits = [
                "virtual-fedpkg",
        ]
        tags = concat(
                mirror("fedpkg", "latest", "", CAB_UNIQUEID),
        )
}
