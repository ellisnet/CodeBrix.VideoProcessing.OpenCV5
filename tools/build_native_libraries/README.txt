================================================================================
tools/build_native_libraries - portable Linux natives, built the manylinux way
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
  * C smoke test: links against the .so and calls core_Mat_sizeof()
  * glibc-ceiling report (informational; recorded in build-info.txt)

Recommended additional test on a real target machine: stage output/<rid>/
libOpenCvSharpExtern.so into the test suite per AGENT-README.txt ("RUNNING THE
TESTS" sections) and run the ported test suite against it.

ADOPTING A BUILT ARTIFACT INTO THE SHIPPED PACKAGES
---------------------------------------------------
NOTE: native_libraries/ currently holds "the exact artifacts upstream
published, never rebuilt" (AGENT-README.txt, decision 2026-07-07). Replacing
one with a self-built binary supersedes that decision for the affected RID -
record the change in AGENT-README.txt when you do it. Steps:

  1. xz -9e -k output/<rid>/libOpenCvSharpExtern.so
     mv output/<rid>/libOpenCvSharpExtern.so.xz \
        ../../native_libraries/runtimes/<rid>/native/
     (and place the RAW .so there too for local use - it stays git-ignored)
  2. Update the <rid> line in native_libraries/SHA256SUMS.txt with the sha256
     from build-info.txt (the pack step verifies it and fails on mismatch).
  3. Pack and publish per AGENT-README.txt "PACKAGING / BUILD DRIVER"
     (family rule: all packages publish at one version in one event).

  For linux-riscv64 there is no runtime package yet: it needs a new
  CodeBrix.VideoProcessing.OpenCV5.LinuxRiscV64.nuspec in build/nuget/ (copy
  the LinuxArm64 one, adjust RID/description), a nuspec entry in the build
  driver, and a runtimes/linux-riscv64/native/ folder under native_libraries/.
  Also note: .NET itself does not yet ship official linux-riscv64 runtimes
  (community/Ubuntu builds exist) - the native library is forward preparation.

FILES
-----
  pins.env                       all version/commit/image pins (edit here only)
  build.sh                       host entry point (container orchestration)
  container_build.sh             the actual build, runs inside the container
  triplets/arm64-linux-static.cmake    vcpkg overlay triplet (new arch)
  triplets/riscv64-linux-static.cmake  vcpkg overlay triplet (new arch)
  (x64 uses upstream's native_src/cmake/triplets/x64-linux-static.cmake)
================================================================================
