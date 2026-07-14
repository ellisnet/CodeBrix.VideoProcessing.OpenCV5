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
    Managed-array interop (see also USING THE DNN MODULE below):
      Mat.FromPixelData(rows, cols, type, Array data[, step])   - wrap/copy a
        managed array into a Mat (N-dim `sizes` overloads also exist); this
        is the supported replacement for the deprecated pixel-data ctor.
      mat.GetArray<T>(out T[]) / GetRectangularArray<T>(out T[,])  - typed
        copies out of a TWO-dimensional Mat (they size the result from
        Rows x Cols, which are -1 when Dims > 2 — so they cannot read DNN
        output tensors).
      mat.ToArray<T>()   - CodeBrix addition (Mat.CodeBrix.cs): copies a
        continuous Mat of ANY dimensionality out in row-major order; T is
        the per-channel primitive (float for CV_32F...) or a whole-element
        Vec struct. THE way to read N-dimensional DNN outputs.

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

  Dnn module (CodeBrix.VideoProcessing.OpenCV5.Dnn):
    Cv2.Dnn.ReadNetFrom{Onnx,Tensorflow,Caffe,Darknet,TFLite,...} -> Net
    Cv2.Dnn.BlobFromImage(...) -> 4D input blob; net.SetInput(blob);
    net.Forward([name]) -> Mat
    net.ForwardAll(params string[] names) -> Mat[]   - CodeBrix addition
      (NetExtensions.cs): reads MULTIPLE named layer outputs reliably; see
      "The multi-output Forward trap" in USING THE DNN MODULE below.

  WPF (CodeBrix.VideoProcessing.OpenCV5.Wpf package):
    BitmapSourceConverter.ToBitmapSource(Mat) / ToMat(BitmapSource, Mat)
    WriteableBitmapConverter.ToWriteableBitmap(Mat) / ToMat(...)

USING THE DNN MODULE (TFLITE MODELS, MULTI-OUTPUT NETS, TENSOR ACCESS)
----------------------------------------------------------------------
Lessons learned building the WebcamPainter sample (CodeBrix.Samples repo),
which runs Google MediaPipe hand-tracking TFLite models through this
library's DNN module in real time. That sample is the reference for the
whole recipe (webcam frames -> palm detection -> hand landmarks -> gesture
classification); the pitfalls and patterns below are general.

TFLite import - what works:
  The vendored natives are built WITH the TFLite importer (flatbuffers), so
  Cv2.Dnn.ReadNetFromTFLite(path | byte[] | stream) works out of the box.
  OpenCV's TFLite OPERATOR coverage is partial, though, and unsupported
  operators throw at LOAD time ("Unsupported operator type XYZ in function
  'populateNet'"). Empirically, for the MediaPipe model family (extracted
  from Google's .task bundles - which are just ZIP archives of .tflite
  files):
    LOADS AND RUNS: hand_detector.tflite (palm detection, 192x192 in,
      2016-anchor SSD out), hand_landmarks_detector.tflite (224x224 in,
      21 landmarks out), pose_landmarks_detector.tflite
    FAILS TO LOAD:  gesture_embedder.tflite (GATHER operator),
      pose_detector.tflite (DENSIFY operator)
  Consequence: the canned MediaPipe gesture classifier and the BlazePose
  pipeline cannot run here today; hand landmarks CAN, and simple gestures
  (open palm, fist, pointing) classify perfectly well geometrically from
  the 21 landmarks - see the WebcamPainter sample's OpenPalmClassifier.
  Implementing GATHER/DENSIFY (likely upstream) would unlock the rest.

The multi-output Forward trap (and net.ForwardAll):
  Net.Forward(outputBlobs, outBlobNames) - the multi-output overload -
  requires the requested names to exactly match the net's REGISTERED
  unconnected outputs (native check "outnames.size() == noutputs"). The
  TFLite importer registers only ONE output, so for multi-output TFLite
  models that overload always throws. MediaPipe's palm detector is the
  classic case: box regressors in "Identity" [1x2016x18] and anchor scores
  in "Identity_1" [1x2016x1]. Read such models with the CodeBrix extension:
      net.SetInput(blob);
      var outputs = net.ForwardAll("Identity", "Identity_1");
  ForwardAll issues sequential single-name Forward calls; with an unchanged
  input, OpenCV reuses the already-computed layers, so the extra outputs
  are close to free (measured: both palm-detector outputs in ~12 ms warm on
  a desktop CPU, essentially the single-output cost). Dispose every
  returned Mat. To DISCOVER a model's output names, probe candidate names
  with single Forward(name) calls ("Identity", "Identity_1", ...) or list
  net.GetLayerNames() / net.GetUnconnectedOutLayersNames().

