================================================================================
EXTRAS-README: CodeBrix.VideoProcessing.OpenCV5
Samples, tools and other content in this repository that is not part of a
NuGet package
================================================================================

There are no sample or demo applications in this repository. The non-package
content is the native build pipeline, the vendored native sources it consumes,
the vendored native binaries themselves, and the test projects.

tools/build_native_libraries/ — the Linux native build pipeline
===============================================================
WHAT IT IS
----------
Tooling that builds libOpenCvSharpExtern.so for Linux x64, ARM64 and RISC-V 64
following the same "manylinux" model upstream used for its shipped linux-x64
binary:

  * built inside a manylinux container, so the glibc baseline is the oldest
    practical one and a single binary runs on effectively every modern glibc
    distribution;
  * FFmpeg, libjpeg-turbo, libpng, libtiff, libwebp, zlib, Tesseract and
    Leptonica are STATICALLY linked (FFmpeg from source, the rest via vcpkg);
  * only universal system libraries stay dynamic — glibc, libstdc++, the GTK3
    stack used by highgui, and libX11.

WHY IT EXISTS: the upstream-shipped linux-arm64 binary was built on an
Ubuntu 24.04 ARM runner against Ubuntu's shared libraries (libavcodec.so.60,
libjpeg.so.8, libtesseract.so.5, ...), so it loaded only on Ubuntu 24.04-family
systems and failed on every Raspberry Pi OS release. Building arm64 with the
x64 recipe fixes that for every Pi and Ubuntu at once. RISC-V 64 had no
upstream binary at all; this tooling closes that gap with the same model.

ARCHITECTURE MATRIX
-------------------
  arch     container image (pins.env)            glibc baseline -> runs on
  x64      quay.io/pypa/manylinux_2_28_x86_64    2.28: Debian 10+/Ubuntu 20.04+/
                                                       RHEL 8+
  arm64    quay.io/pypa/manylinux_2_28_aarch64   2.28: every 64-bit Raspberry Pi
                                                       OS, Ubuntu 20.04+ arm64
  riscv64  quay.io/pypa/manylinux_2_39_riscv64   2.38 ceiling on the produced
                                                       binary: Ubuntu 24.04+,
                                                       Debian 13+

All version/commit/image pins live in pins.env. opencv and opencv_contrib are
pinned to the EXACT revisions the shipped upstream natives were built from
(recorded in native_src/README-NATIVE-SRC.txt); the vcpkg baseline comes from
native_src/vcpkg.json; the FFmpeg version matches upstream's static-deps
script.

HOST REQUIREMENTS (installed by YOU, never by these scripts)
------------------------------------------------------------
  * podman (or docker). On Raspberry Pi OS / Debian:  sudo apt install podman
    For an architecture matching the host, the container engine is the ONLY
    prerequisite.
  * For a NON-native architecture (e.g. riscv64, or x64 on a Pi):
    qemu-user-static plus binfmt support:  sudo apt install qemu-user-static
    Emulated OpenCV builds are very slow (a day or more); prefer building each
    architecture on a native host.
  * Disk: about 25 GB free per architecture (under cache/).
  * Time on a native host: FFmpeg ~15 min, vcpkg deps ~30-60 min, OpenCV
    1.5-4 h, wrapper ~10 min — roughly 2.5-5 h total on a Raspberry Pi 5.
    OpenCV links are RAM-hungry; if the build is killed, re-run with JOBS=2
    (or 1).

NETWORK DOWNLOADS (only when YOU run a build; all pinned)
---------------------------------------------------------
The container image from quay.io; opencv, opencv_contrib and vcpkg from
github.com at pinned commits (vcpkg then downloads its packages' sources); an
FFmpeg release tarball from ffmpeg.org. NOTHING is fetched from
shimat/opencvsharp or nuget.org — the wrapper C++ source comes from this
repo's vendored native_src/, per the 2026-07-07 repo decision. The scripts
never install anything on the host.

HOW TO RUN
----------
    cd tools/build_native_libraries
    ./build.sh arm64          # or x64 / riscv64 / all

  Overrides:  CONTAINER_ENGINE=docker ./build.sh arm64
              IMAGE_OVERRIDE=riscv64/ubuntu:24.04 ./build.sh riscv64
              JOBS=2 ./build.sh arm64        (low-RAM hosts)

  State and outputs (both git-ignored):
    cache/<rid>/    persistent build state; delete to force a full rebuild.
                    An interrupted build resumes from the last finished stage.
    output/<rid>/   libOpenCvSharpExtern.so plus build-info.txt (sha256, all
                    pins, the full dynamic-dependency list, glibc ceiling).

BUILT-IN VERIFICATION (a build succeeds only if ALL of these pass)
------------------------------------------------------------------
  * Required-features check: Tesseract, FFMPEG, JPEG, PNG, TIFF and WEBP must
    all be enabled in the OpenCV configure log (the same check upstream CI
    performs).
  * Forbidden-soname check: the .so must NOT dynamically link libavcodec,
    libavformat, libavutil, libswscale, libswresample, libjpeg, libpng,
    libtiff, libwebp, libtesseract, liblept or libz — those must be inside
    the binary. This is exactly the defect the upstream arm64 binary has, so
    the check makes it impossible to reproduce.
  * C smoke test: dlopen()s the .so and calls core_Mat_sizeof() via dlsym(),
    which is how .NET's NativeLibrary consumes it.
  * Dangling-symbol allowlist: after the loader walks the full dependency
    closure (ldd -r), the ONLY unresolved symbols allowed are MLAS's
    MlasHGemmSupported (a latent OpenCV DNN FP16/GQA reference, implemented
    only in MLAS's ARM64 kernels and absent from arm64 builds because they
    disable MLAS) and libtiff's two liblzma references (lzma_lzma_preset,
    lzma_stream_encoder). The upstream-shipped linux-x64 binary carries all
    three too (verified 2026-07-22); all are benign under lazy binding. Any
    OTHER dangling symbol fails the build.
  * glibc-ceiling report (informational; recorded in build-info.txt).

