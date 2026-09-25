#!/usr/bin/env bash
# build_macos.sh - builds libOpenCvSharpExtern.dylib for macOS x64 (osx-x64)
# directly on an Intel Mac host (no container: macOS cannot run in one).
#
#   Usage:   ./build_macos.sh x64
#
# Mirrors the upstream macOS x64 pipeline (native_src/ci-workflows/macos.yml,
# "build_x64" job) step for step, with the pins from pins.env:
#
#   1. vcpkg                   image libs + Tesseract + Leptonica + FFmpeg + HDF5 +
#                              FreeType + HarfBuzz + Eigen, static (x64-osx-static)
#   2. OpenCV + contrib        static, pinned commits, options from native_src/cmake/
#   3. OpenCvSharpExtern       from the vendored native_src/ wrapper source
#   4. verification            required-features log check, dependency allowlist,
#                              no build-host paths in the OpenCV cache, dlopen smoke
#                              test, exported-symbol parity with the shipped binary
#
# WHY IT EXISTS: the upstream osx-x64 binary (5.0.0.20260704) was built on a
# GitHub macos-26-intel runner whose Homebrew had libavif installed, and OpenCV's
# imgcodecs auto-detected it. The shipped dylib therefore hard-links
# /usr/local/opt/libavif/lib/libavif.16.dylib and fails to load on every Intel
# Mac without that exact Homebrew package ("Library not loaded: ...libavif...").
# This build adds -D WITH_AVIF=OFF (the osx-arm64 binary has no AVIF either, so
# both macOS RIDs expose the same codec set) and gates on the dependency list,
# so no build-host library can leak in again.
#
# HOST REQUIREMENTS (installed by YOU, never by this script)
#   * Intel Mac, Xcode Command Line Tools (clang + macOS SDK)
#   * cmake, ninja, pkg-config, git, curl, xz, unzip on PATH (NASM is fetched
#     into cache/ by this script - pins.env NASM_* - never installed)
#   * disk: ~30 GB free under cache/;  time: roughly 3-5 h on a 6-core Intel Mac
#
# Environment overrides:
#   JOBS=<n>      parallel build jobs (default: hw.ncpu)
#
# Every stage is skipped when its output already exists under cache/osx-x64/,
# so an interrupted build resumes where it left off. Delete that folder to
# force a full rebuild.

set -euxo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=pins.env
source "${SCRIPT_DIR}/pins.env"