Reading output tensors (N-dimensional Mats):
  DNN outputs are usually N-dimensional (e.g. [1 x 2016 x 18], Dims = 3).
  GetArray<T> CANNOT read them (it sizes from Rows x Cols, both -1 when
  Dims > 2). Use the CodeBrix helper:
      float[] scores = outputMat.ToArray<float>();   //row-major copy
  and index it manually (anchor a, field k of 18: scores[a * 18 + k]).

Feeding frames in (managed pixels -> blob):
  Wrap or copy managed pixels with Mat.FromPixelData - e.g. a webcam
  frame's tightly packed BGRA bytes:
      using var bgra = Mat.FromPixelData(height, width, MatType.CV_8UC4, pixelBytes);
      using var bgr = new Mat();
      Cv2.CvtColor(bgra, bgr, ColorConversionCodes.BGRA2BGR);
      using var blob = Cv2.Dnn.BlobFromImage(bgr, 1.0 / 255, new Size(192, 192),
          new Scalar(0, 0, 0), swapRB: true, crop: false);
      net.SetInput(blob);
  BlobFromImage accepts 1- and 3-channel inputs (not 4-channel) - hence the
  BGRA2BGR conversion. swapRB: true feeds RGB, which the MediaPipe models
  (and most TFLite models) expect. Letterbox (aspect-preserving pad) before
  BlobFromImage when the model assumes it - MediaPipe's detectors do; plain
  BlobFromImage stretching degrades their accuracy noticeably.

Model-output activation gotcha (cost a real debugging session):
  Do not assume every "score" output is a logit. In the MediaPipe hand
  bundle, the palm DETECTOR's anchor scores ARE logits (apply sigmoid), but
  the LANDMARK model's hand-presence output is ALREADY a probability
  (~1.0 with a hand, ~0.002 on a blank crop) - applying sigmoid squashes it
  uselessly toward 0.5-0.73. When wiring a new model, probe outputs with a
  real positive AND a blank/negative input and check which interpretation
  separates them.

Real-time pipeline shape (see WebcamPainter.Vision for the full version):
  One worker thread owns the Net objects (they are not thread-safe); frames
  arrive via a single latest-wins pending slot (submitting overwrites the
  previous pending frame), so slow inference drops stale frames instead of
  queueing. Reuse Mats across frames (allocate on size change only). The
  bundled analyzers (OCVS001-004) flag the per-frame P/Invoke and disposal
  mistakes that creep into exactly this kind of loop.

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

  STALE-DLL HAZARD (hit on 2026-07-07; driver now guards against it):
    The packable csprojs (core and .Wpf) set GeneratePackageOnBuild=true.
    Known NuGet quirk: with that property on, an explicit `dotnet pack`
    SKIPS the Build dependency and packs whatever stale assembly sits in
    bin/Release — the first driver run shipped a dll stamped 1.0.188.908
    (and an older commit hash) inside the 1.0.189.394 core package. The
    driver's csproj-pack Exec lines therefore pass
    -p:GeneratePackageOnBuild=false, which restores the normal
    pack-depends-on-build flow; do NOT remove that flag, and add it to any
    new csproj-pack Exec added to the driver. The six nuspec-shim runtime
    packages contain no compiled assembly and are unaffected.
    AFTER EVERY PACK RUN, verify the packed dll matches the package version
    and current HEAD (expect <version>+<git HEAD sha>):
        unzip -p nugets/Release/<ver>/CodeBrix.VideoProcessing.OpenCV5.ApacheLicenseForever.<ver>.nupkg \
          lib/net10.0/CodeBrix.VideoProcessing.OpenCV5.dll | strings -e l | grep -E '^1\.0\.[0-9]+\.[0-9]+\+'
    (On the Windows .Wpf run, check the .Wpf dll the same way.)

  Windows .Wpf pack does NOT need any materialized native .dll: the Windows run
      dotnet build build\CodeBrix.VideoProcessing.OpenCV5.Build.csproj -c Release -p:BuildVersion=1.x.y.z
  packs ONLY the .Wpf package, and needs no OpenCvSharpExtern.dll (or any raw
  native) to do so. Three reasons: (1) MaterializeNatives is skipped on Windows
  (it is non-Windows-gated), (2) the build driver never references the test
  projects, and (3) packing .Wpf only COMPILES the managed WPF assembly against
  the managed core — OpenCvSharpExtern is a RUNTIME dependency, not a build-time
  one, and the .Wpf package ships no natives. So the DLLs materialized for the
  Windows test runs (see RUNNING THE TESTS ON WINDOWS above) — under
  native_libraries/ and the tests/ staging/bin folders — can be deleted with
  ZERO effect on the .Wpf pack. (They are only needed to RUN the tests.)

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

