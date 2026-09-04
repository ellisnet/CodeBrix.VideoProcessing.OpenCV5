================================================================================
MAINTAINER-README: CodeBrix.VideoProcessing.OpenCV5
Notes for people and agents MAINTAINING this repository — not for package
consumers
================================================================================

PURPOSE AND SCOPE
=================
This repository produces NINE NuGet packages, all Apache-2.0, all published
together at ONE version in ONE event (the CodeBrix family rule):

  CodeBrix.VideoProcessing.OpenCV5.ApacheLicenseForever
      The managed binding assembly, plus the four Roslyn analyzers under
      analyzers/dotnet/cs. Built from
      src/CodeBrix.VideoProcessing.OpenCV5/.
  CodeBrix.VideoProcessing.OpenCV5.Wpf.ApacheLicenseForever
      WPF <-> Mat converters. Built from
      src/CodeBrix.VideoProcessing.OpenCV5.Wpf/. Windows-only; the REAL
      assembly and package can only be produced on a Windows host.
  CodeBrix.VideoProcessing.OpenCV5.WindowsX64.ApacheLicenseForever
  CodeBrix.VideoProcessing.OpenCV5.WindowsArm64.ApacheLicenseForever
  CodeBrix.VideoProcessing.OpenCV5.LinuxX64.ApacheLicenseForever
  CodeBrix.VideoProcessing.OpenCV5.LinuxArm64.ApacheLicenseForever
  CodeBrix.VideoProcessing.OpenCV5.LinuxRiscv64.ApacheLicenseForever
  CodeBrix.VideoProcessing.OpenCV5.MacOSX64.ApacheLicenseForever
  CodeBrix.VideoProcessing.OpenCV5.MacOSArm64.ApacheLicenseForever
      SEVEN native runtime packages, one per OS/CPU pair. Each is built from
      its own nuspec in build/nuget/ and carries exactly one native binary
      (two on win-x64) plus the documentation files. No lib/ assembly, no
      build/ props or targets, and NO dependency on the managed core.

There is exactly ONE consumer document, AGENT-README.txt at the repo root; it
covers all nine packages and is packed into every one of them. See
README-INDEX.txt for the map of README files.

Known metadata drift (do not "fix" without a coordinated packaging change):
the <Description> in src/CodeBrix.VideoProcessing.OpenCV5/
CodeBrix.VideoProcessing.OpenCV5.csproj lists only SIX native runtime
packages — it predates LinuxRiscv64. The repo really produces seven; the
build driver, build/nuget/ and AGENT-README.txt all say seven.

REPOSITORY LAYOUT
=================
  src/CodeBrix.VideoProcessing.OpenCV5/        the managed core
      Cv2/            partial Cv2 class, one file per OpenCV module
                      (Cv2_core, Cv2_imgproc, Cv2_imgcodecs, Cv2_features,
                       Cv2_calib, Cv2_calib.FishEye, Cv2_geometry,
                       Cv2_objdetect, Cv2_photo, Cv2_stereo, Cv2_video,
                       Cv2_superres, Cv2_ptcloud, Cv2_highgui)
      Fundamentals/   CvObject / CvPtrObject bases, safe handles, the two
                      exception types, MatMemoryManager
      Internal/       the P/Invoke layer: PInvoke/NativeMethods partials,
                      Vectors/, Util/, and NativeLibraryLoadDiagnostics.cs
      Modules/        one folder per OpenCV module — core, imgproc, imgcodecs,
                      videoio, features, flann, calib, geometry, stereo,
                      objdetect, ml, dnn, video, optflow, bgsegm, tracking,
                      photo, highgui, stitching, shape, superres, ptcloud,
                      barcode, wechat_qrcode, and the contrib modules aruco,
                      face, text, img_hash, quality, saliency, line_descriptors,
                      dnn_superres, xfeatures2d, ximgproc, xphoto
      InternalsVisibleTo.cs
  src/CodeBrix.VideoProcessing.OpenCV5.Analyzers/   Roslyn analyzers
                      (OCVS001-004), netstandard2.0, IsPackable=false
  src/CodeBrix.VideoProcessing.OpenCV5.Wpf/         WPF converters
  tests/CodeBrix.VideoProcessing.OpenCV5.Tests/           ported upstream suite
  tests/CodeBrix.VideoProcessing.OpenCV5.Analyzers.Tests/ analyzer unit tests
  tests/CodeBrix.VideoProcessing.OpenCV5.Wpf.Tests/       Windows-only
  build/              pack driver, the SEVEN runtime nuspecs, the pack shim
  native_libraries/   xz-compressed vendored natives + SHA256SUMS.txt
  native_src/         verbatim upstream C++/CMake/docker/CI sources
  tools/build_native_libraries/   the Linux native build pipeline
                      (see EXTRAS-README.txt)
  nugets/Release/<version>/       pack output
  CodeBrix.VideoProcessing.OpenCV5.slnx           the solution

