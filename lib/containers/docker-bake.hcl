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
                "all-dbrk-ci-fedora",
                "all-dbrk-ci-ubuntu",
                "all-dbrk-fedora-base",
                "all-fedpkg",
                "all-plumbing",
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
        dockerfile = "ci-c-util.Dockerfile"
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
 * dbrk-ci-fedora - DBus Broker Fedora CI Images
 *
 * The following groups and targets build the Fedora CI images used by
 * dbus-broker. They build on the official fedora images.
 */

group "all-dbrk-ci-fedora" {
        targets = [
                "dbrk-ci-fedora-latest",
        ]
}

target "virtual-dbrk-ci-fedora" {
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
        }
        dockerfile = "dbrk-ci-fedora.Dockerfile"
        inherits = [
                "virtual-default",
                "virtual-platforms",
        ]
}

target "dbrk-ci-fedora-latest" {
        args = {
                CAB_FROM = "docker.io/library/fedora:latest",
        }
        inherits = [
                "virtual-dbrk-ci-fedora",
        ]
        tags = concat(
                mirror("dbrk-ci-fedora", "latest", "", CAB_UNIQUEID),
        )
}

/*
 * dbrk-ci-ubuntu - DBus Broker Ubuntu CI Images
 *
 * The following groups and targets build the Ubuntu CI images used by
 * dbus-broker. They build on the official Ubuntu images.
 */

group "all-dbrk-ci-ubuntu" {
        targets = [
                "dbrk-ci-ubuntu-latest",
        ]
}

target "virtual-dbrk-ci-ubuntu" {
        args = {
                CAB_APT_PACKAGES = join(",", [
                        "apparmor",
                        "bash",
                        "binutils-dev",
                        "build-essential",
                        "cargo",
                        "clang",
                        "coreutils",
                        "curl",
                        "dbus-daemon",
                        "debianutils",
                        "file",
                        "findutils",
                        "flex",
                        "gawk",
                        "gcc",
                        "gdb",
                        "gettext",
                        "git",
                        "grep",
                        "groff",
                        "gzip",
                        "htop",
                        "iproute2",
                        "jq",
                        "libapparmor-dev",
                        "libasan8",
                        "libaudit-dev",
                        "libbison-dev",
                        "libc-dev",
                        "libcap-ng-dev",
                        "libclang-dev",
                        "libdbus-1-dev",
                        "libexpat-dev",
                        "libglib2.0-dev",
                        "libselinux-dev",
                        "libsystemd-dev",
                        "libubsan1",
                        "lld",
                        "make",
                        "meson",
                        "ninja-build",
                        "patch",
                        "pkgconf",
                        "procps",
                        "pylint",
                        "python3-clang",
                        "python3-docutils",
                        "python3-dev",
                        "python3-mako",
                        "python3-pip",
                        "python3-pytest",
                        "qemu-system-x86",
                        "qemu-utils",
                        "rust-all",
                        "sed",
                        "strace",
                        "sudo",
                        "systemd",
                        "tar",
                        "texinfo",
                        "util-linux",
                        "valgrind",
                        "vim",
                ]),
        }
        dockerfile = "dbrk-ci-ubuntu.Dockerfile"
        inherits = [
                "virtual-default",
                "virtual-platforms",
        ]
}

target "dbrk-ci-ubuntu-latest" {
        args = {
                CAB_FROM = "docker.io/library/ubuntu:latest",
        }
        inherits = [
                "virtual-dbrk-ci-ubuntu",
        ]
        tags = concat(
                mirror("dbrk-ci-ubuntu", "latest", "", CAB_UNIQUEID),
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
        dockerfile = "dbrk-fedora-base.Dockerfile"
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
        dockerfile = "fedpkg.Dockerfile"
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

/*
 * plumbing - Bus1 Plumbing Image
 *
 * This image is based on Ubuntu and pulls in all required tools used
 * by project maintenance.
 */

group "all-plumbing" {
        targets = [
                "plumbing-latest",
        ]
}

target "virtual-plumbing" {
        args = {
                CAB_APT_PACKAGES = join(",", [
                        "bash",
                        "binutils-dev",
                        "build-essential",
                        "coreutils",
                        "curl",
                        "debianutils",
                        "file",
                        "findutils",
                        "gawk",
                        "gettext",
                        "git",
                        "grep",
                        "gzip",
                        "htop",
                        "iproute2",
                        "jq",
                        "make",
                        "procps",
                        "rclone",
                        "sed",
                        "sudo",
                        "systemd",
                        "tar",
                        "texinfo",
                        "util-linux",
                        "vim",
                ]),
        }
        dockerfile = "plumbing.Dockerfile"
        inherits = [
                "virtual-default",
                "virtual-platforms",
        ]
}

target "plumbing-latest" {
        args = {
                CAB_FROM = "docker.io/library/ubuntu:latest",
        }
        inherits = [
                "virtual-plumbing",
        ]
        tags = concat(
                mirror("plumbing", "latest", "", CAB_UNIQUEID),
        )
}