RUNNING THE TESTS ON WINDOWS (native setup — REQUIRED)
------------------------------------------------------
On Windows, the native OpenCvSharpExtern library is NOT materialized or copied
to the test output automatically. Without the steps below, every test that
touches native code fails at first `new Mat(...)` with:

    System.TypeInitializationException: The type initializer for
    '...Internal.NativeMethods' threw an exception.
      ---> System.DllNotFoundException: Unable to load DLL
      'OpenCvSharpExtern' or one of its dependencies (0x8007007E)

WHY IT DOES NOT "just work" on Windows (three separate reasons):
  1. The pack driver's MaterializeNatives target (which runs `xz -dkf` to
     decompress the vendored natives) is gated Condition="'$(OS)' != 'Windows_NT'"
     in build/CodeBrix.VideoProcessing.OpenCV5.Build.csproj — it only runs on
     Linux/macOS. On Windows the .dll.xz files are never decompressed.
  2. The .Tests project copies raw DLLs to its output only from a `dll/`
     subfolder (the `<None Update="dll\**\*.dll">` rule in the csproj), and that
     folder does NOT exist in the repo — it is deliberately untracked (the raw
     natives exceed GitHub's 100 MiB blob limit; see native_libraries/.gitignore).
  3. The .Wpf.Tests project has NO such copy rule at all, so even a populated
     `dll/` folder in the .Tests project does not reach the .Wpf.Tests output.

The natives you need are vendored, xz-compressed, at:
    native_libraries/runtimes/win-x64/native/OpenCvSharpExtern.dll.xz
    native_libraries/runtimes/win-x64/native/opencv_videoio_ffmpeg500_64.dll.xz
(win-arm64 has its own OpenCvSharpExtern.dll.xz; use it instead on ARM64.)
`xz` ships with Git for Windows at /mingw64/bin/xz (i.e. on PATH in Git Bash).

SETUP (Git Bash; from the repo root). Step A decompresses, step B verifies the
bytes against the committed manifest, step C stages them so the tests find them:

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
  A direct copy into bin/ (step C) is wiped by a full Rebuild/Clean. To make the
  ported .Tests suite self-sufficient, instead create the tracked-by-csproj
  staging folder and drop the DLLs there — the existing `dll\**\*.dll` copy rule
  then re-stages them on every build:
      mkdir -p tests/CodeBrix.VideoProcessing.OpenCV5.Tests/dll
      cp "$SRC/OpenCvSharpExtern.dll" "$SRC/opencv_videoio_ffmpeg500_64.dll" \
         tests/CodeBrix.VideoProcessing.OpenCV5.Tests/dll/
  The .Wpf.Tests project has no such rule, so its bin/ copy from step C must be
  redone after any Rebuild (or add an equivalent copy rule to its csproj).

DO NOT COMMIT the decompressed .dll files or the `dll/` staging folder contents —
they are large native binaries kept out of git on purpose (see reason 2 above).
Verified 2026-07-07: with the DLLs staged as above, all three .Tests projects
pass on Windows (net10.0 / net10.0-windows, x64).

UPSTREAM / PROVENANCE
---------------------
Upstream: https://github.com/shimat/opencvsharp
Ported from: tag 5.0.0.20260703, commit d3bb1f3f3f8b906804c0dde6e8444fd12bd6d5b7
Elimination and vendoring decisions: 2026-07-07 (see THIRD-PARTY-NOTICES.txt
for the list of upstream packages deliberately not ported).
NEVER re-fetch from upstream or nuget.org; this repo is the single source of
truth going forward.
================================================================================