The .slnx lists AGENT-README.txt, EXTRAS-README.txt, icon-codebrix-128.png,
LICENSE, MAINTAINER-README.txt, README-INDEX.txt, README.md and
THIRD-PARTY-NOTICES.txt under Solution Items, the three test projects under a
Tests folder, the driver and shim under a Build folder, and the three src
projects at the root. Keep the Solution Items list in step when a root file is
added or removed. There is no global.json in this repository, so `dotnet test`
uses whichever runner the installed SDK defaults to.

BUILDING
========
    dotnet build CodeBrix.VideoProcessing.OpenCV5.slnx

On non-Windows hosts the .Wpf project and .Wpf.Tests compile to empty
assemblies (their two converter sources are excluded outright), so the whole
solution restores and builds everywhere.

TESTING
=======
    dotnet test CodeBrix.VideoProcessing.OpenCV5.slnx

tests/CodeBrix.VideoProcessing.OpenCV5.Tests/ is the ported upstream suite:
xUnit v3, kept in upstream's Assert style (NOT SilverAssertions) per the
2026-07-07 decision, one folder per module, with test images and fixtures in
_data/. Some tests download DNN models from the network on first run
(FileDownloader.cs / ModelDownloader.cs), guarded for the heavier cases by
the repo's ExplicitFactAttribute / ExplicitTheoryAttribute.
ArchitectureSpecificFactAttribute gates the architecture-dependent cases.

tests/CodeBrix.VideoProcessing.OpenCV5.Analyzers.Tests/ uses the Roslyn
testing harness and needs no native library.

RUNNING THE NATIVE-DEPENDENT TESTS ON LINUX / MACOS
---------------------------------------------------
Tests that exercise native code REQUIRE the native library to be materialized
AND locatable. Materialize first (or run the driver's MaterializeNatives
target), then put the folder on LD_LIBRARY_PATH:

    cd native_libraries
    find . -name '*.xz' -exec xz -dkf {} +
    sha256sum -c SHA256SUMS.txt
    cd -
    export LD_LIBRARY_PATH="$PWD/native_libraries/runtimes/linux-x64/native:$LD_LIBRARY_PATH"
    dotnet test CodeBrix.VideoProcessing.OpenCV5.slnx

The .Tests csproj has a _RemindNativeLibraryPath target that runs before every
build on non-Windows and emits two loud, copy-pasteable warnings (it only
warns, never fails):

    CVNATIVE01  the native library has not been decompressed from its .xz
    CVNATIVE02  it is decompressed but the folder is not on LD_LIBRARY_PATH,
                and the warning text contains the exact export line

Both warning texts refer to "AGENT-README.txt TESTING". That section now
lives HERE, in MAINTAINER-README.txt — the csproj text was not updated
because packaging files are not edited as part of documentation work.

