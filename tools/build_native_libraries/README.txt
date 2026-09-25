================================================================================
tools/build_native_libraries - portable Linux natives, built the manylinux way,
                               and the macOS x64 native (build_macos.sh)
================================================================================

WHAT THIS IS
------------
Tooling to build libOpenCvSharpExtern.so for Linux x64, ARM64, and RISC-V 64
following the SAME model upstream used for the shipped linux-x64 binary (the
"manylinux" recipe in native_src/ci-workflows/manylinux.yml, build_full job):

  * built inside a manylinux container = oldest practical glibc baseline,
    so one binary runs on effectively every modern glibc distro
  * FFmpeg, libjpeg-turbo, libpng, libtiff, libwebp, zlib, Tesseract and
    Leptonica are STATICALLY linked (FFmpeg from source, the rest via vcpkg)
  * only universal system libraries remain dynamic (glibc, libstdc++, GTK3
    stack for highgui, libX11, ...)

WHY IT EXISTS: the shipped upstream linux-arm64 binary was NOT built this way -
it was built on an ubuntu-24.04-arm runner against Ubuntu's shared libraries
(libavcodec.so.60 / libjpeg.so.8 / libtesseract.so.5 ...), so it only loads on
Ubuntu 24.04-family systems and fails on every Raspberry Pi OS release
("libtesseract.so.5: cannot open shared object file"). Building arm64 with the
x64 recipe fixes that for every Pi (and Ubuntu) at once. RISC-V 64 has no
upstream binary at all; this tooling closes that gap with the same model.

ARCHITECTURE MATRIX
-------------------
  arch     container image (pins.env)            glibc baseline -> runs on
  x64      quay.io/pypa/manylinux_2_28_x86_64    2.28: Debian 10+/Ubuntu 20.04+/RHEL 8+
  arm64    quay.io/pypa/manylinux_2_28_aarch64   2.28: every 64-bit Raspberry Pi OS,
                                                       Ubuntu 20.04+ arm64, ...
  riscv64  quay.io/pypa/manylinux_2_39_riscv64   2.39: Ubuntu 24.04+, Debian 13+
                                                       (RISC-V distros are all newer
                                                       than this in practice)

All version/commit/image pins live in pins.env - opencv and opencv_contrib are
pinned to the EXACT revisions the shipped upstream natives were built from
(recorded in native_src/README-NATIVE-SRC.txt); the vcpkg baseline comes from
native_src/vcpkg.json; the FFmpeg version matches upstream's
build_static_deps.sh.

HOST REQUIREMENTS (installed by YOU, never by these scripts)
------------------------------------------------------------
  * podman (or docker). On Raspberry Pi OS / Debian:  sudo apt install podman
    For an arch matching the host (e.g. arm64 on a Raspberry Pi), the
    container engine is the ONLY prerequisite - nothing else is needed.
  * for a NON-native architecture (e.g. building riscv64 or x64 on the Pi):
    qemu-user-static + binfmt support:  sudo apt install qemu-user-static
    Emulated OpenCV builds are very slow (a day or more); prefer building each
    arch on a native host when you have one (e.g. x64 on the LMDE box, arm64
    on this Pi).
  * disk: ~25 GB free per architecture (under cache/)
  * time (native): FFmpeg ~15 min, vcpkg deps ~30-60 min, OpenCV 1.5-4 h,
    wrapper ~10 min. Roughly 2.5-5 h total on a Raspberry Pi 5.
    RAM: OpenCV links are hungry; if the build OOMs, re-run with JOBS=2 (or 1).

NETWORK DOWNLOADS (happen only when YOU run the build, all pinned)
------------------------------------------------------------------
  * container image (quay.io)
  * github.com/opencv/opencv           @ pinned commit
  * github.com/opencv/opencv_contrib   @ pinned commit
  * github.com/microsoft/vcpkg         @ pinned baseline commit
    (vcpkg then downloads its packages' sources)
  * ffmpeg.org release tarball         @ pinned version
  Nothing is fetched from shimat/opencvsharp or nuget.org - the wrapper C++
  source comes from this repo's vendored native_src/ (per the 2026-07-07
  repo decision). The scripts never install anything on the host.

