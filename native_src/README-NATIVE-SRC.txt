================================================================================
native_src/ — verbatim upstream native build sources (REFERENCE ONLY)
================================================================================

Everything in this folder was copied VERBATIM (no renames, no edits) from the
upstream OpenCvSharp repository, so that the native OpenCvSharpExtern
libraries COULD be rebuilt from source in the future. Nothing in this repo
builds these sources today — the shipped native binaries are the exact
upstream-published artifacts vendored xz-compressed under native_libraries/.

Copied 2026-07-07 from https://github.com/shimat/opencvsharp
tag 5.0.0.20260703 (commit d3bb1f3f3f8b906804c0dde6e8444fd12bd6d5b7):

  OpenCvSharpExtern/     from src/OpenCvSharpExtern    (the C wrapper layer)
  uwpOpenCvSharpExtern/  from src/uwpOpenCvSharpExtern (UWP variant; the UWP
                         runtime package was NOT ported — kept for reference)
  cmake/                 from cmake/                   (CMake helper modules)
  scripts/               from scripts/                 (Windows build scripts)
  docker/                from packaging/docker/        (Linux build dockerfiles)
  vcpkg.json             from vcpkg.json               (native deps manifest)
  CMakeLists-src.txt     from src/CMakeLists.txt       (top-level native CMake;
                         renamed so nothing treats this folder as a live build)
  tools/                 from src/tools/                (linux-arm64 native build
                         scripts, full + minimal variants)
  devcontainer-manylinux/ from .devcontainer/manylinux/ (the manylinux_2_28
                         devcontainer recipe that builds the shipped linux-x64
                         libOpenCvSharpExtern.so)
  ci-workflows/          from .github/workflows/        (ONLY the 7 native-build
                         workflows: windows.yml, manylinux.yml, macos.yml,
                         linux-arm64.yml, docker-test-ubuntu.yml,
                         docker-deploy.yml, wasm.yml — the authoritative recipes
                         upstream actually ran to produce every shipped native)
  .dockerignore          from .dockerignore             (docker build support)
  embedded-builds.md     from docs/embedded-builds.md   (custom/minimal native
                         build guide with the module-exclusion flag table)

OPENCV SOURCE REVISIONS (submodule pins at the vendored tag):
The upstream repo carries opencv and opencv_contrib as git submodules; the
submodule CONTENTS are deliberately not vendored here, but the exact pinned
revisions the shipped natives were built from are:

  opencv          https://github.com/opencv/opencv.git
                  commit 40738fb16ceddb5fb3fea747585f7ce6abb0605b
  opencv_contrib  https://github.com/opencv/opencv_contrib.git
                  commit 755e50675d97db9b7d449d8bd6b09888646f6c6e

A faithful native rebuild must check out those revisions.

Per the repo-wide decision of 2026-07-07: NEVER pull anything from the
upstream repo or nuget.org again — this folder is the permanent snapshot.
License: Apache-2.0 (see THIRD-PARTY-NOTICES.txt item 1).
================================================================================