VERIFIED 2026-07-22: copying the raw .so into the test bin/ directory does
NOT work on Linux. The runtime's native probing for this project skips the
app directory — it probes the deps.json runtimes/linux-x64/native/ subdir and
the shared-framework dir, then falls back to plain dlopen, which honours
LD_LIBRARY_PATH. Use LD_LIBRARY_PATH on Linux. The copy-next-to-the-binary
approach documented for Windows below works there via PATH / app-directory
probing.

RUNNING THE TESTS ON WINDOWS (native setup — REQUIRED)
------------------------------------------------------
On Windows the native OpenCvSharpExtern library is NOT materialized or copied
to the test output automatically. Without the steps below, every test that
touches native code fails at the first `new Mat(...)` with:

    System.TypeInitializationException: The type initializer for
    '...Internal.NativeMethods' threw an exception.
      ---> System.DllNotFoundException: Unable to load DLL
      'OpenCvSharpExtern' or one of its dependencies (0x8007007E)

WHY IT DOES NOT "just work" on Windows (three separate reasons):
  1. The pack driver's MaterializeNatives target (which runs `xz -dkf`) is
     gated Condition="'$(OS)' != 'Windows_NT'" in
     build/CodeBrix.VideoProcessing.OpenCV5.Build.csproj — it only runs on
     Linux/macOS. On Windows the .dll.xz files are never decompressed.
  2. The .Tests project copies raw DLLs to its output only from a `dll/`
     subfolder (the `<None Update="dll\**\*.dll">` rule in the csproj), and
     that folder is deliberately untracked (the raw natives exceed GitHub's
     100 MiB blob limit).
  3. The .Wpf.Tests project has NO such copy rule at all, so even a populated
     `dll/` folder in the .Tests project does not reach the .Wpf.Tests output.

The natives you need are vendored, xz-compressed, at:
    native_libraries/runtimes/win-x64/native/OpenCvSharpExtern.dll.xz
    native_libraries/runtimes/win-x64/native/opencv_videoio_ffmpeg500_64.dll.xz
(win-arm64 has its own OpenCvSharpExtern.dll.xz; use it instead on ARM64.)
`xz` ships with Git for Windows at /mingw64/bin/xz (on PATH in Git Bash).

SETUP (Git Bash; from the repo root). Step A decompresses, step B verifies the
bytes against the committed manifest, step C stages them so the tests find
them:

  # A) Materialize the raw DLLs in place (-k keeps the .xz, -f overwrites stale)
  cd native_libraries/runtimes/win-x64/native
  xz -dkf OpenCvSharpExtern.dll.xz
  xz -dkf opencv_videoio_ffmpeg500_64.dll.xz
  cd -

  # B) Verify (optional but recommended). SHA256SUMS.txt has CRLF line endings,
  #    so strip CR before feeding it to sha256sum:
  cd native_libraries
  tr -d '\r' < SHA256SUMS.txt | grep win-x64 | sha256sum -c -
  cd -
  #    Expect: both win-x64 paths report ": OK".

  # C) Stage the two DLLs where the runtime's default DLL probing will find
  #    them. The binding sets [DefaultDllImportSearchPaths(LegacyBehavior)], so
  #    the app (test) output directory and PATH are both searched. Copy the two
  #    DLLs next to EACH native-dependent test binary:
  SRC=native_libraries/runtimes/win-x64/native
  cp "$SRC/OpenCvSharpExtern.dll" "$SRC/opencv_videoio_ffmpeg500_64.dll" \
     tests/CodeBrix.VideoProcessing.OpenCV5.Tests/bin/Debug/net10.0/
  cp "$SRC/OpenCvSharpExtern.dll" "$SRC/opencv_videoio_ffmpeg500_64.dll" \
     tests/CodeBrix.VideoProcessing.OpenCV5.Wpf.Tests/bin/Debug/net10.0-windows/

(CodeBrix.VideoProcessing.OpenCV5.Analyzers.Tests needs no native library.)

