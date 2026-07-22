#!/usr/bin/env bash
# container_build.sh - runs INSIDE the build container (launched by build.sh).
# Mirrors the upstream manylinux x64 pipeline (native_src/ci-workflows/manylinux.yml,
# "build_full" job) for any Linux architecture:
#
#   1. system tools            (dnf on manylinux_2_28/AlmaLinux, apt on Ubuntu-based images)
#   2. vcpkg                   image libs + Tesseract + Leptonica, static, pinned baseline
#   3. static FFmpeg           same version/flags as native_src/docker/manylinux/build_static_deps.sh
#   4. OpenCV + contrib        static, pinned commits, options from native_src/cmake/
#   5. OpenCvSharpExtern       from the vendored native_src/ wrapper source
#   6. verification            required-features log check, forbidden-soname check,
#                              C smoke test, glibc-ceiling report
#
# Mounts (provided by build.sh): /repo (read-only repo root), /cache (persistent
# per-RID build state - safe to delete to force a full rebuild), /out (artifacts).
# Env: BUILD_ARCH (x64|arm64|riscv64), BUILD_RID (linux-<arch>), JOBS (optional).
#
# Every stage is skipped when its output already exists in /cache, so an
# interrupted build resumes where it left off.

set -euxo pipefail

source /repo/tools/build_native_libraries/pins.env

ARCH="${BUILD_ARCH:?BUILD_ARCH not set}"
RID="${BUILD_RID:?BUILD_RID not set}"
TRIPLET="${ARCH}-linux-static"
JOBS="${JOBS:-$(nproc)}"

SRC=/cache/src
VCPKG_ROOT=/cache/vcpkg
VCPKG_INSTALLED=/cache/vcpkg_installed
FFMPEG_PREFIX=/cache/ffmpeg
OPENCV_PREFIX=/cache/opencv_artifacts
TRIPLETS_DIR=/cache/triplets
MANIFEST_DIR=/cache/manifest
EXTERN_SRC=/cache/extern-src
EXTERN_BUILD=/cache/extern-build

# ---------------------------------------------------------------------------
# 1. System tools
# ---------------------------------------------------------------------------
if command -v dnf >/dev/null; then
    # manylinux_2_28 images (AlmaLinux 8). Same package set as the upstream
    # manylinux.yml "Install system tools" step; nasm/yasm are x86-only (FFmpeg
    # is built with --disable-asm, they are only configure-time conveniences).
    PKGS=(git zip unzip pkg-config ninja-build kernel-headers
          perl-IPC-Cmd perl-Time-Piece gtk3-devel curl xz)
    if [[ "$(uname -m)" == "x86_64" ]]; then PKGS+=(nasm yasm); fi
    dnf install -y "${PKGS[@]}"
elif command -v apt-get >/dev/null; then
    # Ubuntu-based images (the manylinux_2_39 riscv64 baseline, or an
    # IMAGE_OVERRIDE like riscv64/ubuntu:24.04).
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    PKGS=(build-essential g++ git zip unzip pkg-config ninja-build cmake
          curl ca-certificates xz-utils libgtk-3-dev linux-libc-dev)
    if [[ "$(uname -m)" == "x86_64" ]]; then PKGS+=(nasm yasm); fi
    apt-get install -y --no-install-recommends "${PKGS[@]}"
else
    echo "ERROR: neither dnf nor apt-get found in this image." >&2
    exit 1
fi
command -v cmake >/dev/null || { echo "ERROR: cmake not found in image." >&2; exit 1; }

# ---------------------------------------------------------------------------
# 2. vcpkg: image libs + Tesseract + Leptonica (static, release-only)
# ---------------------------------------------------------------------------
if [[ ! -x "${VCPKG_ROOT}/vcpkg" ]]; then
    rm -rf "${VCPKG_ROOT}"
    git clone --filter=blob:none "${VCPKG_REPO}" "${VCPKG_ROOT}"
    git -C "${VCPKG_ROOT}" checkout "${VCPKG_COMMIT}"
    "${VCPKG_ROOT}/bootstrap-vcpkg.sh" -disableMetrics
