================================================================================
AGENT-README: CodeBrix.VideoProcessing.OpenCV5
A Comprehensive Guide for AI Coding Agents
================================================================================

OVERVIEW
--------
CodeBrix.VideoProcessing.OpenCV5 is a .NET binding for OpenCV 5 — image
processing, video capture and analysis, camera calibration, object detection,
machine learning, and the OpenCV contrib extra modules — for .NET 10.0+.

It is a fork/port of the OpenCvSharp project's OpenCvSharp5 package family
(https://github.com/shimat/opencvsharp, tag 5.0.0.20260703). All namespaces
use "CodeBrix.VideoProcessing.OpenCV5" instead of "OpenCvSharp". Do NOT use
OpenCvSharp namespaces. Type names were NOT renamed — OpenCvSharpException,
OpenCvSafeHandle, and the native library name "OpenCvSharpExtern" are
retained from upstream.

The repo produces EIGHT NuGet packages: the managed core (with bundled
Roslyn analyzers), a WPF extensions package (Windows-only), and six native
runtime packages (one per OS/architecture pair). The native binaries are
vendored in this repo xz-compressed; they are the exact artifacts upstream
published (never rebuilt, never re-fetched — see NATIVE LIBRARIES below).

INSTALLATION
------------
NuGet Package: CodeBrix.VideoProcessing.OpenCV5.ApacheLicenseForever
Dependencies: none (the managed core has no NuGet dependencies)

    dotnet add package CodeBrix.VideoProcessing.OpenCV5.ApacheLicenseForever

A native runtime package matching the target platform is ALSO required:

    CodeBrix.VideoProcessing.OpenCV5.WindowsX64.ApacheLicenseForever
    CodeBrix.VideoProcessing.OpenCV5.WindowsArm64.ApacheLicenseForever
    CodeBrix.VideoProcessing.OpenCV5.LinuxX64.ApacheLicenseForever
    CodeBrix.VideoProcessing.OpenCV5.LinuxArm64.ApacheLicenseForever
    CodeBrix.VideoProcessing.OpenCV5.MacOSX64.ApacheLicenseForever
    CodeBrix.VideoProcessing.OpenCV5.MacOSArm64.ApacheLicenseForever

For WPF applications (Mat -> BitmapSource/WriteableBitmap conversion):

    CodeBrix.VideoProcessing.OpenCV5.Wpf.ApacheLicenseForever

IMPORTANT: The NuGet package names carry the .ApacheLicenseForever suffix;
the namespaces do NOT (primary namespace: CodeBrix.VideoProcessing.OpenCV5).

Requirements: .NET 10.0 or higher
License: Apache License 2.0

KEY NAMESPACES
--------------
    using CodeBrix.VideoProcessing.OpenCV5;            // Cv2, Mat, Scalar, Size, ...
    using CodeBrix.VideoProcessing.OpenCV5.Dnn;        // Deep neural network module
    using CodeBrix.VideoProcessing.OpenCV5.ML;         // Machine learning module
    using CodeBrix.VideoProcessing.OpenCV5.Flann;      // FLANN nearest-neighbor search
    using CodeBrix.VideoProcessing.OpenCV5.Aruco;      // ArUco marker detection
    using CodeBrix.VideoProcessing.OpenCV5.Face;       // contrib: face recognition
    using CodeBrix.VideoProcessing.OpenCV5.Tracking;   // contrib: object tracking
    using CodeBrix.VideoProcessing.OpenCV5.XImgProc;   // contrib: extended image proc
    using CodeBrix.VideoProcessing.OpenCV5.XFeatures2D;// contrib: extra 2D features
    using CodeBrix.VideoProcessing.OpenCV5.XPhoto;     // contrib: extended photo
    using CodeBrix.VideoProcessing.OpenCV5.ImgHash;    // contrib: image hashing
    using CodeBrix.VideoProcessing.OpenCV5.Quality;    // contrib: quality metrics
    using CodeBrix.VideoProcessing.OpenCV5.Saliency;   // contrib: saliency detection
    using CodeBrix.VideoProcessing.OpenCV5.Text;       // contrib: text detection
    using CodeBrix.VideoProcessing.OpenCV5.LineDescriptor; // contrib: line descriptors
    using CodeBrix.VideoProcessing.OpenCV5.DnnSuperres;// contrib: DNN super-resolution
    using CodeBrix.VideoProcessing.OpenCV5.Detail;     // stitching pipeline details
    using CodeBrix.VideoProcessing.OpenCV5.Internal;   // P/Invoke layer (do not use
                                                       // from application code)
    using CodeBrix.VideoProcessing.OpenCV5.Wpf;        // WPF converters (own package)

CORE API REFERENCE
------------------
The API surface mirrors upstream OpenCvSharp5 exactly (only namespaces
changed), so upstream OpenCvSharp documentation and samples apply directly.

  Cv2 (static class)
    The main OpenCV function surface: Cv2.ImRead, Cv2.ImWrite, Cv2.Resize,
    Cv2.CvtColor, Cv2.Canny, Cv2.GaussianBlur, Cv2.FindContours,
    Cv2.MatchTemplate, Cv2.SolvePnP, Cv2.PutText, and hundreds more, split
    across partial-class files under src/.../Cv2/ (one file per module).

  Mat / Mat<T> / UMat / SparseMat
    The n-dimensional dense (and sparse) array types. Mat is IDisposable and
    wraps native memory — ALWAYS dispose (use `using`). Mat.Row/Mat.Col
    return new Mat instances that must also be disposed (analyzer OCVS004
    reports violations).

  VideoCapture / VideoWriter
    Camera / video-file capture and encoding (videoio module).

  InputArray / OutputArray / InputOutputArray
    Implicit-conversion adapter types used by most Cv2 methods.

  OpenCvSharpException / OpenCVException
    Error model: OpenCVException carries the native error status, function,
    and file/line; OpenCvSharpException is the managed-side exception type.

  Struct types: Point, Point2f/2d, Size, Rect, Scalar, Vec2b..Vec6d, Range,
    RotatedRect, KeyPoint, DMatch, MatType, TermCriteria, etc.

  Bundled Roslyn analyzers (ship inside the core package under
  analyzers/dotnet/cs; project src/CodeBrix.VideoProcessing.OpenCV5.Analyzers):
    OCVS001  Mat.At<T>() inside a loop (RowAtAnalyzer)
    OCVS002  Mat property re-evaluated in a loop condition
    OCVS003  Mat.Row/Col called inside a loop body
    OCVS004  Mat.Row/Col result never disposed
  Do NOT rename these diagnostic IDs.

  WPF (CodeBrix.VideoProcessing.OpenCV5.Wpf package):
    BitmapSourceConverter.ToBitmapSource(Mat) / ToMat(BitmapSource, Mat)
    WriteableBitmapConverter.ToWriteableBitmap(Mat) / ToMat(...)

NATIVE LIBRARIES
----------------
The managed core P/Invokes a single native library named "OpenCvSharpExtern"
(libOpenCvSharpExtern.so / OpenCvSharpExtern.dll / libOpenCvSharpExtern.dylib)
that statically links OpenCV 5 + contrib. The exact binaries upstream
published (5.0.0.20260703; osx 5.0.0.20260704) are committed in this repo
under native_libraries/runtimes/{rid}/native/ with an .xz suffix
(xz-compressed — the raw linux-x64 .so is 131 MB and the osx-x64 .dylib is
127 MB, over GitHub's 100 MiB hard blob limit; NEVER commit the raw files —
.gitignore enforces this).

  - native_libraries/SHA256SUMS.txt records the SHA-256 of every RAW
    (uncompressed) binary; the pack step verifies these and fails loudly on
    any mismatch.
  - DECIDED 2026-07-07: one-time copy. NEVER pull anything from the
    shimat/opencvsharp repo or nuget.org again. No fetch scripts. The
    upstream runtime nupkgs are additionally preserved offline.
  - native_src/ holds the verbatim upstream C++ wrapper source and build
    scripts so natives COULD be self-built later; nothing in this repo
    builds them today.
  - The win-x64 package also ships opencv_videoio_ffmpeg500_64.dll (OpenCV's
    FFmpeg-based videoio plugin). FFmpeg is LGPL — see THIRD-PARTY-NOTICES.txt.

PACKAGING / BUILD DRIVER
------------------------
Mirrors the CodeBrix.Platform pack-only driver pattern:

  build/CodeBrix.VideoProcessing.OpenCV5.Build.csproj
    - computes the canonical date-stamped $(BuildVersion) ONCE per run
      (override with -p:BuildVersion=1.x.y.z for version-locked multi-machine
      sets — the .Wpf package must be packed on a Windows box with the pinned
      version, same pattern as CodeBrix.Platform's .MacOS package)
    - MaterializeNatives target: xz -dkf every native_libraries/**/*.xz in
      place, then verifies SHA256SUMS.txt and FAILS on mismatch
    - packs the 6 runtime packages from build/nuget/*.nuspec via the
      build/nuget-pack-shim shim project
    - packs the core (and, on Windows, the .Wpf) package from the csproj
    - output: nugets/Release/{version}/

  Family rule: ALL family packages publish at one version in one event.

CODING CONVENTIONS (CodeBrix family)
------------------------------------
- TargetFramework net10.0 ONLY (exceptions below); no multi-targeting
- File-scoped namespaces ONLY; usings at top (System.* first, alphabetical)
- Ported files carry `//was previously: <upstream-ns>;` on the namespace line
- No <ImplicitUsings>, no global usings
- No <NoWarn>/project-level warning suppression; fix warnings at source
- xUnit v3 + coverlet for tests; InternalsVisibleTo.cs grants internals to
  the matching .Tests project
- <GenerateDocumentationFile> is ON; public members carry XML doc comments
- Copyright string: upstream attribution prepended to the family clause
  ("Copyright 2008-2026 shimat and the OpenCvSharp contributors. Copyright
  (c) 2026 Jeremy Ellis and contributors.")
- Canonical date-stamped versioning block in every packable csproj

DOCUMENTED PER-REPO EXCEPTIONS (do not "fix" these)
---------------------------------------------------
1. <Nullable>enable</Nullable> in ALL projects: the upstream code relies on
   nullable-reference-type annotations throughout its public API; stripping
   them would change observable signatures (CodeBrix.Platform.OpenGL
   precedent). The `!` null-forgiveness operator also appears where upstream
   used it.
2. The Analyzers project targets netstandard2.0 with <LangVersion>12</> and
   pins AssemblyVersion 1.0.0.0: Roslyn analyzers are loaded in-process by
   the compiler and MUST target netstandard2.0; the LangVersion pin is
   required because netstandard2.0 defaults to C# 7.3. It is IsPackable=false
   — its DLL ships inside the core package under analyzers/dotnet/cs.
3. Scoped `#pragma warning disable 1591` blocks retained from upstream
   (~250 files, e.g. the Vec* struct operators): upstream deliberately
   suppressed doc-comment warnings for repetitive self-describing members.
   These are targeted source-level suppressions kept for upstream fidelity —
   the forbidden pattern is PROJECT-LEVEL <NoWarn>, which this repo does not
   use. Upstream's scoped CA-rule pragmas are likewise retained (they are
   inert without <AnalysisMode>recommended</>, which was dropped).
4. The .Wpf project (and .Wpf.Tests) target net10.0-windows with conditional
   SDK imports: on non-Windows hosts they compile to empty assemblies so the
   solution builds everywhere; the REAL WPF assembly/package is produced on
   Windows only.
5. AllowUnsafeBlocks is ON (the binding uses pointers extensively).

ARCHITECTURE
------------
src/CodeBrix.VideoProcessing.OpenCV5/    the managed core
  Cv2/            partial Cv2 class, one file per OpenCV module
  Fundamentals/   safe handles, CvObject/CvPtrObject bases, exceptions
  Internal/       P/Invoke layer (NativeMethods partials, vectors, utils)
  Modules/        one folder per OpenCV module (core, imgproc, dnn, ml, ...)
src/CodeBrix.VideoProcessing.OpenCV5.Analyzers/   Roslyn analyzers (OCVS001-004)
src/CodeBrix.VideoProcessing.OpenCV5.Wpf/         WPF converters (Windows-only)
native_libraries/  xz-compressed vendored natives + SHA256SUMS.txt
native_src/        verbatim upstream C++/CMake/docker sources (reference only)
build/             pack driver, 6 runtime nuspecs, pack shim

TESTING
-------
tests/CodeBrix.VideoProcessing.OpenCV5.Tests/  the ported upstream suite
  (xUnit v3, kept as-is per 2026-07-07 decision — xUnit Assert style, NOT
  SilverAssertions), one folder per module, _data/ holds test images.
  Tests that exercise native code REQUIRE the linux-x64 native library to be
  materialized and locatable: run the MaterializeNatives target first, then
  either copy the raw .so next to the test binary or set LD_LIBRARY_PATH to
  native_libraries/runtimes/linux-x64/native/.
  Some tests download DNN models from the network on first run (FileDownloader,
  guarded by ExplicitFact/ExplicitTheory attributes for the heavier cases).
tests/CodeBrix.VideoProcessing.OpenCV5.Analyzers.Tests/  analyzer unit tests
  (Roslyn testing harness; no native library needed).
tests/CodeBrix.VideoProcessing.OpenCV5.Wpf.Tests/  Windows-only (empty
  assembly on Linux, like the .Wpf library itself).

    dotnet test CodeBrix.VideoProcessing.OpenCV5.slnx

UPSTREAM / PROVENANCE
---------------------
Upstream: https://github.com/shimat/opencvsharp
Ported from: tag 5.0.0.20260703, commit d3bb1f3f3f8b906804c0dde6e8444fd12bd6d5b7
Elimination and vendoring decisions: 2026-07-07 (see THIRD-PARTY-NOTICES.txt
for the list of upstream packages deliberately not ported).
NEVER re-fetch from upstream or nuget.org; this repo is the single source of
truth going forward.
================================================================================
