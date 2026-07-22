#!/usr/bin/env bash
# build.sh - host-side entry point for building portable (manylinux-model)
# libOpenCvSharpExtern.so native libraries for Linux.
#
#   Usage:   ./build.sh <x64|arm64|riscv64|all>
#
# Everything runs inside a container (podman preferred, docker supported);
# nothing is installed on the host by this script. See README.txt for host
# requirements (container engine; qemu-user-static binfmt for non-native
# architectures), what gets downloaded when this runs, disk/time expectations,
# and how to adopt the built artifacts into native_libraries/.
#
# Environment overrides:
#   CONTAINER_ENGINE=podman|docker   force a specific engine (default: auto)
#   IMAGE_OVERRIDE=<image>           use a different container image
#   JOBS=<n>                         parallel build jobs (default: container nproc;
#                                    lower this if the OpenCV build runs out of RAM)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=pins.env
source "${SCRIPT_DIR}/pins.env"

usage() {
    echo "Usage: $0 <x64|arm64|riscv64|all>" >&2
    exit 2
}

[[ $# -eq 1 ]] || usage
ARCH_ARG="$1"

resolve_engine() {
    if [[ -n "${CONTAINER_ENGINE:-}" ]]; then
        command -v "${CONTAINER_ENGINE}" >/dev/null || {
            echo "ERROR: CONTAINER_ENGINE=${CONTAINER_ENGINE} is not on PATH." >&2; exit 1; }
        echo "${CONTAINER_ENGINE}"
        return
    fi
    if command -v podman >/dev/null; then echo podman; return; fi
    if command -v docker >/dev/null; then echo docker; return; fi
    echo "ERROR: neither podman nor docker found. Install one (see README.txt) and re-run." >&2
    exit 1
}

# Map our arch name -> (container platform, image var, RID, uname -m value)
arch_platform() { case "$1" in
    x64)     echo "linux/amd64"   ;;
    arm64)   echo "linux/arm64"   ;;
    riscv64) echo "linux/riscv64" ;;
esac; }
arch_image() { case "$1" in
    x64)     echo "${IMAGE_X64}"     ;;
    arm64)   echo "${IMAGE_ARM64}"   ;;
    riscv64) echo "${IMAGE_RISCV64}" ;;
esac; }
arch_rid() { case "$1" in
    x64)     echo "linux-x64"     ;;
    arm64)   echo "linux-arm64"   ;;
    riscv64) echo "linux-riscv64" ;;
esac; }
arch_machine() { case "$1" in
    x64)     echo "x86_64"  ;;
    arm64)   echo "aarch64" ;;
    riscv64) echo "riscv64" ;;
esac; }

build_one() {
    local arch="$1"
    local platform image rid
    platform="$(arch_platform "${arch}")"
    image="${IMAGE_OVERRIDE:-$(arch_image "${arch}")}"
    rid="$(arch_rid "${arch}")"

    local host_machine
    host_machine="$(uname -m)"
    if [[ "${host_machine}" != "$(arch_machine "${arch}")" ]]; then
        echo "NOTE: building ${arch} on a ${host_machine} host - this runs under qemu"
        echo "      emulation (qemu-user-static + binfmt must be set up; see README.txt)"
        echo "      and is MUCH slower than a native build. OpenCV under emulation can"
        echo "      take a day or more; prefer a native host for ${arch} when possible."
    fi

    local cache_dir="${SCRIPT_DIR}/cache/${rid}"
    local out_dir="${SCRIPT_DIR}/output"
    mkdir -p "${cache_dir}" "${out_dir}"

    echo "=============================================================="
    echo "Building libOpenCvSharpExtern.so for ${rid}"
    echo "  image:  ${image}  (platform ${platform})"
    echo "  cache:  ${cache_dir}"
    echo "  output: ${out_dir}/${rid}/"
    echo "=============================================================="

    "${ENGINE}" run --rm \
        --platform "${platform}" \
        -v "${REPO_ROOT}:/repo:ro" \
        -v "${cache_dir}:/cache" \
        -v "${out_dir}:/out" \
        -e "BUILD_ARCH=${arch}" \
        -e "BUILD_RID=${rid}" \
        -e "JOBS=${JOBS:-}" \
        "${image}" \
        bash /repo/tools/build_native_libraries/container_build.sh
}

ENGINE="$(resolve_engine)"
echo "Using container engine: ${ENGINE}"

case "${ARCH_ARG}" in
    x64|arm64|riscv64)
        build_one "${ARCH_ARG}"
        ;;
    all)
        for a in x64 arm64 riscv64; do
            build_one "${a}"
        done
        ;;
    *)
        usage
        ;;
esac

echo "Done. Artifacts are under: ${SCRIPT_DIR}/output/"