USAGE
-----
  cd tools/build_native_libraries
  ./build.sh arm64          # or x64 / riscv64 / all

  Overrides:  CONTAINER_ENGINE=docker ./build.sh arm64
              IMAGE_OVERRIDE=riscv64/ubuntu:24.04 ./build.sh riscv64
              JOBS=2 ./build.sh arm64     (low-RAM hosts)

  State/outputs (both git-ignored):
    cache/<rid>/    persistent build state; delete to force a full rebuild;
                    an interrupted build resumes from the last finished stage
    output/<rid>/   libOpenCvSharpExtern.so + build-info.txt (sha256, pins,
                    dynamic-dependency list, glibc ceiling)

BUILT-IN VERIFICATION (a build only succeeds if ALL of these pass)
------------------------------------------------------------------
  * required-features check: Tesseract/FFMPEG/JPEG/PNG/TIFF/WEBP must all be
    enabled in the OpenCV configure log (same check as upstream CI)
  * forbidden-soname check: the .so must NOT dynamically link libavcodec/
    libavformat/libavutil/libswscale/libswresample/libjpeg/libpng/libtiff/
    libwebp/libtesseract/liblept/libz - those must be inside the binary.
    This is exactly the defect the shipped arm64 binary has; the check makes
    it impossible to reproduce.
  * C smoke test: dlopen()s the .so and calls core_Mat_sizeof() via dlsym()
    (exactly how .NET's NativeLibrary consumes it; a static link would
    demand full up-front resolution and trip on the allowlisted reference
    below)
  * dangling-symbol allowlist: after the loader walks the full dependency
    closure (ldd -r), the only unresolved symbols allowed are MLAS's
    MlasHGemmSupported (latent OpenCV 5.0.0 DNN FP16/GQA reference,
    implemented only in MLAS's ARM64 kernels; absent on arm64 builds since
    they disable MLAS) and libtiff's two liblzma references
    (lzma_lzma_preset, lzma_stream_encoder). The exact upstream-shipped
    linux-x64 binary carries all three (verified 2026-07-22); all are
    benign under lazy binding. Any OTHER dangling symbol fails the build
  * glibc-ceiling report (informational; recorded in build-info.txt)

Recommended additional test on a real target machine: stage output/<rid>/
libOpenCvSharpExtern.so into the test suite per MAINTAINER-README.txt ("RUNNING THE
TESTS" sections) and run the ported test suite against it.

MACOS X64 (osx-x64) - build_macos.sh (added 2026-09-24)
-------------------------------------------------------
macOS cannot run in a container, so osx-x64 is built directly on an Intel Mac
host by build_macos.sh, following the upstream macOS x64 recipe
(native_src/ci-workflows/macos.yml, "build_x64" job) step for step: vcpkg with
upstream's x64-osx-static triplet (image libs, Tesseract, Leptonica, FFmpeg,
HDF5, FreeType, HarfBuzz, Eigen - all static), OpenCV + contrib with the same
options, and the wrapper with upstream's exact link line. Minimum macOS 11.0.

WHY IT EXISTS: the upstream osx-x64 binary (5.0.0.20260704) was built on a
GitHub macos-26-intel runner that had Homebrew's libavif installed; OpenCV's
imgcodecs auto-detected it, so the shipped dylib hard-links
/usr/local/opt/libavif/lib/libavif.16.dylib and fails to load on every Intel
Mac without that package ("Library not loaded: ...libavif.16.dylib"). The
build adds -D WITH_AVIF=OFF (osx-arm64 has no AVIF either, so both macOS RIDs
expose the same codecs). osx-arm64 is NOT rebuilt: its upstream binary has no
such dependency.

HOST REQUIREMENTS (installed by YOU, never by the script)
  * Intel Mac + Xcode Command Line Tools
  * cmake, ninja, pkg-config, git, curl, xz, unzip on PATH
  * NOT nasm: vcpkg acquires NASM itself only on Windows, so the script
    downloads the official NASM 3.01 macOS build (pins.env NASM_*, SHA-256
    checked) into cache/ and puts it on PATH for the build only
  * ~30 GB disk; time on a 2018 6-core i7 Mac mini: vcpkg ~1 h, OpenCV
    ~25 min, wrapper ~2 min

BUILD-HOST HYGIENE: a Mac with Homebrew in /usr/local is exactly how libavif
leaked into the upstream binary, so pkg-config is confined to the vcpkg
install tree (PKG_CONFIG_LIBDIR) and the gates below catch anything else.