fi

# Overlay triplets: upstream's (x64) plus this repo's additions (arm64, riscv64).
mkdir -p "${TRIPLETS_DIR}" "${MANIFEST_DIR}"
cp /repo/native_src/cmake/triplets/*.cmake "${TRIPLETS_DIR}/"
cp /repo/tools/build_native_libraries/triplets/*.cmake "${TRIPLETS_DIR}/"
cp /repo/native_src/vcpkg.json "${MANIFEST_DIR}/"

if [[ ! -f "${VCPKG_INSTALLED}/.done-${TRIPLET}" ]]; then
    (cd "${MANIFEST_DIR}" && "${VCPKG_ROOT}/vcpkg" install \
        --triplet "${TRIPLET}" \
        --overlay-triplets="${TRIPLETS_DIR}" \
        --x-install-root="${VCPKG_INSTALLED}")
    touch "${VCPKG_INSTALLED}/.done-${TRIPLET}"
fi

# ---------------------------------------------------------------------------
# 3. Static FFmpeg (same version and configure flags as
#    native_src/docker/manylinux/build_static_deps.sh; LGPL v2.1+, static)
# ---------------------------------------------------------------------------
if [[ ! -f "${FFMPEG_PREFIX}/lib/pkgconfig/libavcodec.pc" ]]; then
    mkdir -p /tmp/ffmpeg-build "${FFMPEG_PREFIX}"
    cd /tmp/ffmpeg-build
    curl -fL --retry 5 --retry-delay 2 \
        "https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz" \
        -o ffmpeg.tar.xz
    tar xf ffmpeg.tar.xz
    cd "ffmpeg-${FFMPEG_VERSION}"
    ./configure \
        --prefix="${FFMPEG_PREFIX}" \
        --enable-static \
        --disable-shared \
        --enable-pic \
        --disable-asm \
        --disable-doc \
        --disable-programs \
        --disable-debug \
        --disable-network \
        --disable-avdevice \
        --disable-postproc \
        --enable-avcodec \
        --enable-avformat \
        --enable-avutil \
        --enable-swscale \
        --enable-swresample
    make -j"${JOBS}"
    make install
    cd /
    rm -rf /tmp/ffmpeg-build
fi

# ---------------------------------------------------------------------------
# 4. OpenCV + contrib (static, pinned to the exact revisions the shipped
#    upstream natives were built from)
# ---------------------------------------------------------------------------
mkdir -p "${SRC}"
clone_pinned() {
    local repo="$1" commit="$2" dir="$3"
    if [[ ! -d "${dir}/.git" ]]; then
        rm -rf "${dir}"
        git clone --filter=blob:none "${repo}" "${dir}"
    fi
    git -C "${dir}" fetch --all --quiet || true
    git -C "${dir}" checkout --quiet "${commit}"
}

if [[ ! -f "${OPENCV_PREFIX}/.done" ]]; then
    clone_pinned "${OPENCV_REPO}" "${OPENCV_COMMIT}" "${SRC}/opencv"
    clone_pinned "${OPENCV_CONTRIB_REPO}" "${OPENCV_CONTRIB_COMMIT}" "${SRC}/opencv_contrib"

    # Arch-specific workarounds:
    #   aarch64: disable the generic ASM language so OpenCV 5's vendored MLAS
    #   skips its ASM kernels (DNN falls back to built-in SGEMM). OpenCV 5.0.0's
    #   aarch64 MLAS FP16/GQA path calls MlasHGemmSupported() without defining
    #   it, breaking the extern link. Same workaround as the upstream
    #   linux-arm64.yml workflow; image codecs are unaffected (their SIMD is
    #   NEON intrinsics, not GAS).
    EXTRA_OPENCV_ARGS=()
    if [[ "$(uname -m)" == "aarch64" ]]; then
        EXTRA_OPENCV_ARGS+=(-D 'CMAKE_ASM_COMPILER=')
    fi

    rm -rf "${SRC}/opencv/build"
    cmake \
        -G Ninja \
        -C /repo/native_src/cmake/opencv_build_options.cmake \
        -S "${SRC}/opencv" \
        -B "${SRC}/opencv/build" \
        -D OPENCV_EXTRA_MODULES_PATH="${SRC}/opencv_contrib/modules" \
        -D CMAKE_INSTALL_PREFIX="${OPENCV_PREFIX}" \
        -D CMAKE_TOOLCHAIN_FILE="${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" \
        -D VCPKG_TARGET_TRIPLET="${TRIPLET}" \
        -D VCPKG_INSTALLED_DIR="${VCPKG_INSTALLED}" \
        -D CMAKE_PREFIX_PATH="${FFMPEG_PREFIX}" \
        -D BUILD_JPEG=OFF \
        -D BUILD_PNG=OFF \
        -D BUILD_TIFF=OFF \
        -D BUILD_WEBP=OFF \
        -D BUILD_ZLIB=ON \
        -D WITH_TBB=OFF \
        -D WITH_OPENEXR=OFF \
        -D WITH_JASPER=OFF \
        -D WITH_OPENGL=OFF \
        -D WITH_VA=OFF \
        -D WITH_VA_INTEL=OFF \
        "${EXTRA_OPENCV_ARGS[@]}" \
        2>&1 | tee /tmp/opencv-configure-full.log

    # Same required-feature verification as the upstream workflow: a silently
    # disabled codec/OCR feature must fail the build, not ship a crippled binary.
    fail=0
    for feature in Tesseract FFMPEG JPEG PNG TIFF WEBP; do
        val=$(grep -E "^--\s+${feature}:\s+" /tmp/opencv-configure-full.log | tail -1 \
              | sed -E "s/^.*${feature}:[[:space:]]+//")
        if [[ -n "$val" ]] && [[ "$val" != NO* ]]; then
            echo "OK: ${feature} = ${val}"
        else
            echo "MISSING or DISABLED: ${feature}"
            grep -iE "${feature}" /tmp/opencv-configure-full.log | tail -3 || true
            fail=1
        fi
    done
    [ "$fail" -eq 0 ]

    cmake --build "${SRC}/opencv/build" -j "${JOBS}"
    cmake --install "${SRC}/opencv/build"
    rm -rf "${SRC}/opencv/build"
    touch "${OPENCV_PREFIX}/.done"
fi

# ---------------------------------------------------------------------------
# 5. OpenCvSharpExtern from the vendored wrapper source
#    (native_src/CMakeLists-src.txt is upstream's src/CMakeLists.txt, renamed
#    so nothing treats native_src/ as a live build - stage it back here)
# ---------------------------------------------------------------------------
rm -rf "${EXTERN_SRC}" "${EXTERN_BUILD}"
mkdir -p "${EXTERN_SRC}"
cp /repo/native_src/CMakeLists-src.txt "${EXTERN_SRC}/CMakeLists.txt"
cp -r /repo/native_src/OpenCvSharpExtern "${EXTERN_SRC}/OpenCvSharpExtern"

OPENCV_CONFIG_DIR="$(dirname "$(find "${OPENCV_PREFIX}" -name OpenCVConfig.cmake | head -1)")"
[[ -n "${OPENCV_CONFIG_DIR}" ]] || { echo "ERROR: OpenCVConfig.cmake not found under ${OPENCV_PREFIX}" >&2; exit 1; }

cmake \
    -G Ninja \
    -S "${EXTERN_SRC}" \
    -B "${EXTERN_BUILD}" \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_TOOLCHAIN_FILE="${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" \
    -D VCPKG_TARGET_TRIPLET="${TRIPLET}" \
    -D VCPKG_INSTALLED_DIR="${VCPKG_INSTALLED}" \
    -D OpenCV_DIR="${OPENCV_CONFIG_DIR}" \
    -D CMAKE_PREFIX_PATH="${OPENCV_PREFIX};${FFMPEG_PREFIX};${VCPKG_INSTALLED}/${TRIPLET}" \
    -D ZLIB_LIBRARY="${VCPKG_INSTALLED}/${TRIPLET}/lib/libz.a" \
    -D ZLIB_INCLUDE_DIR="${VCPKG_INSTALLED}/${TRIPLET}/include" \
    -D CMAKE_SHARED_LINKER_FLAGS="-L${VCPKG_INSTALLED}/${TRIPLET}/lib"
cmake --build "${EXTERN_BUILD}" -j "${JOBS}"

SO="${EXTERN_BUILD}/OpenCvSharpExtern/libOpenCvSharpExtern.so"
[[ -f "${SO}" ]] || { echo "ERROR: build produced no ${SO}" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 6. Verification
# ---------------------------------------------------------------------------
echo "=== ldd ==="
ldd "${SO}" || true

# The entire point of this build model: codecs/FFmpeg/OCR must be INSIDE the
# library. Any of these sonames appearing as a dynamic dependency means the
# static linking failed and the binary would hit the exact per-distro breakage
# this tooling exists to eliminate.
echo "=== forbidden-soname check ==="
NEEDED="$(objdump -p "${SO}" | awk '/NEEDED/{print $2}')"
echo "${NEEDED}"
FORBIDDEN='^lib(avcodec|avformat|avutil|swscale|swresample|jpeg|png|tiff|webp|tesseract|lept|z)\.'
if echo "${NEEDED}" | grep -E "${FORBIDDEN}"; then
    echo "ERROR: the .so dynamically links libraries that must be static (above)." >&2
    exit 1
fi
echo "OK: no forbidden dynamic dependencies."

echo "=== smoke test ==="
cd /tmp
printf '#include <stdio.h>\nint core_Mat_sizeof(); int main(){ printf("sizeof(Mat) = %%d\\n", core_Mat_sizeof()); return 0; }\n' > test.c
gcc test.c -o test -L"$(dirname "${SO}")" -lOpenCvSharpExtern
LD_LIBRARY_PATH="$(dirname "${SO}")" ./test

echo "=== glibc ceiling (the minimum glibc a target system needs) ==="
GLIBC_MAX="$(objdump -T "${SO}" | grep -oE 'GLIBC_[0-9.]+' | sort -Vu | tail -1 || true)"
echo "Highest glibc symbol version referenced: ${GLIBC_MAX:-unknown}"

# ---------------------------------------------------------------------------
# Artifacts
# ---------------------------------------------------------------------------
mkdir -p "/out/${RID}"
cp "${SO}" "/out/${RID}/libOpenCvSharpExtern.so"
SHA256="$(sha256sum "/out/${RID}/libOpenCvSharpExtern.so" | awk '{print $1}')"
{
    echo "libOpenCvSharpExtern.so build info"
    echo "rid:                  ${RID}"
    echo "built:                $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo "sha256:               ${SHA256}"
    echo "glibc ceiling:        ${GLIBC_MAX:-unknown}"
    echo "opencv:               ${OPENCV_VERSION} @ ${OPENCV_COMMIT}"
    echo "opencv_contrib:       @ ${OPENCV_CONTRIB_COMMIT}"
    echo "ffmpeg (static):      ${FFMPEG_VERSION}"
    echo "vcpkg baseline:       ${VCPKG_COMMIT}"
    echo "vcpkg triplet:        ${TRIPLET}"
    echo "container image os:   $(source /etc/os-release && echo "${PRETTY_NAME}")"
    echo "dynamic dependencies:"
    echo "${NEEDED}" | sed 's/^/  /'
} > "/out/${RID}/build-info.txt"

echo "=============================================================="
echo "SUCCESS: /out/${RID}/libOpenCvSharpExtern.so (sha256 ${SHA256})"
echo "=============================================================="