SURVIVING A REBUILD:
  A direct copy into bin/ (step C) is wiped by a full Rebuild/Clean. To make
  the ported .Tests suite self-sufficient, instead create the tracked-by-csproj
  staging folder and drop the DLLs there — the existing `dll\**\*.dll` copy
  rule then re-stages them on every build:
      mkdir -p tests/CodeBrix.VideoProcessing.OpenCV5.Tests/dll
      cp "$SRC/OpenCvSharpExtern.dll" "$SRC/opencv_videoio_ffmpeg500_64.dll" \
         tests/CodeBrix.VideoProcessing.OpenCV5.Tests/dll/
  The .Wpf.Tests project has no such rule, so its bin/ copy from step C must be
  redone after any Rebuild (or add an equivalent copy rule to its csproj).

DO NOT COMMIT the decompressed .dll files or the `dll/` staging folder
contents — they are large native binaries kept out of git on purpose (see
reason 2 above). Verified 2026-07-07: with the DLLs staged as above, all three
.Tests projects pass on Windows (net10.0 / net10.0-windows, x64).

Suite status: linux-x64 passed the FULL ported suite on this repo
(1254 pass / 31 skip, 2026-07-22).

PACKAGING AND PUBLISHING
========================
The driver mirrors the CodeBrix.Platform pack-only driver pattern.

  build/CodeBrix.VideoProcessing.OpenCV5.Build.csproj
    - IsPackable=false; compiles nothing. Computes the canonical date-stamped
      $(BuildVersion) ONCE per run (1.<years-since-2026>.<dayOfYear UTC>.
      <minuteOfDay UTC>), so a full run yields a version-locked set.
      Override with -p:BuildVersion=1.x.y.z when a package must be built on a
      second machine and stay in the same set.
    - MaterializeNatives target (Condition="'$(OS)' != 'Windows_NT'"):
      `find . -name '*.xz' -exec xz -dkf {} +` over native_libraries/, then
      `sha256sum -c SHA256SUMS.txt`. A mismatch FAILS the pack run.
    - PackCodeBrix target (AfterTargets=Build, Release only): captures git
      branch/commit for the nuspec <repository> tokens, then packs.
      * Linux/macOS run: the SEVEN runtime packages from build/nuget/*.nuspec
        through build/nuget-pack-shim/CodeBrix.Pack.Shim.csproj, then the
        managed core from its csproj.
      * Windows run: ONLY the .Wpf package from its csproj.
    - Output: nugets/$(Configuration)/$(BuildVersion)/

  build/nuget-pack-shim/CodeBrix.Pack.Shim.csproj
    A throwaway SDK project whose only job is to let the modern SDK packer
    pack a standalone .nuspec. The driver invokes it once per nuspec via
    `dotnet pack`, passing CbxNuspec, CbxNuspecBasePath, CbxVersion,
    CbxBranch and CbxCommit as -p: properties. NU5128 is expected and
    suppressed there (runtime packages ship runtimes/ natives with no lib/
    assemblies), as is CS2008 (no sources).

  Usage:
    Linux (core + the seven runtime packages):
        dotnet build build/CodeBrix.VideoProcessing.OpenCV5.Build.csproj -c Release
    Windows (.Wpf only, pinned to the Linux run's version):
        dotnet build build\CodeBrix.VideoProcessing.OpenCV5.Build.csproj -c Release -p:BuildVersion=1.x.y.z

  Family rule: ALL family packages publish at one version in one event.

  What ships inside every package: icon-codebrix-128.png, README.md,
  AGENT-README.txt and THIRD-PARTY-NOTICES.txt at the package root — the
  csproj <None Include> items for the core and .Wpf, the <files> element for
  each nuspec. AGENT-README.txt is the single consumer document for all nine
  packages; MAINTAINER-README.txt, EXTRAS-README.txt and README-INDEX.txt are
  NOT packed.

  Versioning: date-stamped, not SemVer. Every packable csproj carries the
  canonical version block. Because the value depends on the clock, two builds
  in the SAME UTC minute produce the SAME version — never publish two packages
  from within one minute.

STALE-DLL HAZARD (hit on 2026-07-07; the driver now guards against it)
----------------------------------------------------------------------
The packable csprojs (core and .Wpf) set GeneratePackageOnBuild=true. Known
NuGet quirk: with that property on, an explicit `dotnet pack` SKIPS the Build
dependency and packs whatever stale assembly sits in bin/Release — the first
driver run shipped a dll stamped with an older BuildVersion (and an older
commit hash) inside a newer core package. The driver's csproj-pack Exec lines
therefore pass -p:GeneratePackageOnBuild=false, which restores the normal
pack-depends-on-build flow. DO NOT remove that flag, and add it to any new
csproj-pack Exec added to the driver. The seven nuspec-shim runtime packages
contain no compiled assembly and are unaffected.

AFTER EVERY PACK RUN, verify the packed dll matches the package version and
the current HEAD (expect <version>+<git HEAD sha>):

    unzip -p nugets/Release/<ver>/CodeBrix.VideoProcessing.OpenCV5.ApacheLicenseForever.<ver>.nupkg \
      lib/net10.0/CodeBrix.VideoProcessing.OpenCV5.dll | strings -e l | grep -E '^1\.0\.[0-9]+\.[0-9]+\+'

(On the Windows .Wpf run, check the .Wpf dll the same way.)

The Windows .Wpf pack needs NO materialized native .dll. Three reasons:
(1) MaterializeNatives is non-Windows-gated, (2) the driver never references
the test projects, and (3) packing .Wpf only COMPILES the managed WPF assembly
against the managed core — OpenCvSharpExtern is a RUNTIME dependency, not a
build-time one, and the .Wpf package ships no natives. So the DLLs materialized
for the Windows test runs (under native_libraries/ and the tests/ staging and
bin folders) can be deleted with ZERO effect on the .Wpf pack; they are only
needed to RUN the tests.

PROVENANCE AND VENDORED SOURCES
===============================
Upstream: https://github.com/shimat/opencvsharp
Ported from: tag 5.0.0.20260703, commit d3bb1f3f3f8b906804c0dde6e8444fd12bd6d5b7
Elimination and vendoring decisions: 2026-07-07 (THIRD-PARTY-NOTICES.txt lists
the upstream packages deliberately not ported).
NEVER re-fetch from upstream or nuget.org; this repo is the single source of
truth going forward.

Namespaces were rewritten from OpenCvSharp* to CodeBrix.VideoProcessing.OpenCV5*
and every ported file carries `//was previously: <upstream-ns>;` on its
namespace line. Type names were NOT renamed — OpenCvSharpException,
OpenCvSafeHandle and the native library name "OpenCvSharpExtern" are retained.

Native binaries (native_libraries/runtimes/{rid}/native/, all .xz-compressed)
----------------------------------------------------------------------------
  WINDOWS + MACOS (win-x64, win-arm64, osx-x64, osx-arm64): the EXACT
    binaries upstream published (5.0.0.20260703; osx 5.0.0.20260704), captured
    once on 2026-07-07 per that day's decision: NEVER pull anything from the
    shimat/opencvsharp repo or nuget.org again. No fetch scripts. The upstream
    runtime nupkgs are additionally preserved offline.
  LINUX (linux-x64, linux-arm64, linux-riscv64): SELF-BUILT 2026-07-22 by
    tools/build_native_libraries/ — this SUPERSEDES the 2026-07-07 "never
    rebuilt" clause FOR THE LINUX RIDs ONLY. Portable manylinux static-linking
    model, built inside pinned manylinux containers from the vendored
    native_src/ wrapper source and the exact opencv/opencv_contrib revisions
    the upstream natives used. FFmpeg, Tesseract, Leptonica and the image
    codecs are statically linked; only universal system libraries (glibc,
    libstdc++, the GTK3 stack, libX11) remain dynamic. glibc ceiling 2.28
    (x64 and arm64) and 2.38 (riscv64). Motivation: the upstream linux-arm64
    binary was dynamically linked against Ubuntu 24.04 shared libraries
    (libtesseract.so.5, libjpeg.so.8, FFmpeg 6 sonames) and failed to load on
    every Raspberry Pi OS / non-Ubuntu distro; upstream shipped no riscv64
    binary at all; and self-building x64 keeps all three Linux RIDs on one
    provenance. Per-build provenance (pins, sha256, dynamic deps, glibc
    ceiling) is recorded in each build's build-info.txt.
    Validation: linux-x64 passed the FULL ported suite (1254 pass / 31 skip,
    2026-07-22); linux-arm64 verified by build gates and host checks, on-device
    suite run pending; linux-riscv64 verified by build gates only (dlopen
    smoke + forbidden-soname + dangling-symbol allowlist + glibc ceiling), no
    riscv64 hardware test yet.
  native_libraries/SHA256SUMS.txt records the SHA-256 of every RAW
    (uncompressed) binary; the pack step verifies these and fails loudly on
    any mismatch.
  NEVER commit the raw .so/.dll/.dylib files — the linux-x64 .so (131 MB) and
    the osx-x64 .dylib (127 MB) exceed GitHub's 100 MiB hard blob limit, which
    applies anywhere in history. .gitignore enforces this; leave it be.
  native_src/ holds the verbatim upstream C++ wrapper source, CMake, docker
    and CI-workflow files. tools/build_native_libraries/ consumes it for the
    Linux self-builds; it is reference-only for Windows/macOS.
  The win-x64 package also ships opencv_videoio_ffmpeg500_64.dll (OpenCV's
    FFmpeg-based videoio plugin). FFmpeg is LGPL — see THIRD-PARTY-NOTICES.txt.

CODING CONVENTIONS
==================
CodeBrix family rules that apply here:
  - TargetFramework net10.0 ONLY (exceptions below); no multi-targeting
  - File-scoped namespaces ONLY; usings at top (System.* first, alphabetical)
  - Ported files carry `//was previously: <upstream-ns>;` on the namespace line
  - Files added by CodeBrix that have no upstream counterpart say so in a
    comment under the namespace line ("Added for CodeBrix (not an upstream
    OpenCvSharp file): ...") — see Mat.CodeBrix.cs, NetExtensions.cs and
    Internal/NativeLibraryLoadDiagnostics.cs
  - No <ImplicitUsings>, no global usings
  - No <NoWarn>/project-level warning suppression; fix warnings at source
  - xUnit v3 for tests (no coverage collector in any of the three test
    projects); InternalsVisibleTo.cs grants internals to the matching .Tests
    project
  - <GenerateDocumentationFile> is ON; public members carry XML doc comments
  - Copyright string: upstream attribution prepended to the family clause
    ("Copyright 2008-2026 shimat and the OpenCvSharp contributors. Copyright
    (c) 2026 Jeremy Ellis and contributors.")
  - Canonical date-stamped versioning block in every packable csproj
  - Do NOT rename the analyzer diagnostic IDs OCVS001-OCVS004

DOCUMENTED PER-REPO EXCEPTIONS (do not "fix" these)
---------------------------------------------------
1. <Nullable>enable</Nullable> in ALL projects: the upstream code relies on
   nullable-reference-type annotations throughout its public API; stripping
   them would change observable signatures (the CodeBrix.Platform.OpenGL
   precedent). The `!` null-forgiveness operator also appears where upstream
   used it.
2. The Analyzers project targets netstandard2.0 with <LangVersion>12</> and
   pins AssemblyVersion 1.0.0.0: Roslyn analyzers are loaded in-process by the
   compiler and MUST target netstandard2.0; the LangVersion pin is required
   because netstandard2.0 defaults to C# 7.3. It is IsPackable=false — its DLL
   ships inside the core package under analyzers/dotnet/cs, wired by BOTH a
   ProjectReference with OutputItemType="Analyzer"
   ReferenceOutputAssembly="false" (so it runs during in-solution builds) and
   a <None Include ... PackagePath="analyzers/dotnet/cs"> item (so it is
   packaged). Both are required; neither alone is sufficient.
3. Scoped `#pragma warning disable 1591` blocks retained from upstream
   (~250 files, e.g. the Vec* struct operators): upstream deliberately
   suppressed doc-comment warnings for repetitive self-describing members.
   These are targeted source-level suppressions kept for upstream fidelity —
   the forbidden pattern is PROJECT-LEVEL <NoWarn>, which this repo does not
   use. Upstream's scoped CA-rule pragmas are likewise retained (they are
   inert without <AnalysisMode>recommended</>, which was dropped).
4. The .Wpf project (and .Wpf.Tests) target net10.0-windows with conditional
   SDK imports (Microsoft.NET.Sdk.WindowsDesktop on Windows, plain
   Microsoft.NET.Sdk elsewhere). On non-Windows hosts BitmapSourceConverter.cs
   and WriteableBitmapConverter.cs are excluded outright and
   GeneratePackageOnBuild is forced false, so the project compiles to an empty
   assembly and produces no package. net10.0-windows auto-defines WINDOWS even
   on Linux, so the `#if WINDOWS` guards alone cannot do this.
5. AllowUnsafeBlocks is ON (the binding uses pointers extensively).
6. The .Tests project references Xunit.StaFact with PrivateAssets=all. It
   ships only Windows-desktop TFM assets; leaking it transitively into the
   net10.0-windows .Wpf.Tests project made that project fail to build on
   non-Windows with NETSDK1073. .Wpf.Tests declares its own Windows-only
   StaFact reference.

NOTES
=====
  * NOT-IMPLEMENTED SURFACE. Five files throw NotImplementedException from
    public members, and this is documented for consumers in AGENT-README.txt:
      Modules/ml/TrainData.cs        - the constructor throws; the type is a
                                       stub, so StatModel.Train(TrainData,int)
                                       and StatModel.CalcError(...) throw too
      Modules/ml/SVM.cs              - TrainAuto(...) throws
      Modules/stitching/Stitcher.cs  - the pipeline-component properties
                                       (FeaturesFinder, FeaturesMatcher,
                                        MatchingMask, BundleAdjuster, Warper,
                                        ExposureCompensator, SeamFinder,
                                        Blender) throw; the high-level
                                        Stitch/EstimateTransform/
                                        ComposePanorama path works
      Modules/core/FileNodeIterator.cs - Reset() throws
    If any of these is implemented later, update AGENT-README.txt's
    MACHINE LEARNING, IMAGE STITCHING and WHAT THIS PACKAGE DOES NOT DO
    sections in the same change.
  * Mat.AsCols<T>() does NOT exist, although two analyzer diagnostic messages
    (OCVS003, OCVS004) suggest it alongside AsRows<T>(). Either add AsCols<T>()
    or reword those messages; do not document AsCols<T>() until it exists.
  * NativeLibraryLoadDiagnostics is deliberately NOT a NativeMethods partial:
    touching any NativeMethods member runs its static constructor, which
    attempts the native load, so the diagnostics must live where they can run
    without natives. tests/.../NativeLoadDiagnosticsTests.cs relies on that.
    Keep it standalone.
  * The default native error path installs no managed callback (it captures
    details natively on the calling thread), which keeps it NativeAOT- and
    trimming-friendly. Cv2.SetErrorHandler is the opt-in escape hatch; do not
    make it the default.
  * ExceptionHandler.ThrowPossibleException swallows native failures once the
    process has begun shutting down ("terminated TLS container" and friends).
    That is deliberate: a video worker thread reaching native OpenCV after its
    TLS state is torn down cannot recover, and surfacing it would turn an
    orderly exit into a fatal unhandled exception.
  * nugets/Release/ holds previous pack outputs; it is build output, not
    source.
================================================================================