OVERLAY PORT: overlay-ports/libaec (an HDF5 dependency) is the baseline port
with ONE change - its source comes over git (URL + pinned commit) instead of
GitLab's generated archive, because gitlab.dkrz.de answered every anonymous
archive request with HTTP 429 (from two different networks, 2026-09-24). The
commit pins the source as exactly as the archive's SHA512 did.

USAGE
  cd tools/build_native_libraries
  ./build_macos.sh x64          (JOBS=<n> to limit parallelism)
  State under cache/osx-x64/ (resumable, delete to rebuild), logs in
  cache/osx-x64/logs/, artifacts in output/osx-x64/. Relinking is
  deterministic: a re-run reproduces the same SHA-256.

BUILT-IN VERIFICATION (the build succeeds only if ALL pass)
  * the upstream feature check (JPEG/PNG/TIFF/WEBP/FFMPEG/Tesseract) plus
    AVIF must be OFF
  * no /usr/local or /opt/homebrew library/include path in the OpenCV
    CMakeCache.txt
  * dependency allowlist: every otool -L entry must be under /usr/lib or
    /System/Library (the 2026-09-24 build: the old binary's list minus
    libavif, identical to osx-arm64's list)
  * dlopen(RTLD_NOW) + dlsym(core_Mat_sizeof) smoke test
  * P/Invoke entry-point parity: every [LibraryImport(DllExtern ...)] entry
    point in src/ that the shipped osx-x64 binary exported must still be
    exported (3118 of 3153 declared; the other 35 were never exported by
    any shipped binary). A raw export-table diff is deliberately NOT used:
    the upstream binary also leaked Intel IPP and FFmpeg internals whose
    set varies with dependency versions.

build-info.txt additionally records the build host, compiler, SDK, every
vcpkg package version, and the SHA-256 of every source archive vcpkg
downloaded.

ADOPTING A BUILT ARTIFACT INTO THE SHIPPED PACKAGES
---------------------------------------------------
NOTE: adoption happened 2026-07-22 for ALL THREE Linux RIDs and 2026-09-24
for osx-x64 (build_macos.sh; same steps with libOpenCvSharpExtern.dylib) -
native_libraries/ now holds self-built binaries for linux-x64/linux-arm64/
linux-riscv64/osx-x64 (the 2026-07-07 "exact upstream artifacts, never
rebuilt" decision is SUPERSEDED for those RIDs; it still governs win-* and
osx-arm64, and the supersession is recorded in MAINTAINER-README.txt,
PROVENANCE AND VENDORED SOURCES). Steps, for future re-adoptions:

  1. xz -9e -k output/<rid>/libOpenCvSharpExtern.so
     mv output/<rid>/libOpenCvSharpExtern.so.xz \
        ../../native_libraries/runtimes/<rid>/native/
     (and place the RAW .so there too for local use - it stays git-ignored)
  2. Update the <rid> line in native_libraries/SHA256SUMS.txt with the sha256
     from build-info.txt (the pack step verifies it and fails on mismatch).
  3. Pack and publish per MAINTAINER-README.txt (PACKAGING AND PUBLISHING)
     (family rule: all packages publish at one version in one event).

  The linux-riscv64 runtime package plumbing was added 2026-07-22:
  CodeBrix.VideoProcessing.OpenCV5.LinuxRiscv64.nuspec in build/nuget/ (note
  the casing - Riscv64, matching the LinuxArm64 pattern), its entry in the
  build driver, and runtimes/linux-riscv64/native/ under native_libraries/.
  The package is usable today with experimental riscv64 .NET 10 SDK builds.

FILES
-----
  pins.env                       all version/commit/image pins (edit here only)
  build.sh                       host entry point (container orchestration)
  container_build.sh             the actual build, runs inside the container
  triplets/arm64-linux-static.cmake    vcpkg overlay triplet (new arch)
  triplets/riscv64-linux-static.cmake  vcpkg overlay triplet (new arch)
  (x64 uses upstream's native_src/cmake/triplets/x64-linux-static.cmake)
  build_macos.sh                 osx-x64 build on an Intel Mac host (no container)
  overlay-ports/libaec/          libaec port fetching over git (see MACOS X64)
================================================================================