Recommended additional check: stage output/<rid>/libOpenCvSharpExtern.so into
the test suite per MAINTAINER-README.txt (TESTING) and run the ported suite
against it on a real target machine.

ADOPTING A BUILT ARTIFACT INTO THE SHIPPED PACKAGES
---------------------------------------------------
Adoption already happened on 2026-07-22 for ALL THREE Linux RIDs;
native_libraries/ now holds self-built binaries for linux-x64, linux-arm64 and
linux-riscv64. Steps for a future re-adoption:

  1. xz -9e -k output/<rid>/libOpenCvSharpExtern.so
     mv output/<rid>/libOpenCvSharpExtern.so.xz \
        ../../native_libraries/runtimes/<rid>/native/
     (and place the RAW .so there too for local use — it stays git-ignored)
  2. Update the <rid> line in native_libraries/SHA256SUMS.txt with the sha256
     from build-info.txt. The pack step verifies it and fails on mismatch.
  3. Pack and publish per MAINTAINER-README.txt (PACKAGING AND PUBLISHING).
     Family rule: all packages publish at one version in one event.

FILES
-----
  pins.env                       all version/commit/image pins (edit only here)
  build.sh                       host entry point (container orchestration)
  container_build.sh             the actual build, runs inside the container
  triplets/arm64-linux-static.cmake     vcpkg overlay triplet
  triplets/riscv64-linux-static.cmake   vcpkg overlay triplet
  (x64 uses upstream's native_src/cmake/triplets/x64-linux-static.cmake)
  README.txt                     the full recipe, expanded

native_src/ — vendored upstream native sources (REFERENCE ONLY)
===============================================================
Everything here was copied VERBATIM from the upstream OpenCvSharp repository
(tag 5.0.0.20260703) so the native libraries COULD be rebuilt from source:

  OpenCvSharpExtern/      the C wrapper layer
  uwpOpenCvSharpExtern/   the UWP variant (that runtime package was not ported;
                          kept for reference only)
  cmake/                  CMake helper modules and build-option files
  scripts/                Windows build scripts (PowerShell)
  tools/                  linux-arm64 native build scripts (full and minimal)
  docker/                 Linux build dockerfiles, including the manylinux set
  ci-workflows/           the upstream CI workflow definitions
  devcontainer-manylinux/ the manylinux devcontainer definition
  vcpkg.json              native dependency manifest
  CMakeLists-src.txt      the top-level native CMake, renamed so nothing treats
                          this folder as a live build tree

tools/build_native_libraries/ consumes this folder for the Linux self-builds.
For Windows and macOS it is reference material only — those binaries are the
exact upstream-published artifacts and are never rebuilt here. See
native_src/README-NATIVE-SRC.txt for the per-folder provenance.

native_libraries/ — vendored native binaries
============================================
The shipped native binaries, xz-compressed, at the exact paths the runtime
nuspecs map into their packages (runtimes/<rid>/native/<file>.xz), plus
SHA256SUMS.txt with the SHA-256 of every RAW (uncompressed) binary. This is
package payload, not a sample; provenance and the never-commit-raw-binaries
rule are in MAINTAINER-README.txt and in
native_libraries/README-NATIVE-LIBRARIES.txt.

To materialize the raw binaries by hand:

    cd native_libraries
    find . -name '*.xz' -exec xz -dkf {} +
    sha256sum -c SHA256SUMS.txt

tests/ — the test projects
==========================
Three test projects, none of them packaged:

  tests/CodeBrix.VideoProcessing.OpenCV5.Tests/
      The ported upstream suite (xUnit v3), one folder per OpenCV module, with
      test images and model fixtures under _data/. Also the largest body of
      worked API examples in the repo — AGENT-README.txt's WORKING EXAMPLES ON
      GITHUB section maps every feature area to a folder here. Native-code
      tests need the native library materialized and on LD_LIBRARY_PATH; see
      MAINTAINER-README.txt (TESTING).
  tests/CodeBrix.VideoProcessing.OpenCV5.Analyzers.Tests/
      Unit tests for the OCVS001-004 analyzers, using the Roslyn testing
      harness. No native library needed.
  tests/CodeBrix.VideoProcessing.OpenCV5.Wpf.Tests/
      Windows-only; an empty assembly on other hosts, like the .Wpf library.

nugets/ — pack output
=====================
nugets/Release/<version>/ holds the .nupkg files from previous pack runs. It
is build output, kept for reference; it is not source and not a sample.
================================================================================