[[ $# -eq 1 && "$1" == "x64" ]] || { echo "Usage: $0 x64" >&2; exit 2; }
[[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "x86_64" ]] || {
    echo "ERROR: build osx-x64 on an Intel Mac (this host is $(uname -s) $(uname -m))." >&2; exit 1; }
for tool in cmake ninja pkg-config git curl xz unzip; do
    command -v "${tool}" >/dev/null || { echo "ERROR: '${tool}' not on PATH (see HOST REQUIREMENTS)." >&2; exit 1; }
done

RID=osx-x64
TRIPLET=x64-osx-static
JOBS="${JOBS:-$(sysctl -n hw.ncpu)}"
DEPLOYMENT_TARGET=11.0          # same as upstream macos.yml

CACHE="${SCRIPT_DIR}/cache/${RID}"
SRC="${CACHE}/src"
VCPKG_ROOT="${CACHE}/vcpkg"
VCPKG_INSTALLED="${CACHE}/vcpkg_installed"
OPENCV_PREFIX="${CACHE}/opencv_artifacts"
TRIPLETS_DIR="${CACHE}/triplets"
MANIFEST_DIR="${CACHE}/manifest"
EXTERN_SRC="${CACHE}/extern-src"
EXTERN_BUILD="${CACHE}/extern-build"
LOGS="${CACHE}/logs"
OUT="${SCRIPT_DIR}/output/${RID}"
mkdir -p "${CACHE}" "${SRC}" "${LOGS}" "${OUT}"

export MACOSX_DEPLOYMENT_TARGET="${DEPLOYMENT_TARGET}"
export VCPKG_MAX_CONCURRENCY="${JOBS}"

# pkg-config must only ever see the vcpkg-built static libraries. Homebrew's
# /usr/local/lib/pkgconfig is exactly how a build-host library leaks in.
export PKG_CONFIG_LIBDIR="${VCPKG_INSTALLED}/${TRIPLET}/lib/pkgconfig"
unset PKG_CONFIG_PATH

# NASM (x86 SIMD for FFmpeg / libjpeg-turbo), pinned and checked, on PATH for
# this build only.
NASM_DIR="${CACHE}/tools/nasm-${NASM_VERSION}"
if [[ ! -x "${NASM_DIR}/nasm" ]]; then
    mkdir -p "${CACHE}/tools"
    curl -fL --retry 5 --retry-delay 2 "${NASM_MACOS_URL}" -o "${CACHE}/tools/nasm.zip"
    echo "${NASM_MACOS_SHA256}  ${CACHE}/tools/nasm.zip" | shasum -a 256 -c -
    unzip -o -q "${CACHE}/tools/nasm.zip" -d "${CACHE}/tools"
    rm -f "${CACHE}/tools/nasm.zip"
fi
export PATH="${NASM_DIR}:${PATH}"
nasm -v

# ---------------------------------------------------------------------------
# 1. vcpkg (static, release-only; upstream triplet x64-osx-static)
# ---------------------------------------------------------------------------
if [[ ! -x "${VCPKG_ROOT}/vcpkg" ]]; then
    rm -rf "${VCPKG_ROOT}"
    git clone --filter=blob:none "${VCPKG_REPO}" "${VCPKG_ROOT}"
    git -C "${VCPKG_ROOT}" checkout "${VCPKG_COMMIT}"
    "${VCPKG_ROOT}/bootstrap-vcpkg.sh" -disableMetrics
fi

mkdir -p "${TRIPLETS_DIR}" "${MANIFEST_DIR}"
cp "${REPO_ROOT}"/native_src/cmake/triplets/*.cmake "${TRIPLETS_DIR}/"
cp "${REPO_ROOT}/native_src/vcpkg.json" "${MANIFEST_DIR}/"

# overlay-ports/: libaec fetched over git instead of GitLab's rate-limited
# archive endpoint (same pinned source; see overlay-ports/libaec/portfile.cmake).
if [[ ! -f "${VCPKG_INSTALLED}/.done-${TRIPLET}" ]]; then
    (cd "${MANIFEST_DIR}" && "${VCPKG_ROOT}/vcpkg" install \
        --triplet "${TRIPLET}" \
        --overlay-triplets="${TRIPLETS_DIR}" \
        --overlay-ports="${SCRIPT_DIR}/overlay-ports" \
        --x-install-root="${VCPKG_INSTALLED}") 2>&1 | tee "${LOGS}/vcpkg-install.log"
    touch "${VCPKG_INSTALLED}/.done-${TRIPLET}"
fi

# ---------------------------------------------------------------------------
# 2. OpenCV + contrib (static, pinned to the exact revisions the shipped
#    upstream natives were built from)
# ---------------------------------------------------------------------------
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

    # Upstream macos.yml configure line, plus:
    #   WITH_AVIF=OFF            the fix this script exists for (see header)
    #   PKG_CONFIG_EXECUTABLE    explicit, so FFmpeg detection uses the isolated
    #                            PKG_CONFIG_LIBDIR above
    # CMAKE_ASM_COMPILER="" is upstream's: it turns OpenCV 5's vendored MLAS off
    # (OpenCV 5.0.0 calls MlasHGemmSupported() without defining it).
    rm -rf "${SRC}/opencv/build"
    cmake \
        -G Ninja \
        -C "${REPO_ROOT}/native_src/cmake/opencv_build_options.cmake" \
        -S "${SRC}/opencv" \
        -B "${SRC}/opencv/build" \
        -D OPENCV_EXTRA_MODULES_PATH="${SRC}/opencv_contrib/modules" \
        -D CMAKE_INSTALL_PREFIX="${OPENCV_PREFIX}" \
        -D CMAKE_TOOLCHAIN_FILE="${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" \
        -D VCPKG_TARGET_TRIPLET="${TRIPLET}" \
        -D VCPKG_INSTALLED_DIR="${VCPKG_INSTALLED}" \
        -D CMAKE_OSX_ARCHITECTURES=x86_64 \
        -D CMAKE_OSX_DEPLOYMENT_TARGET="${DEPLOYMENT_TARGET}" \
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
        -D WITH_AVIF=OFF \
        -D OPENCV_FFMPEG_SKIP_BUILD_CHECK=ON \
        -D PKG_CONFIG_EXECUTABLE="$(command -v pkg-config)" \
        -D CMAKE_ASM_COMPILER="" \
        2>&1 | tee "${LOGS}/opencv-configure.log"

    # Same required-feature verification as the upstream workflow, plus AVIF
    # must be OFF.
    fail=0
    for feature in JPEG PNG TIFF WEBP FFMPEG Tesseract; do
        val=$(grep -E "^--\s+${feature}:\s+" "${LOGS}/opencv-configure.log" | tail -1 \
              | sed -E "s/^.*${feature}:[[:space:]]+//")
        if [[ -n "$val" ]] && [[ "$val" != NO* ]]; then
            echo "OK: ${feature} = ${val}"
        else
            echo "MISSING or DISABLED: ${feature}"
            fail=1
        fi
    done
    if grep -E "^--\s+AVIF:\s+YES" "${LOGS}/opencv-configure.log"; then
        echo "ERROR: AVIF was enabled." >&2; fail=1
    fi
    # No library or header from a build-host package manager may be referenced.
    if grep -E "=(/usr/local|/opt/homebrew)/(lib|include|opt|Cellar)" "${SRC}/opencv/build/CMakeCache.txt"; then
        echo "ERROR: the OpenCV configure picked up build-host (Homebrew) paths (above)." >&2; fail=1
    fi
    [ "$fail" -eq 0 ]

    cmake --build "${SRC}/opencv/build" -j "${JOBS}" 2>&1 | tee "${LOGS}/opencv-build.log" | grep -E "^\[[0-9]+/[0-9]+\]" | awk 'NR % 200 == 0' || true
    [[ "${PIPESTATUS[0]}" -eq 0 ]]
    cmake --install "${SRC}/opencv/build" > "${LOGS}/opencv-install.log"
    touch "${OPENCV_PREFIX}/.done"
fi

# ---------------------------------------------------------------------------
# 3. OpenCvSharpExtern from the vendored wrapper source
#    (native_src/CMakeLists-src.txt is upstream's src/CMakeLists.txt, renamed
#    so nothing treats native_src/ as a live build - stage it back here)
# ---------------------------------------------------------------------------
rm -rf "${EXTERN_SRC}" "${EXTERN_BUILD}"
mkdir -p "${EXTERN_SRC}"
cp "${REPO_ROOT}/native_src/CMakeLists-src.txt" "${EXTERN_SRC}/CMakeLists.txt"
cp -r "${REPO_ROOT}/native_src/OpenCvSharpExtern" "${EXTERN_SRC}/OpenCvSharpExtern"

VLIB="${VCPKG_INSTALLED}/${TRIPLET}/lib"
cmake \
    -G Ninja \
    -S "${EXTERN_SRC}" \
    -B "${EXTERN_BUILD}" \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_PREFIX_PATH="${OPENCV_PREFIX};${VCPKG_INSTALLED}/${TRIPLET}" \
    -D CMAKE_OSX_ARCHITECTURES=x86_64 \
    -D CMAKE_OSX_DEPLOYMENT_TARGET="${DEPLOYMENT_TARGET}" \
    -D CMAKE_SHARED_LINKER_FLAGS="-L${VLIB} -llzma -lzstd -lsharpyuv -lwebp -lwebpmux -lwebpdemux -lwebpdecoder -ljpeg -lpng16 -ltiff -ltesseract -lleptonica -lgif -lfreetype -lharfbuzz -llz4 -framework AudioToolbox -framework VideoToolbox -framework CoreMedia -framework CoreVideo -framework CoreAudio -framework AVFoundation -framework OpenGL -framework IOSurface -framework QuartzCore -framework CoreFoundation" \
    2>&1 | tee "${LOGS}/extern-configure.log"
cmake --build "${EXTERN_BUILD}" -j "${JOBS}" 2>&1 | tee "${LOGS}/extern-build.log" | tail -5
[[ "${PIPESTATUS[0]}" -eq 0 ]]

DYLIB="${EXTERN_BUILD}/OpenCvSharpExtern/libOpenCvSharpExtern.dylib"
[[ -f "${DYLIB}" ]] || { echo "ERROR: build produced no ${DYLIB}" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 4. Verification
# ---------------------------------------------------------------------------
echo "=== architecture / minimum macOS ==="
lipo -archs "${DYLIB}"
[[ "$(lipo -archs "${DYLIB}")" == "x86_64" ]]
MINOS="$(otool -l "${DYLIB}" | awk '/LC_BUILD_VERSION/{f=1} f&&/minos/{print $2; exit}')"
echo "minos: ${MINOS}"

# Only the OS itself may be a dynamic dependency: /usr/lib (libSystem, libc++,
# libz, libbz2, libiconv, ...) and /System frameworks. Anything else -
# /usr/local, /opt/homebrew, @rpath to a sibling - would fail on a clean Mac.
echo "=== dependency allowlist check ==="
DEPS="$(otool -L "${DYLIB}" | tail -n +2 | awk '{print $1}' | grep -v '^@rpath/libOpenCvSharpExtern.dylib$')"
echo "${DEPS}"
BAD_DEPS="$(echo "${DEPS}" | grep -Ev '^(/usr/lib/|/System/Library/)' || true)"
if [[ -n "${BAD_DEPS}" ]]; then
    echo "ERROR: dynamic dependencies outside /usr/lib and /System/Library:" >&2
    echo "${BAD_DEPS}" >&2
    exit 1
fi
echo "OK: only OS libraries and frameworks."

echo "=== smoke test ==="
# dlopen + dlsym, the way .NET's NativeLibrary consumes the library. RTLD_NOW
# forces every symbol to bind up front, so a dangling reference fails here.
SMOKE="${CACHE}/smoke"
mkdir -p "${SMOKE}"
cat > "${SMOKE}/test.c" <<'EOF'
#include <dlfcn.h>
#include <stdio.h>
int main(int argc, char **argv) {
    void *h = dlopen(argv[1], RTLD_NOW | RTLD_LOCAL);
    if (!h) { fprintf(stderr, "dlopen failed: %s\n", dlerror()); return 1; }
    int (*fn)(void) = (int (*)(void))dlsym(h, "core_Mat_sizeof");
    if (!fn) { fprintf(stderr, "dlsym failed: %s\n", dlerror()); return 1; }
    printf("sizeof(Mat) = %d\n", fn());
    return 0;
}
EOF
clang "${SMOKE}/test.c" -o "${SMOKE}/test"
"${SMOKE}/test" "${DYLIB}"

# Every native entry point the managed binding P/Invokes (the EntryPoint of each
# [LibraryImport(DllExtern ...)] in src/, or the method name when it has none)
# that the shipped upstream osx-x64 binary exports must be exported by the new
# build too. (About 35 declared entry points were never exported by any shipped
# binary; those are compared, not required. A raw export-table diff is NOT the
# gate: the upstream binary also leaked Intel IPP and FFmpeg internals whose set
# varies with the dependency versions.)
echo "=== P/Invoke entry-point parity with the shipped osx-x64 binary ==="
SHIPPED_XZ="${REPO_ROOT}/native_libraries/runtimes/${RID}/native/libOpenCvSharpExtern.dylib.xz"
xz -dc "${SHIPPED_XZ}" > "${SMOKE}/shipped.dylib"
nm -gU "${SMOKE}/shipped.dylib" | awk '{print $3}' | sort -u > "${SMOKE}/shipped.syms"
nm -gU "${DYLIB}"               | awk '{print $3}' | sort -u > "${SMOKE}/built.syms"
find "${REPO_ROOT}/src" -name '*.cs' -print0 | xargs -0 perl -0ne '
    while (/\[(?:LibraryImport|DllImport)\(\s*DllExtern([^\]]*)\][^;{]*?[\s*]([A-Za-z_][A-Za-z0-9_]*)\s*\(/sg) {
        my ($attr, $method) = ($1, $2);
        print(($attr =~ /EntryPoint\s*=\s*"([^"]+)"/ ? $1 : $method), "\n");
    }' | sed 's/^/_/' | sort -u > "${SMOKE}/entrypoints.syms"
comm -12 "${SMOKE}/entrypoints.syms" "${SMOKE}/shipped.syms" > "${SMOKE}/required.syms"
MISSING="$(comm -23 "${SMOKE}/required.syms" "${SMOKE}/built.syms" || true)"
echo "declared: $(wc -l < "${SMOKE}/entrypoints.syms")  exported by shipped: $(wc -l < "${SMOKE}/required.syms")"
if [[ -n "${MISSING}" ]]; then
    echo "ERROR: P/Invoke entry points missing from the new build:" >&2
    echo "${MISSING}" >&2
    exit 1
fi
echo "OK: every P/Invoke entry point the shipped binary exports is present."
rm -f "${SMOKE}/shipped.dylib"

# ---------------------------------------------------------------------------
# Artifacts
# ---------------------------------------------------------------------------
cp "${DYLIB}" "${OUT}/libOpenCvSharpExtern.dylib"
SHA256="$(shasum -a 256 "${OUT}/libOpenCvSharpExtern.dylib" | awk '{print $1}')"
{
    echo "libOpenCvSharpExtern.dylib build info"
    echo "rid:                  ${RID}"
    echo "built:                $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo "sha256:               ${SHA256}"
    echo "minimum macOS:        ${MINOS}"
    echo "opencv:               ${OPENCV_VERSION} @ ${OPENCV_COMMIT}"
    echo "opencv_contrib:       @ ${OPENCV_CONTRIB_COMMIT}"
    echo "vcpkg baseline:       ${VCPKG_COMMIT}"
    echo "vcpkg triplet:        ${TRIPLET}"
    echo "extra configure:      WITH_AVIF=OFF (see build_macos.sh header)"
    echo "build host:           macOS $(sw_vers -productVersion) ($(sw_vers -buildVersion)), $(uname -m)"
    echo "compiler:             $(clang --version | head -1)"
    echo "macOS SDK:            $(xcrun --show-sdk-version)"
    echo "cmake / ninja:        $(cmake --version | head -1 | awk '{print $3}') / $(ninja --version)"
    echo "nasm:                 ${NASM_VERSION} (${NASM_MACOS_URL}, sha256 ${NASM_MACOS_SHA256})"
    echo "vcpkg packages (name:triplet version):"
    "${VCPKG_ROOT}/vcpkg" list --x-install-root="${VCPKG_INSTALLED}" 2>/dev/null \
        | awk '$1 !~ /\[/ {print "  " $1 " " $2}'
    echo "vcpkg source downloads (sha256):"
    (cd "${VCPKG_ROOT}/downloads" 2>/dev/null && find . -maxdepth 1 -type f ! -name '*.part' \
        -exec shasum -a 256 {} + | sed -E 's|  \./|  |' | sort -k2 | sed 's/^/  /') || true
    echo "dynamic dependencies:"
    echo "${DEPS}" | sed 's/^/  /'
} > "${OUT}/build-info.txt"

echo "=============================================================="
echo "SUCCESS: ${OUT}/libOpenCvSharpExtern.dylib (sha256 ${SHA256})"
echo "=============================================================="
