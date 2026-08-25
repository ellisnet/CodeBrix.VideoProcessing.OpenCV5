================================================================================
AGENT-README: CodeBrix.VideoProcessing.OpenCV5
A Guide for AI Coding Agents — CONSUMING the CodeBrix.VideoProcessing.OpenCV5
NuGet package family
================================================================================

OVERVIEW
========
CodeBrix.VideoProcessing.OpenCV5 is a .NET binding for OpenCV 5: image
processing, image and video I/O, feature detection and matching, camera
calibration and 3D geometry, object detection, machine learning, motion
analysis and tracking, computational photography, deep-neural-network
inference, and the OpenCV contrib extra modules. Target framework: .NET 10
or later.

The family is nine NuGet packages: one managed core assembly (which also
carries four bundled Roslyn analyzers), one WPF interop package, and seven
native runtime packages — one per OS/CPU pair. The managed core has no
managed dependencies; it P/Invokes a single native library named
"OpenCvSharpExtern" that statically links OpenCV 5 plus opencv_contrib.

Provenance: this is a port of the OpenCvSharp project's OpenCvSharp5 package
family (https://github.com/shimat/opencvsharp, tag 5.0.0.20260703). Every
namespace root is "CodeBrix.VideoProcessing.OpenCV5" instead of "OpenCvSharp"
— do NOT write OpenCvSharp namespaces or reference OpenCvSharp packages.
Type names were NOT renamed, so a handful of upstream-flavoured identifiers
survive verbatim: OpenCvSharpException, OpenCvSafeHandle, and the native
library name "OpenCvSharpExtern". Upstream OpenCvSharp5 samples therefore
port by changing usings only.

INSTALLATION
============
The nine package ids (every id carries the .ApacheLicenseForever suffix; the
NAMESPACES never do):

  Managed core (required, always):
    CodeBrix.VideoProcessing.OpenCV5.ApacheLicenseForever

  Native runtime packages (at least one required — see below):
    CodeBrix.VideoProcessing.OpenCV5.WindowsX64.ApacheLicenseForever
    CodeBrix.VideoProcessing.OpenCV5.WindowsArm64.ApacheLicenseForever
    CodeBrix.VideoProcessing.OpenCV5.LinuxX64.ApacheLicenseForever
    CodeBrix.VideoProcessing.OpenCV5.LinuxArm64.ApacheLicenseForever
    CodeBrix.VideoProcessing.OpenCV5.LinuxRiscv64.ApacheLicenseForever
    CodeBrix.VideoProcessing.OpenCV5.MacOSX64.ApacheLicenseForever
    CodeBrix.VideoProcessing.OpenCV5.MacOSArm64.ApacheLicenseForever

  WPF interop (optional, Windows-only apps):
    CodeBrix.VideoProcessing.OpenCV5.Wpf.ApacheLicenseForever

License for all nine: Apache-2.0.

NuGet dependencies
------------------
  * The managed core package has NO NuGet dependencies at all.
  * Each native runtime package has NO dependencies either — in particular it
    does NOT depend on the managed core, and it ships no MSBuild props/targets.
    Its entire payload is the native binary at runtimes/<rid>/native/ plus
    documentation files. That is why the core and the native package must BOTH
    be referenced explicitly: neither pulls the other in.
  * The .Wpf package depends on the managed core package and on
    System.Drawing.Common.

WHICH PACKAGES DO I REFERENCE
-----------------------------
Rule 1 — always reference the managed core. It is the only package that
contains a lib/ assembly, and it is what your code compiles against.

Rule 2 — reference the native runtime package(s) for every platform the app
must RUN on:

  * Portable / RID-less app (plain `dotnet build`, `dotnet run`, or a
    framework-dependent publish with no -r): reference EVERY platform you
    intend to support — commonly all seven. The native binaries are large, so
    trim the list to the platforms you actually ship to.
  * RID-specific publish (`dotnet publish -r linux-x64`, self-contained or
    not): the matching RID package is the only one whose payload is deployed.
    Referencing just that one keeps restore small; referencing all seven is
    also fine (the non-matching ones contribute nothing to the publish output).

  RID mapping:
    WindowsX64   -> win-x64        LinuxX64     -> linux-x64
    WindowsArm64 -> win-arm64      LinuxArm64   -> linux-arm64
    MacOSX64     -> osx-x64        LinuxRiscv64 -> linux-riscv64
    MacOSArm64   -> osx-arm64

Rule 3 — reference the .Wpf package only from a net10.0-windows WPF app.

    dotnet add package CodeBrix.VideoProcessing.OpenCV5.ApacheLicenseForever
    dotnet add package CodeBrix.VideoProcessing.OpenCV5.LinuxX64.ApacheLicenseForever
    dotnet add package CodeBrix.VideoProcessing.OpenCV5.WindowsX64.ApacheLicenseForever

HOW THE RIGHT NATIVE BINARY IS SELECTED
---------------------------------------
Each native package places exactly one file (two on win-x64) at
runtimes/<rid>/native/ inside the nupkg:

    runtimes/win-x64/native/OpenCvSharpExtern.dll
    runtimes/win-x64/native/opencv_videoio_ffmpeg500_64.dll
    runtimes/win-arm64/native/OpenCvSharpExtern.dll
    runtimes/linux-x64/native/libOpenCvSharpExtern.so
    runtimes/linux-arm64/native/libOpenCvSharpExtern.so
    runtimes/linux-riscv64/native/libOpenCvSharpExtern.so
    runtimes/osx-x64/native/libOpenCvSharpExtern.dylib
    runtimes/osx-arm64/native/libOpenCvSharpExtern.dylib

There is no MSBuild logic and no DllImportResolver: resolution is the .NET
runtime's ordinary native-library probing over that runtimes/<rid>/native/
layout. The SDK records the assets in the app's .deps.json, the host adds the
directory matching the running RID to NATIVE_DLL_SEARCH_DIRECTORIES, and the
first P/Invoke loads the library from there. The binding declares
[assembly: DefaultDllImportSearchPaths(DllImportSearchPath.LegacyBehavior)],
so on Windows the application directory and PATH are searched as well.

If the load fails, the package tells you exactly what went wrong — see
NATIVE LIBRARY LOADING AND DIAGNOSTICS below.

LINUX SYSTEM PREREQUISITES
--------------------------
The Linux binaries are portable manylinux-model builds: FFmpeg, libjpeg-turbo,
libpng, libtiff, libwebp, zlib, Tesseract and Leptonica are STATICALLY linked
inside libOpenCvSharpExtern.so. Only universal system libraries stay dynamic.
The complete dynamic-dependency list of the shipped linux-x64/linux-arm64
binaries is:

    libfreetype.so.6      libharfbuzz.so.0      libgtk-3.so.0
    libgdk-3.so.0         libpangocairo-1.0.so.0 libpango-1.0.so.0
    libatk-1.0.so.0       libcairo-gobject.so.2 libcairo.so.2
    libgdk_pixbuf-2.0.so.0 libgio-2.0.so.0      libgobject-2.0.so.0
    libglib-2.0.so.0      libm.so.6             libdrm.so.2
    libatomic.so.1        libX11.so.6           librt.so.1
    libpthread.so.0       libdl.so.2            libstdc++.so.6
    libgcc_s.so.1         libc.so.6             (plus the ELF interpreter)

(linux-riscv64 has the same list minus librt/libpthread/libdl.)

On a Debian-based distribution every one of those comes from the GTK-3 runtime
and Xlib, which a desktop image already has. On a headless/container image
install them explicitly:

    sudo apt-get install -y libgtk-3-0 libx11-6

libgtk-3-0 pulls in gdk, pango, cairo, gdk-pixbuf, glib, freetype and
harfbuzz; libdrm2, libatomic1 and libstdc++6 are already present on any host
that can run .NET. On distributions that completed the 64-bit time_t
transition the GTK package is named libgtk-3-0t64 — use that name there.

glibc floor: the linux-x64 and linux-arm64 binaries need glibc 2.28 or newer
(Debian 10+, Ubuntu 20.04+, RHEL 8+, every 64-bit Raspberry Pi OS release).
The linux-riscv64 binary needs glibc 2.38 or newer (Ubuntu 24.04+, Debian 13+)
and is usable today with experimental riscv64 .NET SDK builds.

WINDOWS AND MACOS NOTES
-----------------------
  * win-x64 additionally ships opencv_videoio_ffmpeg500_64.dll, OpenCV's
    FFmpeg-based videoio plugin. It is loaded on demand by VideoCapture /
    VideoWriter and must sit beside OpenCvSharpExtern.dll — the package puts
    it there. FFmpeg is LGPL; see THIRD-PARTY-NOTICES.txt in the package.
  * The macOS and Windows binaries have no extra system prerequisites.
  * The .Wpf package targets net10.0-windows and is meaningful only on
    Windows.

KEY NAMESPACES / USINGS
=======================
    using CodeBrix.VideoProcessing.OpenCV5;             // Cv2, Mat, Scalar,
                                                        // Size, Rect, Point,
                                                        // VideoCapture, ...
    using CodeBrix.VideoProcessing.OpenCV5.Dnn;         // Net, Model, blobs
    using CodeBrix.VideoProcessing.OpenCV5.ML;          // SVM, RTrees, KNearest
    using CodeBrix.VideoProcessing.OpenCV5.Flann;       // FLANN index params
    using CodeBrix.VideoProcessing.OpenCV5.Aruco;       // ArUco / ChArUco
    using CodeBrix.VideoProcessing.OpenCV5.Face;        // face recognition
    using CodeBrix.VideoProcessing.OpenCV5.Tracking;    // TrackerCSRT/KCF
    using CodeBrix.VideoProcessing.OpenCV5.Text;        // OCR / text detection
    using CodeBrix.VideoProcessing.OpenCV5.XImgProc;    // extended imgproc
    using CodeBrix.VideoProcessing.OpenCV5.XFeatures2D; // SURF, BRISK, KAZE...
    using CodeBrix.VideoProcessing.OpenCV5.XPhoto;      // white balance, ...
    using CodeBrix.VideoProcessing.OpenCV5.ImgHash;     // perceptual hashes
    using CodeBrix.VideoProcessing.OpenCV5.Quality;     // PSNR/SSIM/BRISQUE
    using CodeBrix.VideoProcessing.OpenCV5.Saliency;    // saliency detectors
    using CodeBrix.VideoProcessing.OpenCV5.LineDescriptor; // LSDDetector
    using CodeBrix.VideoProcessing.OpenCV5.DnnSuperres; // DnnSuperResImpl
    using CodeBrix.VideoProcessing.OpenCV5.Segmentation; // IntelligentScissorsMB
    using CodeBrix.VideoProcessing.OpenCV5.XImgProc.Segmentation;
                                                        // graph / selective
                                                        // search segmentation
    using CodeBrix.VideoProcessing.OpenCV5.Detail;      // stitching internals
    using CodeBrix.VideoProcessing.OpenCV5.Extensions;  // CvExtensions
    using CodeBrix.VideoProcessing.OpenCV5.Wpf;         // WPF converters
                                                        // (separate package)

CodeBrix.VideoProcessing.OpenCV5.Internal is the P/Invoke layer. Do not call
into it from application code — with ONE documented exception,
NativeMethods.TryPInvoke() (see NATIVE LIBRARY LOADING AND DIAGNOSTICS).

Note that several modules that have their own namespace upstream live in the
ROOT namespace here, so no extra using is needed for them: VideoCapture,
VideoWriter, FourCC, CascadeClassifier, QRCodeDetector, HOGDescriptor,
FaceDetectorYN, Tracker, TrackerMIL, KalmanFilter, BackgroundSubtractor and
its MOG2/KNN/MOG/GMG subclasses, SIFT, ORB, BFMatcher, FlannBasedMatcher,
Stitcher, the photo-module Tonemap/Merge/Calibrate types, Subdiv2D, CLAHE,
and every geometry/value struct.

CORE API REFERENCE
==================
The API reference is organised by feature area in the sections that follow.

THE Mat TYPE
============
Mat is the n-dimensional dense array that carries every image and matrix.
It wraps native memory and implements IDisposable — ALWAYS dispose it, and
dispose every Mat that a method hands back to you.

Construction
------------
    Mat()                                          // empty, sized on first use
    Mat(int rows, int cols, MatType type)
    Mat(Size size, MatType type)
    Mat(int rows, int cols, MatType type, Scalar s)  // filled
    Mat(Size size, MatType type, Scalar s)
    Mat(IEnumerable<int> sizes, MatType type)        // N-dimensional
    Mat(MatShape shape, MatType type)
    Mat(string fileName, ImreadModes flags = ImreadModes.Color)  // = ImRead
    Mat(Mat m, Rect roi)                             // view onto m
    Mat(Mat m, Range rowRange, Range? colRange = null)
    Mat(Mat m, params Range[] ranges)

    static Mat Zeros(...) / Ones(...) / Eye(...)     // return MatExpr
    static Mat ZerosMat(int rows, int cols, MatType type)   // return Mat
    static Mat OnesMat(...)  /  static Mat EyeMat(...)
    static Mat Diag(Mat d)
    static Mat<T> FromArray<T>(params T[] arr)
    static Mat<T> FromArray<T>(T[,] arr)
    static Mat<T> FromArray<T>(IEnumerable<T> enumerable)

Wrapping existing pixel data (FromPixelData)
--------------------------------------------
FromPixelData is the supported way to build a Mat over memory you already
have (the old pixel-data constructor is deprecated):

    static Mat FromPixelData(int rows, int cols, MatType type, Array data,
                             long step = 0)
    static Mat FromPixelData(int rows, int cols, MatType type, IntPtr data,
                             long step = 0)
    static Mat FromPixelData(IEnumerable<int> sizes, MatType type, Array data,
                             IEnumerable<long>? steps = null)
    static Mat FromPixelData(IEnumerable<int> sizes, MatType type, IntPtr data,
                             IEnumerable<long>? steps = null)

Decoding compressed bytes:

    static Mat ImDecode(byte[] imageBytes, ImreadModes mode = ImreadModes.Color)
    static Mat ImDecode(ReadOnlySpan<byte> span, ImreadModes mode = ...)
    static Mat FromImageData(byte[] imageBytes, ImreadModes mode = ...)
    static Mat FromStream(Stream stream, ImreadModes mode)

Shape, type and buffer queries
------------------------------
    int Rows / int Height          int Cols / int Width
    int Dims                       MatShape Shape()
    Size Size()                    int Size(int dim)
    MatType Type()                 int Depth()      int Channels()
    int ElemSize()                 int ElemSize1()
    long Step()                    long Step(int i)     long Step1(int i = 0)
    long Total()                   long Total(int startDim, int endDim = ...)
    bool Empty()                   bool IsContinuous()   bool IsSubmatrix()
    IntPtr Data                    unsafe byte* DataPointer
    bool IsDisposed                IntPtr CvPtr
    string Dump(FormatType format = FormatType.Default)

Rows and Cols report -1 when Dims > 2. Rows, Cols, Dims, Width and Height are
each a P/Invoke call — cache them before a loop (analyzer OCVS002).

Element access
--------------
    T Get<T>(int i0)                     where T : struct
    T Get<T>(int i0, int i1)
    T Get<T>(int i0, int i1, int i2)
    T Get<T>(params int[] idx)
    void Set<T>(int i0, T value)         where T : struct
    void Set<T>(int i0, int i1, T value)
    void Set<T>(int i0, int i1, int i2, T value)
    void Set<T>(int[] idx, T value)
    unsafe ref T At<T>(int i0)           where T : unmanaged
    unsafe ref T At<T>(int i0, int i1)
    unsafe ref T At<T>(int i0, int i1, int i2)
    unsafe ref T At<T>(params int[] idx)
    Indexer<T> GetGenericIndexer<T>()          where T : struct
    UnsafeIndexer<T> GetUnsafeGenericIndexer<T>() where T : unmanaged

T is the whole-element type: byte for CV_8UC1, Vec3b for CV_8UC3, Vec4b for
CV_8UC4, float for CV_32FC1, Vec3f for CV_32FC3, and so on.

Fast bulk access (CodeBrix additions and spans)
-----------------------------------------------
    unsafe Span<T> AsSpan<T>()        where T : unmanaged   // continuous only
    unsafe Span<T> RowSpan<T>(int row)                      // 2-D only
    unsafe MatRowAccessor<T> AsRows<T>()                    // 2-D only
    T[] ToArray<T>()                  where T : unmanaged   // CodeBrix
    bool GetArray<T>(out T[] data)
    bool GetRectangularArray<T>(out T[,] data)
    bool SetArray<T>(params T[] data)
    bool SetRectangularArray<T>(T[,] data)

  * AsSpan<T>() returns an EMPTY span when the Mat is not continuous.
  * AsRows<T>() captures the data pointer, the row step and the dimensions
    once and returns a ref struct with `int Count` and
    `unsafe Span<T> this[int row]` — zero P/Invoke, zero allocation per row.
    Because it is a ref struct it cannot be captured by a lambda; inside
    Parallel.For call mat.AsRows<T>() again in each iteration.
  * ToArray<T>() is a CodeBrix addition: it copies a CONTINUOUS Mat of ANY
    dimensionality out in row-major order. T may be the per-channel primitive
    (float for any CV_32F matrix) or a whole-element Vec struct. This is the
    way to read N-dimensional DNN output tensors. It throws
    OpenCvSharpException when the Mat is not continuous or when sizeof(T)
    matches neither the per-channel size nor the element size.
  * GetArray<T> / GetRectangularArray<T> size their result from Rows x Cols,
    which are -1 when Dims > 2, so they CANNOT read an N-dimensional Mat.

Views, copies and conversions
-----------------------------
    Mat Row(int y)                  Mat Col(int x)
    Mat RowRange(int startRow, int endRow)    // also Range / System.Range
    Mat ColRange(int startCol, int endCol)    // overloads
    Mat SubMat(int rowStart, int rowEnd, int colStart, int colEnd)
    Mat SubMat(Rect roi)  /  SubMat(Range rowRange, Range colRange)
    Mat SubMat(params Range[] ranges)
    Mat this[Rect roi]              // indexer form of SubMat
    Mat this[int rowStart, int rowEnd, int colStart, int colEnd]
    Mat this[Range rowRange, Range colRange]
    Mat this[System.Range rowRange, System.Range colRange]
    Mat Clone()                     Mat Clone(Rect roi)
    Mat EmptyClone()
    void CopyTo(OutputArray m, InputArray mask = default)
    void CopyTo(Mat m, InputArray mask = default)
    void ConvertTo(OutputArray m, MatType rtype, double alpha = 1,
                   double beta = 0)
    void AssignTo(Mat m, MatType? type = null)
    Mat SetTo(Scalar value, Mat? mask = null)
    Mat SetTo(InputArray value, Mat? mask = null)
    Mat Reshape(int cn, int rows = 0)
    Mat Reshape(int cn, params int[] newDims)
    void Create(int rows, int cols, MatType type)   // reallocate
    Mat AdjustROI(int dtop, int dbottom, int dleft, int dright)
    void LocateROI(out Size wholeSize, out Point ofs)
    TMat Cast<TMat>()

EVERY one of Row, Col, RowRange, ColRange, SubMat and the indexers returns a
NEW Mat header that shares the parent's pixels and MUST be disposed (analyzer
OCVS004). Clone() copies the pixels; SubMat() does not.

Encoding straight off a Mat
---------------------------
    byte[] ToBytes(string ext = ".png", int[]? prms = null)
    byte[] ToBytes(string ext = ".png", params ImageEncodingParam[] prms)
    MemoryStream ToMemoryStream(string ext = ".png",
                                params ImageEncodingParam[] prms)
    void WriteToStream(Stream stream, string ext = ".png",
                       params ImageEncodingParam[] prms)

Arithmetic and comparison
-------------------------
Mat overloads +, -, *, /, &, |, ^, ~ and the comparison helpers; each returns
a lazy MatExpr, so materialise with an explicit cast or by assigning into a
Mat. Named forms exist for every operator: Add, Subtract, Multiply, Divide,
BitwiseAnd, BitwiseOr, Xor, OnesComplement, Negate, Plus, LessThan,
LessThanOrEqual, Equals, NotEquals, GreaterThan, GreaterThanOrEqual, plus
T() (transpose), Inv(DecompTypes method = DecompTypes.LU), Mul, Cross and Dot.

Related array types
-------------------
  Mat<TElem>     strongly typed Mat; adds TElem[] ToArray(),
                 TElem[,] ToRectangularArray(), TElem this[int row, int col],
                 IEnumerable<TElem>, and typed Clone/SubMat/Reshape/T.
  UMat           OpenCL-backed array; same shape API, plus
                 UMat(int rows, int cols, MatType type,
                      UMatUsageFlags usageFlags = UMatUsageFlags.None).
                 Mat.GetUMat(AccessFlag, UMatUsageFlags) converts.
  SparseMat      sparse n-dimensional array.
  MatExpr        lazy expression tree produced by the operators.
  MatShape       shape descriptor used by the N-dimensional overloads.

MatType
-------
MatType is a readonly record struct wrapping the OpenCV type code.

    static readonly MatType CV_8UC1  CV_8UC2  CV_8UC3  CV_8UC4
                            CV_8SC1..4   CV_16UC1..4  CV_16SC1..4
                            CV_32SC1..4  CV_32FC1..4  CV_64FC1..4
                            CV_16FC1..4  CV_16BFC1..4 CV_BoolC1..4
                            CV_64UC1..4  CV_64SC1..4  CV_32UC1..4
    static MatType CV_8UC(int ch) / CV_32FC(int ch) / ... one per depth
    static MatType MakeType(int depth, int channels)
    const int CV_8U CV_8S CV_16U CV_16S CV_32S CV_32F CV_64F CV_16F
              CV_16BF CV_Bool CV_64U CV_64S CV_32U
    int Value      int Depth      int Channels     bool IsInteger
    implicit operator MatType(int) / explicit operator int(MatType)

GEOMETRY AND VALUE STRUCTS
==========================
All of these live in the root namespace and are record structs unless noted:

    Point(int X, int Y)              Point2f(float X, float Y)
    Point2d(double X, double Y)      Point3i / Point3f / Point3d (X, Y, Z)
    Size(int Width, int Height)      Size2f / Size2d
    Rect(int X, int Y, int Width, int Height)     Rect2f / Rect2d
    Range(int Start, int End)        Rangef
    RotatedRect                      TermCriteria(CriteriaTypes Type,
                                                  int MaxCount, double Epsilon)
    Scalar(double Val0, double Val1, double Val2, double Val3)
    KeyPoint(Point2f Pt, float Size, float Angle = -1, float Response = 0,
             int Octave = 0, int ClassId = -1)
    DMatch(int QueryIdx, int TrainIdx, int ImgIdx, float Distance)
    Vec2b Vec3b Vec4b Vec6b   Vec2s Vec3s Vec4s Vec6s
    Vec2w Vec3w Vec4w Vec6w   Vec2i Vec3i Vec4i Vec6i
    Vec2f Vec3f Vec4f Vec6f   Vec2d Vec3d Vec4d Vec6d
    Moments   HierarchyIndex   LineSegmentPoint(Point P1, Point P2)
    LineSegmentPolar   CircleSegment(Point2f Center, float Radius)

Scalar carries the drawing colours: 140 named CSS colours as static readonly
fields (Scalar.Red, Scalar.Lime, Scalar.Blue, Scalar.White, Scalar.Black,
Scalar.Yellow, ...), plus Scalar.All(double v), Scalar.FromRgb(int r, int g,
int b) and Scalar.RandomColor(). Note that the OpenCV channel order for an
8UC3 image is B, G, R — FromRgb reorders for you.

InputArray / OutputArray / InputOutputArray
===========================================
Most Cv2 methods take these adapter types. They are `readonly ref struct`s
with implicit conversions from Mat, UMat, MatExpr, Scalar, double and every
Vec struct, so in practice you pass a Mat and never name them:

    Cv2.CvtColor(src, dst, ColorConversionCodes.BGR2GRAY);   // both Mats

Because they are ref structs they cannot be stored in a field, captured by a
lambda, used as a generic type argument, or crossed over an await. Keep them
as method arguments and locals. An omitted optional InputArray parameter is
written `default`, not `null`.

IMAGE I/O (imgcodecs)
=====================
    static Mat  Cv2.ImRead(string fileName,
                           ImreadModes flags = ImreadModes.Color)
    static bool Cv2.ImReadMulti(string filename, out Mat[] mats,
                           ImreadModes flags = ImreadModes.AnyColor)
    static bool Cv2.ImWrite(string fileName, Mat img, int[]? prms = null)
    static bool Cv2.ImWrite(string fileName, Mat img,
                           params ImageEncodingParam[] prms)
    static bool Cv2.ImWrite(string fileName, IEnumerable<Mat> img,
                           int[]? prms = null)
    static Mat  Cv2.ImDecode(byte[] buf, ImreadModes flags)
    static Mat  Cv2.ImDecode(ReadOnlySpan<byte> span, ImreadModes flags)
    static Mat  Cv2.ImDecode(Mat buf, ImreadModes flags)
    static Mat  Cv2.ImDecode(InputArray buf, ImreadModes flags)
    static bool Cv2.ImEncode(string ext, InputArray img, out byte[] buf,
                           int[]? prms = null)
    static void Cv2.ImEncode(string ext, InputArray img, out byte[] buf,
                           params ImageEncodingParam[] prms)
    static bool Cv2.HaveImageReader(string fileName)
    static bool Cv2.HaveImageWriter(string fileName)

    ImreadModes: Unchanged, Grayscale, Color, AnyDepth, AnyColor, LoadGdal,
                 ReducedGrayscale2/4/8, ReducedColor2/4/8, IgnoreOrientation
    ImageEncodingParam(ImwriteFlags id, int value) — ImwriteFlags includes
                 JpegQuality, PngCompression, WebPQuality, TiffCompression, ...

ImRead returns a Mat whose Empty() is true when the file could not be read; it
does not throw. Always check.

IMAGE PROCESSING (imgproc)
==========================
Resizing, warping and remapping
-------------------------------
    static void Resize(InputArray src, OutputArray dst, Size dsize,
                       double fx = 0, double fy = 0,
                       InterpolationFlags interpolation =
                           InterpolationFlags.Linear)
    static Mat  GetRotationMatrix2D(Point2f center, double angle, double scale)
    static void WarpAffine(InputArray src, OutputArray dst, InputArray m,
                       Size dsize,
                       InterpolationFlags flags = InterpolationFlags.Linear,
                       BorderTypes borderMode = BorderTypes.Constant,
                       Scalar? borderValue = null,
                       AlgorithmHint hint = AlgorithmHint.Default)
    static void WarpPerspective(InputArray src, OutputArray dst, InputArray m,
                       Size dsize, InterpolationFlags flags = ...,
                       BorderTypes borderMode = BorderTypes.Constant,
                       Scalar? borderValue = null, AlgorithmHint hint = ...)
    static Mat  GetPerspectiveTransform(IEnumerable<Point2f> src,
                                        IEnumerable<Point2f> dst)
    static void Remap(InputArray src, OutputArray dst, InputArray map1,
                      InputArray map2, InterpolationFlags interpolation = ...,
                      BorderTypes borderMode = BorderTypes.Constant,
                      Scalar? borderValue = null, AlgorithmHint hint = ...)
    static void PyrDown(InputArray src, OutputArray dst, ...)
    static void PyrUp(InputArray src, OutputArray dst, ...)

    InterpolationFlags: Nearest, Linear, Cubic, Area, Lanczos4, LinearExact,
                        NearestExact (+ WarpFillOutliers, WarpInverseMap)
    Use Area when shrinking, Cubic or Linear when enlarging.

Colour conversion
-----------------
    static void CvtColor(InputArray src, OutputArray dst,
                         ColorConversionCodes code, int dstCn = 0,
                         AlgorithmHint hint = AlgorithmHint.Default)

    ColorConversionCodes covers the full OpenCV set — BGR2GRAY, GRAY2BGR,
    BGRA2BGR, BGR2RGB, BGR2HSV, HSV2BGR, BGR2Lab, BGR2YUV, and the Bayer and
    YUV 4:2:0 conversions.

Filtering and edges
-------------------
    static void GaussianBlur(InputArray src, OutputArray dst, Size ksize,
                       double sigmaX, double sigmaY = 0,
                       BorderTypes borderType = BorderTypes.Default,
                       AlgorithmHint hint = AlgorithmHint.Default)
    static void Blur(InputArray src, OutputArray dst, Size ksize,
                       Point? anchor = null,
                       BorderTypes borderType = BorderTypes.Default)
    static void MedianBlur(InputArray src, OutputArray dst, int ksize)
    static void BilateralFilter(InputArray src, OutputArray dst, int d,
                       double sigmaColor, ...)
    static void Filter2D(InputArray src, OutputArray dst, InputArray kernel,
                       Filter2DParams? @params = null)
    static void Sobel(InputArray src, OutputArray dst, MatType ddepth,
                       int xorder, int yorder, int ksize = 3, double scale = 1,
                       double delta = 0,
                       BorderTypes borderType = BorderTypes.Default)
    static void Scharr(...)   static void Laplacian(...)
    static void Canny(InputArray src, OutputArray edges, double threshold1,
                       double threshold2, int apertureSize = 3,
                       bool L2gradient = false)
    static void Canny(InputArray dx, InputArray dy, OutputArray edges,
                       double threshold1, double threshold2,
                       bool L2gradient = false)

Thresholding, morphology and histograms
---------------------------------------
    static double Threshold(InputArray src, OutputArray dst, double thresh,
                       double maxval, ThresholdTypes type)
    static void AdaptiveThreshold(InputArray src, OutputArray dst,
                       double maxValue, AdaptiveThresholdTypes adaptiveMethod,
                       ThresholdTypes thresholdType, int blockSize, double c)
    static Mat  GetStructuringElement(MorphShapes shape, Size ksize)
    static Mat  GetStructuringElement(MorphShapes shape, Size ksize,
                                      Point anchor)
    static void Dilate(InputArray src, OutputArray dst, InputArray element,
                       Point? anchor = null, int iterations = 1,
                       BorderTypes borderType = BorderTypes.Constant,
                       Scalar? borderValue = null)
    static void Erode(...)  // same shape as Dilate
    static void MorphologyEx(InputArray src, OutputArray dst, MorphTypes op,
                       InputArray element, Point? anchor = null,
                       int iterations = 1, ...)
    static void EqualizeHist(InputArray src, OutputArray dst)
    static void CalcHist(Mat[] images, int[] channels, InputArray mask,
                       OutputArray hist, int dims, int[] histSize,
                       Rangef[] ranges, bool uniform = true,
                       bool accumulate = false)
    CLAHE.Create(double clipLimit = 40.0, Size? tileGridSize = null)
        -> CLAHE with void Apply(InputArray src, OutputArray dst)

    ThresholdTypes: Binary, BinaryInv, Trunc, Tozero, TozeroInv, Mask, Otsu,
                    Triangle  (combine Otsu/Triangle with Binary using |)
    MorphShapes: Rect, Cross, Ellipse
    MorphTypes: Erode, Dilate, Open, Close, Gradient, TopHat, BlackHat, HitMiss

Contours and shape analysis
---------------------------
    static void FindContours(InputArray image, out Point[][] contours,
                       out HierarchyIndex[] hierarchy, RetrievalModes mode,
                       ContourApproximationModes method, Point? offset = null)
    static void FindContours(InputArray image, out Mat[] contours,
                       OutputArray hierarchy, RetrievalModes mode,
                       ContourApproximationModes method, Point? offset = null)
    static void DrawContours(InputOutputArray image,
                       IEnumerable<IEnumerable<Point>> contours,
                       int contourIdx, Scalar color, int thickness = 1,
                       LineTypes lineType = LineTypes.Link8,
                       IEnumerable<HierarchyIndex>? hierarchy = null,
                       int maxLevel = int.MaxValue, Point? offset = null)
    static Point[]  ApproxPolyDP(IEnumerable<Point> curve, double epsilon,
                                 bool closed)
    static double   ArcLength(IEnumerable<Point> curve, bool closed)
    static double   ContourArea(IEnumerable<Point> contour,
                                bool oriented = false)
    static Rect     BoundingRect(IEnumerable<Point> curve)
    static RotatedRect MinAreaRect(IEnumerable<Point> points)
    static Point[]  ConvexHull(IEnumerable<Point> points, bool clockwise=false)
    static Moments  Moments(InputArray array, bool binaryImage = false)
    static int      ConnectedComponents(InputArray image, OutputArray labels,
                                 PixelConnectivity connectivity =
                                     PixelConnectivity.Connectivity8)
    static int      ConnectedComponents(InputArray image, OutputArray labels,
                                 PixelConnectivity connectivity,
                                 MatType ltype)
    static void     Watershed(InputArray image, InputOutputArray markers)
    static void     GrabCut(InputArray img, InputOutputArray mask, Rect rect,
                                 InputOutputArray bgdModel,
                                 InputOutputArray fgdModel, int iterCount,
                                 GrabCutModes mode)
    static void     DistanceTransform(InputArray src, ...)
    static int      FloodFill(InputOutputArray image, Point seedPoint,
                                 Scalar newVal)

    RetrievalModes: External, List, CComp, Tree, FloodFill
    ContourApproximationModes: ApproxNone, ApproxSimple, ApproxTC89L1,
                               ApproxTC89KCOS

Corners, lines and template matching
------------------------------------
    static Point2f[] GoodFeaturesToTrack(InputArray src, int maxCorners,
                       double qualityLevel, double minDistance,
                       InputArray mask, int blockSize, bool useHarrisDetector,
                       double k)
    static Point2f[] CornerSubPix(InputArray image,
                       IEnumerable<Point2f> inputCorners, Size winSize,
                       Size zeroZone, TermCriteria criteria)
    static void CornerHarris(InputArray src, OutputArray dst, int blockSize,
                       int ksize, double k, ...)
    static LineSegmentPolar[] HoughLines(InputArray image, double rho,
                       double theta, int threshold, double srn = 0,
                       double stn = 0)
    static LineSegmentPoint[] HoughLinesP(InputArray image, double rho,
                       double theta, int threshold, double minLineLength = 0,
                       double maxLineGap = 0)
    static CircleSegment[] HoughCircles(InputArray image, HoughModes method,
                       double dp, double minDist, double param1 = 100,
                       double param2 = 100, int minRadius = 0,
                       int maxRadius = 0)
    static void MatchTemplate(InputArray image, InputArray templ,
                       OutputArray result, TemplateMatchModes method,
                       InputArray mask = default)

    TemplateMatchModes: SqDiff, SqDiffNormed, CCorr, CCorrNormed, CCoeff,
                        CCoeffNormed

Other imgproc helper types
--------------------------
  CLAHE                   contrast-limited adaptive histogram equalisation
  LineIterator            walks the pixels along a line segment
  LineSegmentDetector     LSD line detection
  GeneralizedHough,       generalised Hough transform
  GeneralizedHoughBallard,
  GeneralizedHoughGuil
  Subdiv2D                Delaunay triangulation / Voronoi
  IntelligentScissorsMB   interactive segmentation (namespace
                          ...OpenCV5.Segmentation)
  FontFace                TrueType font handle for the PutText overload that
                          takes one
  Filter2DParams          option bag for the Filter2D overload
  Line2D, Line3D          fitted-line result classes
  ConnectedComponents     the object-model result of the ConnectedComponents
                          helpers, with a nested Blob class per component
  Moments, HierarchyIndex, LineSegmentPoint, LineSegmentPolar, CircleSegment
                          the result types returned above

DRAWING
=======
    static void Line(InputOutputArray img, Point pt1, Point pt2, Scalar color,
                     int thickness = 1, LineTypes lineType = LineTypes.Link8,
                     int shift = 0)
    static void Rectangle(InputOutputArray img, Rect rect, Scalar color,
                     int thickness = 1, LineTypes lineType = LineTypes.Link8,
                     int shift = 0)
    static void Rectangle(InputOutputArray img, Point pt1, Point pt2,
                     Scalar color, int thickness = 1, ...)
    static void Circle(InputOutputArray img, Point center, int radius,
                     Scalar color, int thickness = 1, ...)
    static void Ellipse(InputOutputArray img, Point center, Size axes,
                     double angle, double startAngle, double endAngle,
                     Scalar color, int thickness = 1, ...)
    static void Ellipse(InputOutputArray img, RotatedRect box, Scalar color,
                     int thickness = 1, LineTypes lineType = LineTypes.Link8)
    static void Polylines(InputOutputArray img, InputArray pts, bool isClosed,
                     Scalar color, int thickness = 1, ...)
    static void FillPoly(Mat img, IEnumerable<IEnumerable<Point>> pts,
                     Scalar color, LineTypes lineType = LineTypes.Link8,
                     int shift = 0, Point? offset = null)
    static void PutText(InputOutputArray img, string text, Point org,
                     HersheyFonts fontFace, double fontScale, Scalar color,
                     int thickness = 1, LineTypes lineType = LineTypes.Link8,
                     bool bottomLeftOrigin = false)
    static Size GetTextSize(string text, HersheyFonts fontFace,
                     double fontScale, int thickness, out int baseLine)

    HersheyFonts: HersheySimplex, HersheyPlain, HersheyDuplex, HersheyComplex,
                  HersheyTriplex, HersheyComplexSmall, HersheyScriptSimplex,
                  HersheyScriptComplex (| Italic)
    LineTypes: Link4, Link8, AntiAlias
    Cv2.FILLED (= -1) as the thickness fills the shape.

A TrueType-capable text path also exists: FontFace plus the
PutText(InputOutputArray img, string text, Point org, Scalar color,
FontFace fontFace, int size, int weight = 0,
PutTextFlags flags = PutTextFlags.AlignLeft, Range? wrap = null) overload,
and its matching GetTextSize overload returning a Rect.

CORE ARRAY OPERATIONS
=====================
    static void   Add / Subtract(InputArray src1, InputArray src2,
                        OutputArray dst, InputArray mask = default,
                        int dtype = -1)
    static void   AddWeighted(InputArray src1, double alpha, InputArray src2,
                        double beta, double gamma, OutputArray dst,
                        int dtype = -1)
    static void   ConvertScaleAbs(InputArray src, OutputArray dst,
                        double alpha = 1, double beta = 0)
    static void   Normalize(InputArray src, InputOutputArray dst,
                        double alpha = 1, double beta = 0,
                        NormTypes normType = NormTypes.L2, int dtype = -1,
                        InputArray mask = default)
    static void   MinMaxLoc(InputArray src, out double minVal,
                        out double maxVal, out Point minLoc, out Point maxLoc,
                        InputArray mask = default)
    static Scalar Mean(InputArray src, InputArray mask = default)
    static void   MeanStdDev(InputArray src, out Scalar mean,
                        out Scalar stddev, InputArray mask = default)
    static Scalar Sum(InputArray src)
    static int    CountNonZero(InputArray mtx)
    static Mat[]  Split(Mat src)
    static void   Split(Mat src, out Mat[] mv)
    static void   Merge(ReadOnlySpan<Mat> mv, Mat dst)
    static void   InRange(InputArray src, Scalar lowerb, Scalar upperb,
                        OutputArray dst)
    static void   Compare(InputArray src1, InputArray src2, OutputArray dst,
                        CmpTypes cmpop)
    static void   BitwiseAnd / BitwiseOr / BitwiseXor(InputArray src1,
                        InputArray src2, OutputArray dst,
                        InputArray mask = default)
    static void   BitwiseNot(InputArray src, OutputArray dst,
                        InputArray mask = default)
    static void   Flip(InputArray src, OutputArray dst, FlipMode flipCode)
    static void   Rotate(InputArray src, OutputArray dst,
                        RotateFlags rotateCode)
    static void   Transpose(InputArray src, OutputArray dst)
    static void   HConcat / VConcat(ReadOnlySpan<Mat> src, OutputArray dst)
    static void   CopyMakeBorder(InputArray src, OutputArray dst, int top,
                        int bottom, int left, int right,
                        BorderTypes borderType, Scalar? value = null)
    static void   SetNumThreads(int nThreads)   static int GetNumThreads()
    static long   GetTickCount()   static double GetTickFrequency()
    static bool   UseOptimized()   static void SetUseOptimized(bool onoff)
    static string GetBuildInformation()
    static string? GetVersionString()

    FlipMode: X, Y, XY.  RotateFlags: Rotate90Clockwise, Rotate180,
    Rotate90Counterclockwise.

Other core services: Algorithm (base of every Create()-style detector), PCA,
SVD, LDA, RNG, RNG_MT19937, FileStorage / FileNode / FileNodeIterator (the
OpenCV YAML/XML/JSON persistence used by CascadeClassifier and the ml models).

VIDEO CAPTURE AND WRITING (videoio)
===================================
VideoCapture
------------
    VideoCapture()
    VideoCapture(int index, VideoCaptureAPIs apiPreference =
                 VideoCaptureAPIs.ANY)
    VideoCapture(string fileName, VideoCaptureAPIs apiPreference =
                 VideoCaptureAPIs.ANY)
    static VideoCapture FromCamera(int index, VideoCaptureAPIs apiPreference =
                 VideoCaptureAPIs.ANY)
    static VideoCapture FromFile(string fileName,
                 VideoCaptureAPIs apiPreference = VideoCaptureAPIs.ANY)

    bool Open(string fileName, VideoCaptureAPIs apiPreference = ...)
    bool Open(int index, VideoCaptureAPIs apiPreference = ...)
    bool IsOpened()
    bool Read(Mat image)            bool Read(OutputArray image)
    bool Grab()                     bool Retrieve(Mat image, int flag = 0)
    void Release()
    bool   Set(VideoCaptureProperties propertyId, double value)
    double Get(VideoCaptureProperties propertyId)
    string GetBackendName()
    void   SetExceptionMode(bool enable)

    Typed property shortcuts: FrameWidth, FrameHeight, Fps, FrameCount,
    FourCC, PosMsec, PosFrames, PosAviRatio, Brightness, Contrast, Saturation,
    Hue, Gain, Exposure, AutoExposure, AutoFocus, Focus, Zoom, BufferSize,
    ConvertRgb, Format, Mode, CaptureType, and the OpenNI / XI_* device
    families.

    VideoCaptureAPIs: ANY, V4L, V4L2, DSHOW, MSMF, FFMPEG, GSTREAMER,
    AVFOUNDATION, OPENCV_MJPEG, IMAGES, ... Pass ANY unless you must pin a
    backend.

VideoWriter
-----------
    VideoWriter()
    VideoWriter(string fileName, FourCC fourcc, double fps, Size frameSize,
                bool isColor = true)
    VideoWriter(string fileName, VideoCaptureAPIs apiPreference, FourCC fourcc,
                double fps, Size frameSize, bool isColor = true)
    bool Open(string fileName, FourCC fourcc, double fps, Size frameSize,
              bool isColor = true)
    bool IsOpened()      void Write(InputArray image)      void Release()
    bool   Set(VideoWriterProperties propId, double value)
    double Get(VideoWriterProperties propId)
    string GetBackendName()
    static int FourCC(char c1, char c2, char c3, char c4)
    static int FourCC(string code)
    string? FileName   double Fps   Size FrameSize   bool IsColor

FourCC
------
FourCC is a readonly struct with implicit conversions to and from int, so the
named codes can be passed straight to the VideoWriter constructor:

    FourCC.MJPG  FourCC.XVID  FourCC.X264  FourCC.H264  FourCC.H265
    FourCC.HEVC  FourCC.MP4V  FourCC.DIVX  FourCC.AVC   FourCC.WMV3
    FourCC.I420  FourCC.IYUV  FourCC.JPEG  FourCC.DIB   (and ~30 more)
    FourCC.FromString("MJPG")   FourCC.FromFourChars('M','J','P','G')
    FourCC.Default / FourCC.Prompt (= -1)

Every frame handed to Write must have the exact frameSize the writer was
opened with, and (unless isColor: false) must be 3-channel 8-bit.

FEATURE DETECTION AND MATCHING (features2d)
===========================================
Detectors and descriptors derive from Feature2D:

    static SIFT SIFT.Create(int nFeatures = 0, int nOctaveLayers = 3,
                     double contrastThreshold = 0.04,
                     double edgeThreshold = 10, double sigma = 1.6)
    static ORB  ORB.Create(int nFeatures = 500, float scaleFactor = 1.2f,
                     int nLevels = 8, int edgeThreshold = 31,
                     int firstLevel = 0, int wtaK = 2,
                     ORBScoreType scoreType = ORBScoreType.Harris,
                     int patchSize = 31, int fastThreshold = 20)

  Other Feature2D implementations shipped: AffineFeature, ALIKED, DISK,
  FastFeatureDetector, GFTTDetector, MSER, SimpleBlobDetector (with its
  nested Params), and from the XFeatures2D namespace AKAZE, KAZE, BRISK,
  SURF, FREAK, LATCH, LUCID, StarDetector, BriefDescriptorExtractor,
  AgastFeatureDetector, plus BOWKMeansTrainer / BOWImgDescriptorExtractor.

Feature2D API
-------------
    KeyPoint[] Detect(Mat image, Mat? mask = null)
    KeyPoint[] Detect(InputArray image, InputArray mask = default)
    KeyPoint[][] Detect(IEnumerable<Mat> images,
                        IEnumerable<Mat>? masks = null)
    virtual void Compute(InputArray image, ref KeyPoint[] keypoints,
                        OutputArray descriptors)
    virtual void DetectAndCompute(InputArray image, InputArray mask,
                        out KeyPoint[] keypoints, OutputArray descriptors,
                        bool useProvidedKeypoints = false)
    virtual int DescriptorSize   virtual int DescriptorType
    virtual int DefaultNorm      virtual bool Empty()

Matchers derive from DescriptorMatcher:

    BFMatcher(NormTypes normType = NormTypes.L2, bool crossCheck = false)
    FlannBasedMatcher(IndexParams? indexParams = null,
                      SearchParams? searchParams = null)
    static DescriptorMatcher DescriptorMatcher.Create(
                      string descriptorMatcherType)

    DMatch[]   Match(Mat queryDescriptors, Mat trainDescriptors,
                     Mat? mask = null)
    DMatch[][] KnnMatch(Mat queryDescriptors, Mat trainDescriptors, int k,
                     Mat? mask = null, bool compactResult = false)
    DMatch[][] RadiusMatch(Mat queryDescriptors, Mat trainDescriptors,
                     float maxDistance, Mat? mask = null,
                     bool compactResult = false)
    virtual void Add(IEnumerable<Mat> descriptors)   // train-set overloads
    virtual void Train()   virtual void Clear()   virtual bool IsMaskSupported()

    Use NormTypes.Hamming for ORB/BRISK/BRIEF binary descriptors and
    NormTypes.L2 for SIFT/SURF float descriptors. FLANN index parameter types:
    KDTreeIndexParams, KMeansIndexParams, LshIndexParams, CompositeIndexParams,
    AutotunedIndexParams, LinearIndexParams, SavedIndexParams, SearchParams
    (namespace ...Flann, alongside the standalone Flann.Index).

Free functions
--------------
    static KeyPoint[] Cv2.FAST(InputArray image, int threshold,
                     bool nonmaxSupression = true)
    static KeyPoint[] Cv2.AGAST(InputArray image, int threshold,
                     bool nonmaxSuppression,
                     AgastFeatureDetector.DetectorType type)
    static void Cv2.DrawKeypoints(InputArray image,
                     IEnumerable<KeyPoint> keypoints,
                     InputOutputArray outImage, Scalar? color = null,
                     DrawMatchesFlags flags = DrawMatchesFlags.Default)
    static void Cv2.DrawMatches(Mat img1, IEnumerable<KeyPoint> keypoints1,
                     Mat img2, IEnumerable<KeyPoint> keypoints2,
                     IEnumerable<DMatch> matches1To2, Mat outImg,
                     Scalar? matchColor = null, Scalar? singlePointColor = null,
                     IEnumerable<byte>? matchesMask = null,
                     DrawMatchesFlags flags = DrawMatchesFlags.Default)
    static void Cv2.DrawMatchesKnn(... IEnumerable<IEnumerable<DMatch>>
                     matches1To2 ...)
    KeyPointsFilter — static helpers to filter KeyPoint[] sets.

CAMERA CALIBRATION AND 3D GEOMETRY (calib3d)
============================================
    static bool FindChessboardCorners(InputArray image, Size patternSize,
                     out Point2f[] corners,
                     ChessboardFlags flags = ChessboardFlags.AdaptiveThresh |
                                             ChessboardFlags.NormalizeImage)
    static bool FindCirclesGrid(InputArray image, Size patternSize,
                     out Point2f[] centers,
                     FindCirclesGridFlags flags =
                         FindCirclesGridFlags.SymmetricGrid,
                     Feature2D? blobDetector = null)
    static void DrawChessboardCorners(InputOutputArray image, Size patternSize,
                     IEnumerable<Point2f> corners, bool patternWasFound)
    static double CalibrateCamera(
                     IEnumerable<IEnumerable<Point3f>> objectPoints,
                     IEnumerable<IEnumerable<Point2f>> imagePoints,
                     Size imageSize, double[,] cameraMatrix,
                     double[] distCoeffs, out Vec3d[] rvecs,
                     out Vec3d[] tvecs,
                     CalibrationFlags flags = CalibrationFlags.None,
                     TermCriteria? criteria = null)
    static double CalibrateCamera(IEnumerable<Mat> objectPoints,
                     IEnumerable<Mat> imagePoints, Size imageSize,
                     InputOutputArray cameraMatrix,
                     InputOutputArray distCoeffs, out Mat[] rvecs,
                     out Mat[] tvecs, CalibrationFlags flags = ...,
                     TermCriteria? criteria = null)
    static void Undistort(InputArray src, OutputArray dst,
                     InputArray cameraMatrix, InputArray distCoeffs,
                     InputArray newCameraMatrix = default)
    static void InitUndistortRectifyMap(InputArray cameraMatrix,
                     InputArray distCoeffs, InputArray r,
                     InputArray newCameraMatrix, Size size, MatType m1Type,
                     OutputArray map1, OutputArray map2)
    static void UndistortPoints(InputArray src, OutputArray dst,
                     InputArray cameraMatrix, InputArray distCoeffs,
                     InputArray r = default, InputArray p = default)
    static Mat  GetOptimalNewCameraMatrix(InputArray cameraMatrix,
                     InputArray distCoeffs, Size imageSize, double alpha,
                     Size newImgSize, out Rect validPixROI,
                     bool centerPrincipalPoint = false)
    static void SolvePnP(InputArray objectPoints, InputArray imagePoints,
                     InputArray cameraMatrix, InputArray distCoeffs,
                     OutputArray rvec, OutputArray tvec,
                     bool useExtrinsicGuess = false,
                     SolvePnPMethod flags = SolvePnPMethod.Iterative)
    static void SolvePnPRansac(InputArray objectPoints,
                     InputArray imagePoints, InputArray cameraMatrix,
                     InputArray distCoeffs, OutputArray rvec,
                     OutputArray tvec, bool useExtrinsicGuess = false,
                     int iterationsCount = 100,
                     float reprojectionError = 8.0f, double confidence = 0.99,
                     OutputArray inliers = default,
                     SolvePnPMethod flags = SolvePnPMethod.Iterative)
    static void ProjectPoints(InputArray objectPoints, InputArray rvec,
                     InputArray tvec, InputArray cameraMatrix,
                     InputArray distCoeffs, OutputArray imagePoints,
                     OutputArray jacobian = default, double aspectRatio = 0)
    static void Rodrigues(InputArray src, OutputArray dst,
                     OutputArray jacobian = default)
    static Mat  FindHomography(InputArray srcPoints, InputArray dstPoints,
                     HomographyMethods method = HomographyMethods.None,
                     double ransacReprojThreshold = 3,
                     OutputArray mask = default, int maxIters = 2000,
                     double confidence = 0.995)
    static double StereoCalibrate(...)      static void StereoRectify(...)
    static void DrawFrameAxes(InputOutputArray image, InputArray cameraMatrix,
                     InputArray distCoeffs, InputArray rvec, InputArray tvec,
                     float length, int thickness = 3)

Stereo matching: StereoBM, StereoSGBM (both StereoMatcher subclasses).
Fisheye variants live under the nested Cv2.FishEye class: ProjectPoints,
UndistortPoints, InitUndistortRectifyMap, StereoRectify and friends.
UsacParams configures the USAC robust estimators.

OBJECT DETECTION (objdetect)
============================
CascadeClassifier — Haar / LBP cascades
    CascadeClassifier()      CascadeClassifier(string fileName)
    bool Load(string fileName)      virtual bool Empty()
    virtual Rect[] DetectMultiScale(Mat image, double scaleFactor = 1.1,
                     int minNeighbors = 3, HaarDetectionTypes flags = 0,
                     Size? minSize = null, Size? maxSize = null)
    virtual Rect[] DetectMultiScale(Mat image, out int[] rejectLevels,
                     out double[] levelWeights, double scaleFactor = 1.1,
                     int minNeighbors = 3, HaarDetectionTypes flags = 0,
                     Size? minSize = null, Size? maxSize = null,
                     bool outputRejectLevels = false)
    virtual Size GetOriginalWindowSize()   int GetFeatureType()

QRCodeDetector
    bool   Detect(InputArray img, out Point2f[] points)
    string Decode(InputArray img, IEnumerable<Point2f> points,
                     OutputArray straightQrCode = default)
    string DetectAndDecode(InputArray img, out Point2f[] points,
                     OutputArray straightQrCode = default)
    bool   DetectMulti(InputArray img, out Point2f[] points)
    bool   DecodeMulti(InputArray img, IEnumerable<Point2f> points,
                     out string?[] decodedInfo)
    void   SetEpsX(double epsX)      void SetEpsY(double epsY)

HOGDescriptor
    HOGDescriptor(Size? winSize = null, Size? blockSize = null,
                     Size? blockStride = null, Size? cellSize = null,
                     int nbins = 9, int derivAperture = 1,
                     double winSigma = -1,
                     HistogramNormType histogramNormType =
                         HistogramNormType.L2Hys,
                     double l2HysThreshold = 0.2, bool gammaCorrection = true,
                     int nlevels = DefaultNlevels)
    HOGDescriptor(string fileName)
    static float[] GetDefaultPeopleDetector()
    static float[] GetDaimlerPeopleDetector()
    virtual void SetSVMDetector(float[] svmDetector)
    virtual float[] Compute(Mat img, Size? winStride = null,
                     Size? padding = null, Point[]? locations = null)
    virtual Point[] Detect(Mat img, double hitThreshold = 0,
                     Size? winStride = null, Size? padding = null,
                     Point[]? searchLocations = null)
    virtual Rect[] DetectMultiScale(Mat img, double hitThreshold = 0,
                     Size? winStride = null, Size? padding = null,
                     double scale = 1.05, int groupThreshold = 2)
    virtual Rect[] DetectMultiScale(Mat img, out double[] foundWeights, ...)
    virtual bool Load(string fileName, string? objName = null)
    virtual void Save(string fileName, string? objName = null)
    Properties: WinSize, BlockSize, BlockStride, CellSize, Nbins, WinSigma,
                L2HysThreshold, GammaCorrection, NLevels, SignedGradient

FaceDetectorYN — the DNN face detector
    static FaceDetectorYN Create(string model, string config, Size inputSize,
                     float scoreThreshold = 0.9f, float nmsThreshold = 0.3f,
                     int topK = 5000, Backend backendId = Backend.DEFAULT,
                     Target targetId = Target.CPU)
    int Detect(Mat image, Mat faces)

Also: Cv2.GroupRectangles(IList<Rect> rectList, int groupThreshold,
double eps = 0.2) and its out-weights overloads, BarcodeDetector,
WeChatQRCode, the SimilarRects predicate helper, and DetectionROI (used by
HOGDescriptor.DetectMultiScaleROI).

MACHINE LEARNING (ml)
=====================
All models derive from StatModel:

    virtual bool  Train(InputArray samples, SampleTypes layout,
                        InputArray responses)
    virtual float Predict(InputArray samples, OutputArray results = default,
                        StatModel.Flags flags = 0)   // Flags is nested in
                                                     // StatModel
    virtual int   GetVarCount()   virtual bool IsTrained()
    virtual bool  IsClassifier()  virtual bool Empty()

    SampleTypes: RowSample (one sample per row) or ColSample.

Shipped models, each with static Create(), static Load(string filePath) and
static LoadFromString(string strModel):

    SVM        Type (SVM.Types), KernelType (SVM.KernelTypes), C, Gamma,
               Coef0, Degree, Nu, P, ClassWeights, TermCriteria,
               Mat GetSupportVectors(),
               double GetDecisionFunction(int i, OutputArray alpha,
                                          OutputArray svidx),
               static ParamGrid GetDefaultGrid(SVM.ParamTypes paramId)
    RTrees     CalculateVarImportance, ActiveVarCount, TermCriteria,
               Mat GetVarImportance()   (derives from DTrees)
    DTrees     MaxCategories, MaxDepth, MinSampleCount, CVFolds,
               UseSurrogates, Use1SERule, TruncatePrunedTree,
               RegressionAccuracy, Priors, GetRoots/GetNodes/GetSplits/
               GetSubsets, nested Node and Split structs
    KNearest   DefaultK, IsClassifier, Emax, AlgorithmType,
               float FindNearest(InputArray samples, int k,
                                 OutputArray results,
                                 OutputArray neighborResponses = default,
                                 OutputArray dist = default)
    ANN_MLP    SetLayerSizes(InputArray), SetActivationFunction(
               ANN_MLP.ActivationFunctions type, double param1 = 0,
               double param2 = 0), SetTrainMethod(
               ANN_MLP.TrainingMethods method, ...), TermCriteria,
               Backprop/Rprop tuning properties
    Boost, EM, LogisticRegression, NormalBayesClassifier
    ParamGrid — grid descriptor for the SVM helpers

IMPORTANT — TrainData is NOT implemented in this port. Its constructor throws
NotImplementedException, and so do the members that take one:
StatModel.Train(TrainData, int), StatModel.CalcError(TrainData, bool,
OutputArray) and SVM.TrainAuto(...). Train models through
Train(InputArray samples, SampleTypes layout, InputArray responses) with two
Mats you build yourself, and evaluate with Predict.

MOTION, TRACKING AND BACKGROUND SUBTRACTION (video / tracking)
==============================================================
Optical flow and motion
-----------------------
    static void CalcOpticalFlowPyrLK(InputArray prevImg, InputArray nextImg,
                     Point2f[] prevPts, ref Point2f[] nextPts,
                     out byte[] status, out float[] err,
                     Size? winSize = null, int maxLevel = 3,
                     TermCriteria? criteria = null,
                     OpticalFlowFlags flags = OpticalFlowFlags.None,
                     double minEigThreshold = 1e-4)
    static void CalcOpticalFlowPyrLK(InputArray prevImg, InputArray nextImg,
                     InputArray prevPts, InputOutputArray nextPts,
                     OutputArray status, OutputArray err, ...)
    static void CalcOpticalFlowFarneback(InputArray prev, InputArray next,
                     InputOutputArray flow, double pyrScale, int levels,
                     int winsize, int iterations, int polyN,
                     double polySigma, OpticalFlowFlags flags)
    static int  BuildOpticalFlowPyramid(InputArray img, out Mat[] pyramid,
                     Size winSize, int maxLevel, ...)
    static RotatedRect CamShift(InputArray probImage, ref Rect window,
                     TermCriteria criteria)
    static int  MeanShift(InputArray probImage, ref Rect window,
                     TermCriteria criteria)
    static double FindTransformECC(InputArray templateImage,
                     InputArray inputImage, InputOutputArray warpMatrix,
                     MotionTypes motionType, TermCriteria criteria,
                     InputArray inputMask = default, int gaussFiltSize = 5)
    Cv2.OptFlow nested class: UpdateMotionHistory, CalcMotionGradient,
                     CalcGlobalOrientation, SegmentMotion,
                     CalcOpticalFlowSF, CalcOpticalFlowSparseToDense

Background subtraction
----------------------
    abstract class BackgroundSubtractor : Algorithm
        virtual void Apply(InputArray image, OutputArray fgmask,
                     double learningRate = -1)
        virtual void GetBackgroundImage(OutputArray backgroundImage)

    static BackgroundSubtractorMOG2 BackgroundSubtractorMOG2.Create(
                     int history = 500, double varThreshold = 16,
                     bool detectShadows = true)
        History, NMixtures, BackgroundRatio, VarThreshold, VarThresholdGen,
        VarInit, VarMin, VarMax, ComplexityReductionThreshold,
        DetectShadows, ShadowValue, ShadowThreshold
    static BackgroundSubtractorKNN BackgroundSubtractorKNN.Create(
                     int history = 500, double dist2Threshold = 400.0,
                     bool detectShadows = true)
        History, NSamples, Dist2Threshold, KNNSamples, DetectShadows,
        ShadowValue, ShadowThreshold
    static BackgroundSubtractorMOG BackgroundSubtractorMOG.Create(
                     int history = 200, int nMixtures = 5,
                     double backgroundRatio = 0.7, double noiseSigma = 0)
    static BackgroundSubtractorGMG BackgroundSubtractorGMG.Create(
                     int initializationFrames = 120,
                     double decisionThreshold = 0.8)

Trackers
--------
    abstract class Tracker : Algorithm
        void Init(Mat image, Rect boundingBox)
        bool Update(Mat image, ref Rect boundingBox)

    TrackerMIL.Create()  / TrackerMIL.Create(TrackerMIL.Params parameters)
    TrackerKCF.Create()  / TrackerKCF.Create(TrackerKCF.Params parameters)
    TrackerCSRT.Create() / TrackerCSRT.Create(TrackerCSRT.Params parameters)
        plus virtual void SetInitialMask(InputArray mask)

    TrackerKCF and TrackerCSRT live in ...OpenCV5.Tracking; Tracker and
    TrackerMIL live in the root namespace.

KalmanFilter
------------
    KalmanFilter(int dynamParams, int measureParams, int controlParams = 0,
                 int type = MatType.CV_32F)
    void Init(int dynamParams, int measureParams, int controlParams = 0,
              int type = MatType.CV_32F)
    Mat Predict(Mat? control = null)      Mat Correct(Mat measurement)
    Mat StatePre, StatePost, TransitionMatrix, ControlMatrix,
        MeasurementMatrix, ProcessNoiseCov, MeasurementNoiseCov,
        ErrorCovPre, Gain, ErrorCovPost

COMPUTATIONAL PHOTOGRAPHY (photo / xphoto)
==========================================
    static void Inpaint(InputArray src, InputArray inpaintMask,
                     OutputArray dst, double inpaintRadius,
                     InpaintTypes flags)
    static void FastNlMeansDenoising(InputArray src, OutputArray dst,
                     float h = 3, int templateWindowSize = 7,
                     int searchWindowSize = 21)
    static void FastNlMeansDenoisingColored(InputArray src, OutputArray dst,
                     float h = 3, float hColor = 3,
                     int templateWindowSize = 7, int searchWindowSize = 21)
    static void DenoiseTVL1(IEnumerable<Mat> observations, Mat result,
                     double lambda = 1.0, int niters = 30)
    static void SeamlessClone(InputArray src, InputArray dst, InputArray mask,
                     Point p, OutputArray blend, SeamlessCloneFlags flags)
    static void ColorChange(InputArray src, InputArray mask, OutputArray dst,
                     float redMul = 1.0f, float greenMul = 1.0f,
                     float blueMul = 1.0f)
    static void IlluminationChange(InputArray src, InputArray mask,
                     OutputArray dst, float alpha = 0.2f, float beta = 0.4f)
    static void TextureFlattening(InputArray src, InputArray mask,
                     OutputArray dst, float lowThreshold = 30,
                     float highThreshold = 45, int kernelSize = 3)
    static void EdgePreservingFilter(InputArray src, OutputArray dst,
                     EdgePreservingMethods flags =
                         EdgePreservingMethods.RecursFilter,
                     float sigmaS = 60, float sigmaR = 0.4f)
    static void DetailEnhance(InputArray src, OutputArray dst,
                     float sigmaS = 10, float sigmaR = 0.15f)
    static void PencilSketch(InputArray src, OutputArray dst1,
                     OutputArray dst2, float sigmaS = 60, float sigmaR = 0.07f,
                     float shadeFactor = 0.02f)
    static void Stylization(InputArray src, OutputArray dst,
                     float sigmaS = 60, float sigmaR = 0.45f)
    static void Decolor(InputArray src, OutputArray grayscale,
                     OutputArray colorBoost)

HDR pipeline: CalibrateDebevec, CalibrateRobertson (CalibrateCRF),
MergeDebevec, MergeMertens (MergeExposures), Tonemap, TonemapDrago,
TonemapReinhard, TonemapMantiuk. From XPhoto: GrayworldWB, LearningBasedWB,
SimpleWB (WhiteBalancer) and TonemapDurand.

IMAGE STITCHING
===============
    static Stitcher Stitcher.Create(Stitcher.Mode mode =
                                    Stitcher.Mode.Panorama)
    Stitcher.Status Stitch(IEnumerable<Mat> images, OutputArray pano)
    Stitcher.Status Stitch(InputArray images, OutputArray pano)
    Stitcher.Status EstimateTransform(IEnumerable<Mat> images)
    Stitcher.Status ComposePanorama(OutputArray pano)
    Properties: RegistrationResol, SeamEstimationResol, CompositingResol,
                PanoConfidenceThresh, WaveCorrection, WaveCorrectKind,
                Component, WorkScale
    Stitcher.Mode:   Panorama, Scans
    Stitcher.Status: OK, ErrorNeedMoreImgs, ErrorHomographyEstFail,
                     ErrorCameraParamsAdjustFail

Stitcher's high-level Stitch / EstimateTransform / ComposePanorama path is
fully working. The pipeline-component PROPERTIES (FeaturesFinder,
FeaturesMatcher, MatchingMask, BundleAdjuster, Warper, ExposureCompensator,
SeamFinder, Blender) throw NotImplementedException in this port — you cannot
swap stitching stages from managed code. The Detail namespace exposes the
supporting types (ImageFeatures, MatchesInfo, CameraParams,
BestOf2NearestMatcher, AffineBestOf2NearestMatcher).

ARUCO AND CHARUCO MARKERS
=========================
    static Dictionary Cv2.Aruco.GetPredefinedDictionary(
                     PredefinedDictionaryType name)
    static Dictionary Cv2.Aruco.ReadDictionary(string dictionaryFile)
    ArucoDetector(Dictionary dictionary)
    ArucoDetector(Dictionary dictionary, DetectorParameters detectorParams,
                     RefineParameters refineParams)
    void DetectMarkers(InputArray image, out Point2f[][] corners,
                     out int[] ids, out Point2f[][] rejectedImgPoints)
    static void Cv2.Aruco.DrawDetectedMarkers(InputOutputArray image,
                     Point2f[][] corners, IEnumerable<int> ids)
    static void Cv2.Aruco.DrawDetectedMarkers(InputOutputArray image,
                     Point2f[][] corners, IEnumerable<int>? ids,
                     Scalar borderColor)
    Dictionary: Mat BytesList, int MarkerSize, int MaxCorrectionBits,
                void GenerateImageMarker(int id, int sidePixels,
                     OutputArray img, int borderBits = 1),
                bool Identify(...), int GetDistanceToId(...)
    CharucoBoard, CharucoDetector with
        void DetectBoard(InputArray image, out Point2f[] charucoCorners,
                     out int[] charucoIds, out Point2f[][] markerCorners,
                     out int[] markerIds)
        void DetectDiamonds(...)
    Cv2.Aruco.DrawDetectedCornersCharuco / DrawDetectedDiamonds

FACE (contrib)
==============
    static EigenFaceRecognizer EigenFaceRecognizer.Create(
                     int numComponents = 0, double threshold = double.MaxValue)
    static FisherFaceRecognizer FisherFaceRecognizer.Create(
                     int numComponents = 0, double threshold = double.MaxValue)
    static LBPHFaceRecognizer LBPHFaceRecognizer.Create(int radius = 1,
                     int neighbors = 8, int gridX = 8, int gridY = 8,
                     double threshold = double.MaxValue)

    FaceRecognizer (base):
        virtual void Train(IEnumerable<Mat> src, IEnumerable<int> labels)
        void Update(IEnumerable<Mat> src, IEnumerable<int> labels)
        virtual int Predict(InputArray src)
        virtual void Predict(InputArray src, out int label,
                     out double confidence)
        virtual void Write(string fileName) / Read(string fileName)
        void SetLabelInfo(int label, string strInfo)
        string GetLabelInfo(int label)
        double GetThreshold() / void SetThreshold(double val)

    Facial landmarks: Facemark, FacemarkLBF, FacemarkAAM.
    EigenFaceRecognizer and FisherFaceRecognizer derive from
    BasicFaceRecognizer, which adds GetNumComponents/SetNumComponents,
    GetProjections(), GetLabels(), GetEigenValues(), GetEigenVectors() and
    GetMean().
    All three recognizers require equally sized, single-channel training
    images (Eigen and Fisher additionally require identical dimensions).

TEXT AND OCR (contrib)
======================
    static OCRTesseract OCRTesseract.Create(string? datapath = null,
                     string? language = null, string? charWhitelist = null,
                     int oem = 3, int psmode = 3)
    override void Run(Mat image, out string outputText,
                     out Rect[] componentRects, out string?[] componentTexts,
                     out float[] componentConfidences,
                     ComponentLevels componentLevel = ComponentLevels.Word)
    override void Run(Mat image, Mat mask, out string outputText, ...)
    void SetWhiteList(string charWhitelist)

    static TextDetectorCNN TextDetectorCNN.Create(string modelArchFilename,
                     string modelWeightsFilename)
    override void Detect(InputArray inputImage, out Rect[] bbox,
                     out float[] confidence)
    static Rect[] Cv2.Text.DetectTextSWT(InputArray input, bool darkOnLight,
                     OutputArray draw = default,
                     OutputArray chainBBs = default)

    TextDetectorCNN derives from the abstract TextDetector; OCRTesseract
    derives from the abstract BaseOCR.

Tesseract is statically linked into the native library, so OCRTesseract works
with no separate Tesseract install — but you must supply tessdata language
files yourself and point datapath at the folder holding them.

OTHER CONTRIB MODULES SHIPPED
=============================
The left-hand label is the NAMESPACE suffix where one exists — XImgProc,
ImgHash, Quality, Saliency, DnnSuperres, LineDescriptor, Segmentation and
Extensions are real sub-namespaces (for example
"using CodeBrix.VideoProcessing.OpenCV5.XImgProc;"). The shape, superres and
ptcloud types are in the ROOT namespace and need no extra using.

  XImgProc      DTFilter, GuidedFilter, AdaptiveManifoldFilter,
                FastGlobalSmootherFilter, FastBilateralSolverFilter,
                FastLineDetector, EdgeDrawing (+EdgeDrawingParams), EdgeBoxes,
                StructuredEdgeDetection, RFFeatureGetter,
                RidgeDetectionFilter, SuperpixelSLIC, SuperpixelSEEDS,
                SuperpixelLSC, RL, XImgProc; and in the nested
                ...XImgProc.Segmentation namespace GraphSegmentation and
                SelectiveSearchSegmentation (+ its Color/Fill/Size/Texture/
                Multiple strategies)
  ImgHash       AverageHash, PHash, BlockMeanHash, MarrHildrethHash,
                RadialVarianceHash, ColorMomentHash (ImgHashBase)
  Quality       QualityMSE, QualityPSNR, QualitySSIM, QualityGMSD,
                QualityBRISQUE (QualityBase)
  Saliency      StaticSaliencySpectralResidual, StaticSaliencyFineGrained,
                MotionSaliencyBinWangApr2014, ObjectnessBING
  shape         ShapeDistanceExtractor and its implementations
   (root)       ShapeContextDistanceExtractor and HausdorffDistanceExtractor;
                ShapeTransformer and its implementations
                ThinPlateSplineShapeTransformer and AffineTransformer;
                HistogramCostExtractor and its NormHistogramCostExtractor,
                EMDHistogramCostExtractor, EMDL1HistogramCostExtractor and
                ChiHistogramCostExtractor implementations
  superres      SuperResolution, FrameSource, DenseOpticalFlowExt and its
   (root)       implementations BroxOpticalFlow, DualTVL1OpticalFlow,
                FarnebackOpticalFlow, PyrLKOpticalFlow
  DnnSuperres   DnnSuperResImpl (EDSR/ESPCN/FSRCNN/LapSRN upscaling)
  LineDescriptor LSDDetector, KeyLine, LSDParam
  ptcloud       Odometry, OdometryFrame, OdometrySettings, RgbdNormals,
   (root)       Volume, VolumeSettings
  Segmentation  IntelligentScissorsMB (its own top-level sub-namespace,
                ...OpenCV5.Segmentation)
  Extensions    CvExtensions.HoughLinesProbabilisticEx

DNN MODULE
==========
Loading a network
-----------------
    static Net  Cv2.Dnn.ReadNet(string model, string config = "",
                     string framework = "",
                     EngineType engine = EngineType.Auto)
    static Net? Cv2.Dnn.ReadNetFromONNX(string onnxFile,
                     EngineType engine = EngineType.Auto)
    static Net? Cv2.Dnn.ReadNetFromONNX(byte[] | ReadOnlySpan<byte> | Stream,
                     EngineType engine = EngineType.Auto)
    static Net? Cv2.Dnn.ReadNetFromTFLite(string model,
                     EngineType engine = EngineType.Auto)
    static Net? Cv2.Dnn.ReadNetFromTFLite(byte[] | ReadOnlySpan<byte> |
                     Stream, EngineType engine = EngineType.Auto)
    static Net? Cv2.Dnn.ReadNetFromTensorflow(string model,
                     string? config = null, EngineType engine = ...)
    static Net? Cv2.Dnn.ReadNetFromModelOptimizer(string xml, string bin)
    static Mat? Cv2.Dnn.ReadTensorFromONNX(string path)
    The same Read* factories are also static members of Net itself.

Blobs and post-processing
-------------------------
    static Mat Cv2.Dnn.BlobFromImage(Mat image, double scaleFactor = 1.0,
                     Size size = default, Scalar mean = default,
                     bool swapRB = true, bool crop = true)
    static Mat Cv2.Dnn.BlobFromImages(IEnumerable<Mat> images,
                     double scaleFactor, Size size = default,
                     Scalar mean = default, bool swapRB = true,
                     bool crop = true)
    static Mat Cv2.Dnn.BlobFromImageWithParams(InputArray image,
                     Image2BlobParams? param = null)
    static Mat[] Cv2.Dnn.ImagesFromBlob(Mat blob)
    static void Cv2.Dnn.NMSBoxes(IEnumerable<Rect> bboxes,
                     IEnumerable<float> scores, float scoreThreshold,
                     float nmsThreshold, out int[] indices, float eta = 1.0f,
                     int topK = 0)           // Rect2d and RotatedRect too
    static void Cv2.Dnn.NMSBoxesBatched(..., IEnumerable<int> classIds, ...)
    static void Cv2.Dnn.SoftNMSBoxes(...)
    static Target[] Cv2.Dnn.GetAvailableTargets(Backend backend)
    static (Backend Backend, Target Target)[] Cv2.Dnn.GetAvailableBackends()

Net
---
    Mat  Forward(string? outputName = null)
    void Forward(IEnumerable<Mat> outputBlobs, string? outputName = null)
    void Forward(IEnumerable<Mat> outputBlobs,
                 IEnumerable<string> outBlobNames)
    void SetInput(Mat blob, string name = "")
    void SetInputsNames(IEnumerable<string> inputBlobNames)
    void SetInputShape(string inputName, IEnumerable<int> shape)
    void SetPreferableBackend(Backend backendId)
    void SetPreferableTarget(Target targetId)
    bool Empty()
    string?[] GetLayerNames()
    string?[] GetUnconnectedOutLayersNames()
    int[] GetUnconnectedOutLayers()
    string?[] GetLayerTypes()      int GetLayersCount(string layerType)
    int GetLayerId(string layer)
    long GetPerfProfile(out double[] timings)
    void GetPerfProfileDetailed(out string[] names, out string[] timems,
                                out string[] counts)
    long GetFLOPS(MatShape netInputShape, MatType netInputType)
    void GetLayerShapes(...) / GetLayersShapes(...) / GetMemoryConsumption(...)
    Mat GetParam(string layerName, int numParam = 0)
    void SetParam(string layerName, int numParam, Mat blob)
    void EnableFusion(bool fusion)      void EnableWinograd(bool useWinograd)
    void EnableKVCache() / DisableKVCache() / ResetKVCache()
    ModelFormat GetModelFormat()        string Dump() / DumpToFile(string path)
    TracingMode TracingMode             ProfilingMode ProfilingMode
    int RegisterOutput(string outputName, int layerId, int outputPort)

CodeBrix addition (namespace ...OpenCV5.Dnn, class NetExtensions):
    static Mat[] ForwardAll(this Net net, params string[] outBlobNames)

High-level model wrappers (class Model and subclasses)
-----------------------------------------------------
    Model(string model, string? config = null) / Model(Net network)
    void SetInputParams(double scale = 1.0, Size? size = null,
                     Scalar? mean = null, bool swapRB = false,
                     bool crop = false)
    void SetInputSize(Size size) / SetInputSize(int width, int height)
    void SetInputMean(Scalar) / SetInputScale(Scalar) / SetInputCrop(bool)
    void SetInputSwapRB(bool) / SetOutputNames(IEnumerable<string>)
    Mat[] Predict(InputArray frame)

    ClassificationModel:  void Classify(InputArray frame, out int classId,
                                        out float conf)
                          SetEnableSoftmaxPostProcessing(bool)
    DetectionModel:       void Detect(InputArray frame, out int[] classIds,
                                        out float[] confidences,
                                        out Rect[] boxes,
                                        float confThreshold = 0.5f,
                                        float nmsThreshold = 0.0f)
                          SetNmsAcrossClasses(bool)
    SegmentationModel:    void Segment(InputArray frame, OutputArray mask)
    KeypointsModel, TextDetectionModel, TextDetectionModelDB,
    TextDetectionModelEAST, TextRecognitionModel (SetVocabulary,
    SetDecodeType, string Recognize(InputArray frame)), Tokenizer.

USING THE DNN MODULE (TFLITE MODELS, MULTI-OUTPUT NETS, TENSOR ACCESS)
=====================================================================
Lessons learned building a real-time hand-tracking sample that runs Google
MediaPipe TFLite models through this library's DNN module. The pitfalls and
patterns below are general.

TFLite import - what works:
  The shipped natives are built WITH the TFLite importer (flatbuffers), so
  Cv2.Dnn.ReadNetFromTFLite(path | byte[] | span | stream) works out of the
  box. OpenCV's TFLite OPERATOR coverage is partial, though, and unsupported
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
  the 21 landmarks. Implementing GATHER/DENSIFY (likely upstream) would
  unlock the rest.

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

Real-time pipeline shape:
  One worker thread owns the Net objects (they are not thread-safe); frames
  arrive via a single latest-wins pending slot (submitting overwrites the
  previous pending frame), so slow inference drops stale frames instead of
  queueing. Reuse Mats across frames (allocate on size change only). The
  bundled analyzers (OCVS001-004) flag the per-frame P/Invoke and disposal
  mistakes that creep into exactly this kind of loop.

HIGHGUI WINDOWS
===============
    static void Cv2.ImShow(string winName, Mat mat)
    static int  Cv2.WaitKey(int delay = 0)
    static int  Cv2.WaitKeyEx(int delay = 0)
    static void Cv2.NamedWindow(string winName,
                     WindowFlags flags = WindowFlags.Normal)
    static void Cv2.DestroyWindow(string winName)
    static void Cv2.DestroyAllWindows()
    static void Cv2.ResizeWindow(string winName, int width, int height)
    static void Cv2.MoveWindow(string winName, int x, int y)
    static void Cv2.SetWindowTitle(string winName, string title)
    static void Cv2.SetMouseCallback(string windowName, MouseCallback onMouse,
                     IntPtr userData = default)
    static int  Cv2.CreateTrackbar(string trackbarName, string winName,
                     ref int value, int count,
                     TrackbarCallbackNative? onChange = null,
                     IntPtr userData = default)

An object-oriented wrapper also exists: `Window` (IDisposable) with
ShowImage, Move, Resize, GetProperty/SetProperty, CreateTrackbar, the static
Window.WaitKey / Window.ShowImages / Window.GetWindowByName, plus CvTrackbar.

The highgui windows need a GUI session. On Linux they need the GTK-3 stack
listed under LINUX SYSTEM PREREQUISITES and a running display server; in a
headless container ImShow will fail. Everything else in the library works
headless.

ERROR MODEL AND DISPOSAL
========================
  OpenCVException — thrown when NATIVE OpenCV raises an error. Carries
      ErrorCode Status, string FuncName, string ErrMsg, string FileName and
      int Line, in addition to Message. Catch this for "the image was the
      wrong type / the file did not decode / the assertion failed".
  OpenCvSharpException — the managed-side exception. Used for binding-level
      failures: a native library that would not load (with the diagnostic
      message described below, and the original runtime exception as
      InnerException), and Mat.ToArray<T> misuse.
  Ordinary ArgumentNullException / ArgumentException / ObjectDisposedException
      come from the managed argument checks.

Details of a native error are captured on the calling thread directly from
the thrown C++ exception; no managed error callback is installed by default,
which keeps the default path NativeAOT- and trimming-friendly. You can
install one anyway with Cv2.SetErrorHandler(CvErrorCallback? errorHandler)
(pass null to restore the silent default) — opt in only if you need it,
because it puts a managed delegate back into the native error path.

Disposal
--------
Every native-backed type derives from CvObject : IDisposable and exposes
bool IsDisposed, IntPtr CvPtr and void ThrowIfDisposed(). Mat, UMat,
VideoCapture, VideoWriter, Net, every Feature2D / DescriptorMatcher /
StatModel / Tracker / BackgroundSubtractor, CascadeClassifier, Window — all
of them must be disposed. `using var` is the house style. Mats returned from
Row/Col/SubMat/Clone/Split/ForwardAll are yours to dispose too.

A background thread that calls into native OpenCV while the process is
shutting down is handled for you: teardown-time native failures ("Can't
fetch data from terminated TLS container") are swallowed instead of turning
an orderly exit into a fatal unhandled exception on that thread.

BUNDLED ROSLYN ANALYZERS
========================
The core package ships four analyzers under analyzers/dotnet/cs; they run in
YOUR build automatically once you reference the package. All are warnings.

  OCVS001  Correctness  At<T>(int) called on a Mat row submatrix.
           mat.Row(i) returns a 1xN 2-D submatrix, so At<T>(int i0) treats
           i0 as a ROW index, not a column index — silently wrong results or
           out-of-bounds access. Use mat.At<T>(row, col) or mat.AsRows<T>().
  OCVS002  Performance  Mat property (Rows/Cols/Dims/Width/Height) evaluated
           in a loop condition. Each is a P/Invoke; cache it in a local
           before the loop.
  OCVS003  Performance  Mat.Row() / Mat.Col() called inside a loop body.
           Each call allocates a native Mat header. Take mat.AsRows<T>()
           once before the loop and index it.
  OCVS004  Reliability  Mat submatrix from Row/Col/RowRange/ColRange never
           disposed. Wrap it in `using`, or avoid the allocation with
           AsRows<T>().

Do not suppress these wholesale — each marks a real defect class. Fix the
code instead.

NATIVE LIBRARY LOADING AND DIAGNOSTICS
======================================
The managed core P/Invokes one native library named "OpenCvSharpExtern"
(OpenCvSharpExtern.dll / libOpenCvSharpExtern.so / libOpenCvSharpExtern.dylib)
that statically links OpenCV 5 plus opencv_contrib. The load happens lazily,
inside the static constructor of the internal NativeMethods class, which runs
the first time you touch ANY API — typically `new Mat()`.

When the load fails, the package does NOT surface the runtime's raw
DllNotFoundException (whose message buries the loader's real error in a wall
of per-probe "cannot open shared object file" lines). Instead you get an
OpenCvSharpException, with the original exception as InnerException and a
root-cause-first message that distinguishes four cases:

  * NOT FOUND in any probing directory — the message lists every directory
    probed and names the exact runtime package to add for the current RID
    (e.g. "CodeBrix.VideoProcessing.OpenCV5.LinuxArm64.ApacheLicenseForever").
    This is a missing-package-reference or missing-RID problem.
  * FOUND but the OS loader REJECTED it — the message surfaces the loader's
    own error, which almost always names a missing NATIVE DEPENDENCY of the
    OpenCV library rather than the library itself, and adds the right
    inspection command for the OS (`ldd`, `otool -L`, `dumpbin /dependents`).
    On Linux this is nearly always the GTK-3/X11 stack; install it.
  * FOUND but the wrong CPU ARCHITECTURE for this process.
  * FOUND and loads fine on its own — a probing/deployment mismatch. Either
    ship it through the runtime package so it lands in a probed directory,
    or pre-load it yourself with NativeLibrary.Load(path).

Two pre-flight hooks are public (namespace ...OpenCV5.Internal, class
NativeMethods) if you want to validate before any real work:

    NativeMethods.LoadLibraries();   // trigger resolution now
    NativeMethods.TryPInvoke();      // call once; throws the same
                                     // diagnostic-bearing exception, and
                                     // also writes it to Console/Debug

Call TryPInvoke() after installing any custom loading (for example
NativeLibrary.SetDllImportResolver) to fail fast with a readable message.

WPF INTEROP (CodeBrix.VideoProcessing.OpenCV5.Wpf package)
==========================================================
Namespace: CodeBrix.VideoProcessing.OpenCV5.Wpf. Two static EXTENSION classes.

WriteableBitmapConverter
    static WriteableBitmap ToWriteableBitmap(this Mat src)
    static WriteableBitmap ToWriteableBitmap(this Mat src, PixelFormat pf)
    static WriteableBitmap ToWriteableBitmap(this Mat src, double dpiX,
                     double dpiY, PixelFormat pf, BitmapPalette? bp)
    static void ToWriteableBitmap(Mat src, WriteableBitmap dst)  // in place
    static Mat  ToMat(this WriteableBitmap src)
    static void ToMat(this WriteableBitmap src, Mat dst)

BitmapSourceConverter
    static BitmapSource ToBitmapSource(this Mat src)
    static BitmapSource ToBitmapSource(this Mat src, int horizontalResolution,
                     int verticalResolution, PixelFormat pixelFormat,
                     BitmapPalette palette)
    static BitmapSource ToBitmapSource(this System.Drawing.Bitmap src)
    static Mat  ToMat(this BitmapSource src)
    static void ToMat(this BitmapSource src, Mat dst)

PixelFormat here is System.Windows.Media.PixelFormat. The parameterless
overloads pick the format from the Mat type; the supported mapping is:

    CV_8UC1  / CV_8SC1  -> Gray8        CV_8UC3  / CV_8SC3  -> Bgr24
    CV_8UC4  / CV_8SC4  -> Bgra32       CV_16UC1 / CV_16SC1 -> Gray16
    CV_16UC3 / CV_16SC3 -> Rgb48        CV_16UC4 / CV_16SC4 -> Rgba64
    CV_32SC4            -> Prgba64      CV_32FC1            -> Gray32Float
    CV_32FC3            -> Rgb128Float  CV_32FC4            -> Rgba128Float

Any other MatType throws ArgumentOutOfRangeException("Not supported MatType").
The in-place ToWriteableBitmap(Mat, WriteableBitmap) and ToMat(..., Mat)
overloads require matching sizes (and matching channel counts) and throw
ArgumentException otherwise — but they let you reuse one WriteableBitmap for
every video frame instead of allocating per frame, which is what you want in
a live-preview loop.

WPF example — show a camera frame in an Image control:

    using System;
    using System.Windows;
    using System.Windows.Media.Imaging;
    using CodeBrix.VideoProcessing.OpenCV5;
    using CodeBrix.VideoProcessing.OpenCV5.Wpf;

    public partial class MainWindow : Window
    {
        private readonly VideoCapture capture = new(0);
        private readonly Mat frame = new();
        private WriteableBitmap? bitmap;

        private void OnTick(object sender, EventArgs e)
        {
            if (!capture.Read(frame) || frame.Empty())
                return;

            //Allocate once, then reuse the same WriteableBitmap.
            bitmap ??= frame.ToWriteableBitmap();
            WriteableBitmapConverter.ToWriteableBitmap(frame, bitmap);
            PreviewImage.Source = bitmap;   //<Image x:Name="PreviewImage"/>
        }
    }

COMPLETE EXAMPLES
=================
1. Read, resize, convert and save
---------------------------------
    using CodeBrix.VideoProcessing.OpenCV5;

    using var src = Cv2.ImRead("input.jpg", ImreadModes.Color);
    if (src.Empty())
        throw new InvalidOperationException("input.jpg could not be read.");

    using var small = new Mat();
    Cv2.Resize(src, small, new Size(640, 480), 0, 0,
        InterpolationFlags.Area);

    using var gray = new Mat();
    Cv2.CvtColor(small, gray, ColorConversionCodes.BGR2GRAY);

    Cv2.ImWrite("small.png", small);
    Cv2.ImWrite("gray.jpg", gray,
        new ImageEncodingParam(ImwriteFlags.JpegQuality, 90));

2. Edges and contours, then annotate
------------------------------------
    using var src = Cv2.ImRead("shapes.png", ImreadModes.Color);
    using var gray = new Mat();
    Cv2.CvtColor(src, gray, ColorConversionCodes.BGR2GRAY);

    using var blurred = new Mat();
    Cv2.GaussianBlur(gray, blurred, new Size(5, 5), 1.5);

    using var edges = new Mat();
    Cv2.Canny(blurred, edges, 80, 160);

    Cv2.FindContours(edges, out Point[][] contours,
        out HierarchyIndex[] hierarchy,
        RetrievalModes.External, ContourApproximationModes.ApproxSimple);

    foreach (var contour in contours)
    {
        if (Cv2.ContourArea(contour) < 100)
            continue;

        Rect box = Cv2.BoundingRect(contour);
        Cv2.Rectangle(src, box, Scalar.Lime, 2);
        Cv2.PutText(src, $"{Cv2.ContourArea(contour):F0}",
            new Point(box.X, box.Y - 4),
            HersheyFonts.HersheySimplex, 0.5, Scalar.Yellow, 1,
            LineTypes.AntiAlias);
    }

    Cv2.DrawContours(src, contours, -1, Scalar.Red, 1);
    Cv2.ImWrite("annotated.png", src);

3. Threshold, morphology and a binary mask
------------------------------------------
    using var gray = Cv2.ImRead("scan.png", ImreadModes.Grayscale);
    using var binary = new Mat();
    double used = Cv2.Threshold(gray, binary, 0, 255,
        ThresholdTypes.Binary | ThresholdTypes.Otsu);
    Console.WriteLine($"Otsu picked threshold {used}");

    using var kernel = Cv2.GetStructuringElement(MorphShapes.Rect,
        new Size(3, 3));
    using var cleaned = new Mat();
    Cv2.MorphologyEx(binary, cleaned, MorphTypes.Open, kernel,
        iterations: 2);
    Cv2.ImWrite("mask.png", cleaned);

4. Webcam capture loop with FPS and a live window
-------------------------------------------------
    using var capture = VideoCapture.FromCamera(0);
    if (!capture.IsOpened())
        throw new InvalidOperationException("No camera at index 0.");

    capture.Set(VideoCaptureProperties.FrameWidth, 1280);
    capture.Set(VideoCaptureProperties.FrameHeight, 720);

    using var frame = new Mat();          //reuse the SAME Mat every frame
    long frequency = (long)Cv2.GetTickFrequency();
    long previous = Cv2.GetTickCount();

    while (true)
    {
        if (!capture.Read(frame) || frame.Empty())
            break;

        long now = Cv2.GetTickCount();
        double fps = frequency / (double)(now - previous);
        previous = now;

        Cv2.PutText(frame, $"{fps:F1} fps", new Point(12, 32),
            HersheyFonts.HersheySimplex, 1.0, Scalar.Lime, 2);

        Cv2.ImShow("camera", frame);
        if (Cv2.WaitKey(1) == 27)         //Esc
            break;
    }
    Cv2.DestroyAllWindows();

5. Transcode a video file, converting every frame to grayscale
---------------------------------------------------------------
    using var capture = VideoCapture.FromFile("input.mp4");
    if (!capture.IsOpened())
        throw new InvalidOperationException("input.mp4 could not be opened.");

    var size = new Size(capture.FrameWidth, capture.FrameHeight);
    double fps = capture.Fps > 0 ? capture.Fps : 30.0;

    using var writer = new VideoWriter("output.avi", FourCC.MJPG, fps, size);
    if (!writer.IsOpened())
        throw new InvalidOperationException("Could not open the writer.");

    using var frame = new Mat();
    using var gray = new Mat();
    using var bgr = new Mat();

    while (capture.Read(frame) && !frame.Empty())
    {
        Cv2.CvtColor(frame, gray, ColorConversionCodes.BGR2GRAY);
        Cv2.CvtColor(gray, bgr, ColorConversionCodes.GRAY2BGR);
        writer.Write(bgr);                //must match `size` and be 3-channel
    }

6. ORB features and brute-force matching between two images
------------------------------------------------------------
    using System;      //Array.Sort
    using System.Linq;  //Take

    using var img1 = Cv2.ImRead("left.png", ImreadModes.Grayscale);
    using var img2 = Cv2.ImRead("right.png", ImreadModes.Grayscale);

    using var orb = ORB.Create(1000);
    using var desc1 = new Mat();
    using var desc2 = new Mat();
    orb.DetectAndCompute(img1, default, out KeyPoint[] kp1, desc1);
    orb.DetectAndCompute(img2, default, out KeyPoint[] kp2, desc2);

    using var matcher = new BFMatcher(NormTypes.Hamming, crossCheck: true);
    DMatch[] matches = matcher.Match(desc1, desc2);
    Array.Sort(matches, (a, b) => a.Distance.CompareTo(b.Distance));
    DMatch[] best = matches.Take(50).ToArray();

    using var canvas = new Mat();
    Cv2.DrawMatches(img1, kp1, img2, kp2, best, canvas);
    Cv2.ImWrite("matches.png", canvas);

7. Face detection with a Haar cascade
--------------------------------------
    using var cascade = new CascadeClassifier(
        "haarcascade_frontalface_default.xml");
    if (cascade.Empty())
        throw new InvalidOperationException("Cascade XML did not load.");

    using var image = Cv2.ImRead("people.jpg", ImreadModes.Color);
    using var gray = new Mat();
    Cv2.CvtColor(image, gray, ColorConversionCodes.BGR2GRAY);
    Cv2.EqualizeHist(gray, gray);

    Rect[] faces = cascade.DetectMultiScale(gray, 1.1, 4,
        minSize: new Size(48, 48));

    foreach (Rect face in faces)
        Cv2.Rectangle(image, face, Scalar.Lime, 2);

    Cv2.ImWrite("faces.png", image);

8. Background subtraction over a video
---------------------------------------
    using var capture = VideoCapture.FromFile("street.mp4");
    using var subtractor = BackgroundSubtractorMOG2.Create(
        history: 500, varThreshold: 16, detectShadows: true);

    using var frame = new Mat();
    using var mask = new Mat();

    while (capture.Read(frame) && !frame.Empty())
    {
        subtractor.Apply(frame, mask);
        int movingPixels = Cv2.CountNonZero(mask);
        //...act on movingPixels...
    }

9. Reading pixels fast, three ways
-----------------------------------
    using var image = Cv2.ImRead("photo.png", ImreadModes.Color); //CV_8UC3

    //(a) one element - convenient, one P/Invoke per call
    Vec3b pixel = image.Get<Vec3b>(10, 20);      //(row, col)

    //(b) whole rows - no P/Invoke, no allocation (2-D Mats only)
    var rows = image.AsRows<Vec3b>();
    int rowCount = rows.Count;                   //cache; never in the
    for (int y = 0; y < rowCount; y++)           //loop condition
    {
        Span<Vec3b> row = rows[y];
        for (int x = 0; x < row.Length; x++)
            row[x] = new Vec3b(row[x].Item2, row[x].Item1, row[x].Item0);
    }

    //(c) the whole buffer as one managed array (continuous Mats only)
    byte[] raw = image.ToArray<byte>();

10. ONNX object detection with the high-level DetectionModel
------------------------------------------------------------
    using CodeBrix.VideoProcessing.OpenCV5.Dnn;

    using var model = new DetectionModel("yolo.onnx");
    model.SetInputParams(scale: 1.0 / 255, size: new Size(640, 640),
        mean: new Scalar(0, 0, 0), swapRB: true, crop: false);

    using var image = Cv2.ImRead("street.jpg", ImreadModes.Color);
    model.Detect(image, out int[] classIds, out float[] confidences,
        out Rect[] boxes, confThreshold: 0.4f, nmsThreshold: 0.45f);

    for (int i = 0; i < boxes.Length; i++)
    {
        Cv2.Rectangle(image, boxes[i], Scalar.Lime, 2);
        Cv2.PutText(image, $"{classIds[i]} {confidences[i]:F2}",
            new Point(boxes[i].X, boxes[i].Y - 6),
            HersheyFonts.HersheySimplex, 0.5, Scalar.Yellow, 1);
    }
    Cv2.ImWrite("detections.png", image);

11. Train and use an SVM (without TrainData)
---------------------------------------------
    using CodeBrix.VideoProcessing.OpenCV5.ML;

    //4 samples x 2 features, CV_32FC1; labels are CV_32SC1 for a classifier.
    float[] features = { 1f, 1f,  2f, 2f,  8f, 8f,  9f, 9f };
    int[] labels = { 0, 0, 1, 1 };

    using var samples = Mat.FromPixelData(4, 2, MatType.CV_32FC1, features);
    using var responses = Mat.FromPixelData(4, 1, MatType.CV_32SC1, labels);

    using var svm = SVM.Create();
    svm.Type = SVM.Types.CSvc;
    svm.KernelType = SVM.KernelTypes.Linear;
    svm.TermCriteria = new TermCriteria(
        CriteriaTypes.MaxIter | CriteriaTypes.Eps, 1000, 1e-6);

    svm.Train(samples, SampleTypes.RowSample, responses);

    using var query = Mat.FromPixelData(1, 2, MatType.CV_32FC1,
        new float[] { 8.5f, 8.5f });
    float predicted = svm.Predict(query);   //-> 1

MINIMUM VIABLE PROJECT
======================
Linux x64
---------
    MyVision/MyVision.csproj

    <Project Sdk="Microsoft.NET.Sdk">
      <PropertyGroup>
        <OutputType>Exe</OutputType>
        <TargetFramework>net10.0</TargetFramework>
        <Nullable>enable</Nullable>
      </PropertyGroup>
      <ItemGroup>
        <PackageReference
          Include="CodeBrix.VideoProcessing.OpenCV5.ApacheLicenseForever" />
        <PackageReference
          Include="CodeBrix.VideoProcessing.OpenCV5.LinuxX64.ApacheLicenseForever" />
      </ItemGroup>
    </Project>

(No Version attributes are shown because package versions go stale in
documentation. Either add the packages with
`dotnet add package <id>`, which writes the current version in for you, or
keep the bare form above and pin the versions in a Directory.Packages.props
under Central Package Management.)

    MyVision/Program.cs

    using System;
    using CodeBrix.VideoProcessing.OpenCV5;

    using var image = new Mat(240, 320, MatType.CV_8UC3, Scalar.Black);
    Cv2.Circle(image, new Point(160, 120), 80, Scalar.Lime, 3);
    Cv2.PutText(image, "OpenCV 5", new Point(90, 128),
        HersheyFonts.HersheySimplex, 1.0, Scalar.White, 2);
    Cv2.ImWrite("hello.png", image);
    Console.WriteLine($"{image.Rows}x{image.Cols}, {image.Type()}");

    Prerequisite on a headless image:
        sudo apt-get install -y libgtk-3-0 libx11-6
    Then:
        dotnet run

macOS (Apple silicon)
---------------------
Same csproj, but reference
CodeBrix.VideoProcessing.OpenCV5.MacOSArm64.ApacheLicenseForever
(MacOSX64 on Intel). No system prerequisites.

Windows x64
-----------
Same csproj, but reference
CodeBrix.VideoProcessing.OpenCV5.WindowsX64.ApacheLicenseForever
(WindowsArm64 on ARM). No system prerequisites. For a WPF app also add
CodeBrix.VideoProcessing.OpenCV5.Wpf.ApacheLicenseForever and set
<TargetFramework>net10.0-windows</TargetFramework> with <UseWPF>true</UseWPF>.

Cross-platform console app that runs anywhere
---------------------------------------------
Reference the core plus every native package you support:

      <ItemGroup>
        <PackageReference
          Include="CodeBrix.VideoProcessing.OpenCV5.ApacheLicenseForever" />
        <PackageReference
          Include="CodeBrix.VideoProcessing.OpenCV5.WindowsX64.ApacheLicenseForever" />
        <PackageReference
          Include="CodeBrix.VideoProcessing.OpenCV5.LinuxX64.ApacheLicenseForever" />
        <PackageReference
          Include="CodeBrix.VideoProcessing.OpenCV5.LinuxArm64.ApacheLicenseForever" />
        <PackageReference
          Include="CodeBrix.VideoProcessing.OpenCV5.MacOSArm64.ApacheLicenseForever" />
      </ItemGroup>

PERFORMANCE TIPS
================
  * Allocate Mats ONCE and reuse them across frames. In a capture loop,
    create `frame`, `gray`, `blob` outside the loop and let the Cv2 functions
    resize them. Per-frame `new Mat()` is the single biggest avoidable cost.
  * Never put mat.Rows / Cols / Dims / Width / Height in a loop condition —
    each is a P/Invoke. Cache them in locals (analyzer OCVS002 flags this).
  * For per-pixel work use mat.AsRows<T>() (a ref struct over the raw buffer:
    no P/Invoke, no allocation, Span<T> per row) rather than Row()/Col() or
    per-element Get<T>/At<T>. Row()/Col() inside a loop allocates a native
    header on every iteration (OCVS003 / OCVS004).
  * mat.AsSpan<T>() gives the whole buffer as a Span for continuous Mats;
    check IsContinuous() first, because it returns an empty span otherwise.
  * Prefer InterpolationFlags.Area for downscaling — it is both faster and
    better looking than Linear at large reduction factors.
  * Convert to grayscale before detection/feature work; a 3x reduction in
    data usually dominates the cost of the conversion.
  * Cv2.SetNumThreads(n) bounds OpenCV's internal thread pool. Set it low
    when several pipelines share a machine; Cv2.GetNumThreads() reports the
    current value and Cv2.UseOptimized() / SetUseOptimized(bool) toggle the
    optimised code paths.
  * Time with Cv2.GetTickCount() / Cv2.GetTickFrequency() rather than
    Stopwatch when you want to compare against OpenCV's own numbers.
  * DNN: keep one Net per worker thread (Net is NOT thread-safe), reuse the
    input blob Mat, and use net.ForwardAll(...) for multi-output models —
    with an unchanged input the extra outputs reuse already-computed layers
    and are nearly free. net.GetPerfProfile(out double[] timings) gives
    per-layer timings.
  * On Windows, reuse a single WriteableBitmap and call the in-place
    WriteableBitmapConverter.ToWriteableBitmap(Mat, WriteableBitmap) rather
    than allocating a bitmap per frame.
  * Video encoding: FourCC.MJPG is cheap and universally available;
    FourCC.X264 / H264 gives far smaller files but leans on the platform's
    codec support (on win-x64 that means the bundled FFmpeg videoio plugin).

COMMON PITFALLS TO AVOID
========================
  * Forgetting the native runtime package. The core package alone compiles
    fine and then throws OpenCvSharpException at the first `new Mat()`. The
    exception message names the exact package to add — read it.
  * Assuming a native RID package pulls in the core (or vice versa). Neither
    depends on the other; reference both.
  * Cv2.ImRead does not throw on a missing or unreadable file — it returns a
    Mat whose Empty() is true. Check every load.
  * Not disposing Mats returned by Row(), Col(), RowRange(), ColRange(),
    SubMat(), Clone(), Cv2.Split() or net.ForwardAll(). They are native
    allocations; the finalizer is not a plan.
  * mat.Row(i).At<T>(j) is WRONG. Row(i) returns a 1xN two-dimensional Mat,
    so At<T>(int) indexes its ROW dimension. Use mat.At<T>(i, j) or
    mat.AsRows<T>() (analyzer OCVS001).
  * GetArray<T> / GetRectangularArray<T> silently cannot handle a Mat with
    Dims > 2 (Rows and Cols are -1 there). Use ToArray<T>() for DNN tensors.
  * ToArray<T>() requires a CONTINUOUS Mat. A SubMat/ROI view is not
    continuous — Clone() it first.
  * InputArray / OutputArray / InputOutputArray are ref structs. You cannot
    store one in a field, capture one in a lambda, or hold one across an
    await. Pass Mats; write `default`, not `null`, for an omitted optional
    InputArray.
  * Colour order is BGR, not RGB. Scalar.FromRgb and the named colours
    already account for it, but raw byte triples do not, and DNN models
    almost always want swapRB: true.
  * Cv2.Dnn.BlobFromImage accepts 1- and 3-channel images only. Convert a
    4-channel BGRA frame with ColorConversionCodes.BGRA2BGR first.
  * VideoWriter silently produces an unusable file if IsOpened() is false or
    if a written frame's size differs from the frameSize it was opened with.
    Check IsOpened() and keep the sizes identical.
  * VideoCapture.Read returns false at end of stream AND on a transient
    grab failure; also test frame.Empty().
  * Net objects are not thread-safe. One Net per worker thread.
  * ml.TrainData is not implemented — its constructor throws. Use
    StatModel.Train(InputArray samples, SampleTypes layout,
    InputArray responses) and build the sample/label Mats yourself.
  * Stitcher's component properties (FeaturesFinder, Blender, Warper, ...)
    throw NotImplementedException. Only the high-level Stitch path works.
  * Cv2.ImShow and the Window class need a GUI session plus, on Linux, the
    GTK-3 stack. In a container they will fail; everything else works
    headless.
  * Do not reference OpenCvSharp packages alongside this one, and do not
    write OpenCvSharp namespaces — the type names are identical, so mixing
    the two produces ambiguous-reference errors rather than a clear failure.
  * The package IDS carry .ApacheLicenseForever; the NAMESPACES do not.

WHAT THIS PACKAGE DOES NOT DO
=============================
  * It does not ship OpenCV's CUDA modules — there is no cv::cuda surface and
    no GPU-accelerated variant of the algorithms. DNN inference runs on the
    CPU backend; Backend/Target enums exist, but only the targets the shipped
    native build supports are available (query
    Cv2.Dnn.GetAvailableBackends()).
  * It does not implement ml.TrainData, StatModel.Train(TrainData, int),
    StatModel.CalcError, SVM.TrainAuto, or Stitcher's pipeline-component
    properties. Those members throw NotImplementedException.
  * It does not provide OpenCV's Python/JavaScript/WASM bindings, and there
    is no browser-WASM runtime package.
  * It does not ship native binaries for any RID other than the seven listed
    — no win-x86, no linux-musl, no Android or iOS runtime packages, no
    32-bit ARM.
  * It does not carry any GUI toolkit of its own beyond OpenCV's own highgui
    windows; the only UI interop shipped is the WPF converter package
    (Windows-only). There is no WinForms, MAUI, Avalonia or Skia bridge here.
  * It does not download models, cascades, or tessdata for you. Supply your
    own .onnx / .tflite / .xml / traineddata files.
  * It does not bundle the OpenCV sample data set or any test images.
  * It does not install system libraries. On Linux the GTK-3 / X11 runtime
    is your responsibility (see LINUX SYSTEM PREREQUISITES).
  * It is not a drop-in for OpenCvSharp 4.x: this tracks OpenCV 5 and the
    OpenCvSharp5 API, where InputArray/OutputArray are ref structs, the
    pixel-data constructors were replaced by Mat.FromPixelData, and several
    4.x helpers no longer exist.

WORKING EXAMPLES ON GITHUB
==========================
The ported upstream test suite is the largest body of worked examples for
this API. Browse it at:

  https://github.com/ellisnet/CodeBrix.VideoProcessing.OpenCV5/tree/main/tests/CodeBrix.VideoProcessing.OpenCV5.Tests

Feature area -> test folder/file:

  Mat, MatExpr, MatType, structs, PCA/SVD/RNG/FileStorage
      tests/CodeBrix.VideoProcessing.OpenCV5.Tests/core/
      (MatTests.cs, MatToArrayTests.cs, MatExprTests.cs, MatShapeTests.cs,
       MatTypeTests.cs, InputArrayTests.cs, RectTests.cs, RotatedRectTests.cs,
       PCATests.cs, LDATests.cs, RNGTests.cs, FileStorageTests.cs,
       CoreTests.cs, AlgorithmTests.cs)
  Image I/O and encoding parameters
      tests/CodeBrix.VideoProcessing.OpenCV5.Tests/imgcodecs/ImgCodecsTests.cs
  Filtering, contours, drawing, CLAHE, Hough, Subdiv2D, undistort
      tests/CodeBrix.VideoProcessing.OpenCV5.Tests/imgproc/
      (ImgProcTests.cs, ImgProcMediumTests.cs, CLAHETests.cs,
       ConnectedComponentsTests.cs, LineIteratorTests.cs,
       LineSegmentDetectorTests.cs, GeneralizedHoughTests.cs,
       Subdiv2DTests.cs, UndistortTests.cs, FontFaceTests.cs,
       IntelligentScissorsMBTests.cs, AlgorithmHintTests.cs)
  VideoCapture / VideoWriter / FourCC
      tests/CodeBrix.VideoProcessing.OpenCV5.Tests/videoio/
      (VideoCaptureTests.cs, VideoWriterTests.cs)
  SIFT/ORB/AKAZE/DISK/ALIKED, BFMatcher, FLANN matching
      tests/CodeBrix.VideoProcessing.OpenCV5.Tests/features/
      (SIFTTests.cs, ORBTests.cs, AffineFeatureTests.cs,
       FastFeatureDetectorTests.cs, AGASTTests.cs, ANNIndexTests.cs,
       FlannBasedMatcherTests.cs, DiskAlikedLightGlueTests.cs,
       FeaturesCoverageTests.cs)
      and tests/.../xfeatures2d/, tests/.../flann/IndexTests.cs
  Calibration, PnP, homography, stereo, fisheye
      tests/CodeBrix.VideoProcessing.OpenCV5.Tests/calib3d/
      (Calib3dTests.cs, GeometryFunctionsTests.cs, FishEyeTests.cs,
       StereoBMTests.cs, StereoSGBMTests.cs, StereoRectificationTests.cs,
       MultiviewCalibrationTests.cs, UsacParamsTests.cs)
  CascadeClassifier, QRCodeDetector, HOGDescriptor, FaceDetectorYN
      tests/CodeBrix.VideoProcessing.OpenCV5.Tests/objdetect/
  SVM, RTrees, KNearest, ANN_MLP, Boost, EM, NormalBayes
      tests/CodeBrix.VideoProcessing.OpenCV5.Tests/ml/
  Optical flow, background subtraction, Kalman, trackers
      tests/CodeBrix.VideoProcessing.OpenCV5.Tests/video/
      (OptFlowTests.cs, BackgroundSubtractorMOG2Tests.cs,
       BackgroundSubtractorKNNTests.cs, KalmanTests.cs,
       VideoTrackingTests.cs)
      and tests/.../tracking/ (TrackerCSRTTests.cs, TrackerKCFTests.cs,
       TrackerMILTests.cs)
  DNN: nets, blobs, NMS, models, TFLite, ForwardAll, tracing
      tests/CodeBrix.VideoProcessing.OpenCV5.Tests/dnn/
      (NetTests.cs, NetExtensionsTests.cs, NetIntrospectionTests.cs,
       DnnTests.cs, ModelTests.cs, BlobAndNmsTests.cs, TensorflowTests.cs,
       EastTextDetectionTests.cs, TextModelTests.cs,
       EngineSelectionTests.cs, PerfProfileDetailedTests.cs,
       DnnUnicodePathTests.cs)
  Photo / HDR / tonemapping
      tests/CodeBrix.VideoProcessing.OpenCV5.Tests/photo/
  Stitching, ArUco, face, text/OCR, img_hash, quality, saliency, shape,
  superres, ximgproc, xphoto, line_descriptor, wechat_qrcode, barcode,
  dnn_superres, ptcloud
      the matching folder under
      tests/CodeBrix.VideoProcessing.OpenCV5.Tests/
  Native-load failure diagnostics
      tests/CodeBrix.VideoProcessing.OpenCV5.Tests/NativeLoadDiagnosticsTests.cs
  Analyzer behaviour (OCVS001-004)
      https://github.com/ellisnet/CodeBrix.VideoProcessing.OpenCV5/tree/main/tests/CodeBrix.VideoProcessing.OpenCV5.Analyzers.Tests
  WPF converters
      https://github.com/ellisnet/CodeBrix.VideoProcessing.OpenCV5/tree/main/tests/CodeBrix.VideoProcessing.OpenCV5.Wpf.Tests

Because only the namespaces were changed, upstream OpenCvSharp5 samples and
answers port by rewriting `using OpenCvSharp...` to
`using CodeBrix.VideoProcessing.OpenCV5...`.

QUICK REFERENCE CARD
====================
    Packages   core .ApacheLicenseForever + one native RID package per
               platform (+ .Wpf on Windows). Neither depends on the other.
    Usings     using CodeBrix.VideoProcessing.OpenCV5;  (+ .Dnn, .ML, .Aruco,
               .Face, .Text, .Tracking, .XImgProc, .XFeatures2D, .Wpf)

    Load/save  Cv2.ImRead(path, ImreadModes.Color) -> Mat (Empty() on failure)
               Cv2.ImWrite(path, mat[, ImageEncodingParam...])
               Cv2.ImDecode(bytes, mode) / Cv2.ImEncode(".png", mat, out buf)
    Create     new Mat(rows, cols, MatType.CV_8UC3, Scalar.Black)
               Mat.FromPixelData(rows, cols, type, array[, step])
               Mat.Zeros/Ones/Eye (MatExpr) or ZerosMat/OnesMat/EyeMat (Mat)
    Inspect    mat.Rows, mat.Cols, mat.Type(), mat.Channels(), mat.Empty(),
               mat.IsContinuous(), mat.Total(), mat.Dump()
    Access     mat.Get<Vec3b>(y, x) / mat.Set<Vec3b>(y, x, v)
               mat.At<T>(y, x)      mat.AsRows<T>()[y] -> Span<T>
               mat.ToArray<T>()     mat.AsSpan<T>()
    Views      mat.SubMat(rect) / mat[rect] / mat.Row(y) / mat.Col(x)
               -> all are NEW Mats you must dispose
    Resize     Cv2.Resize(src, dst, new Size(w, h), 0, 0,
                          InterpolationFlags.Area)
    Colour     Cv2.CvtColor(src, dst, ColorConversionCodes.BGR2GRAY)
    Blur/edge  Cv2.GaussianBlur(src, dst, new Size(5,5), 1.5)
               Cv2.Canny(src, edges, 80, 160)
    Threshold  Cv2.Threshold(src, dst, 0, 255,
                          ThresholdTypes.Binary | ThresholdTypes.Otsu)
    Contours   Cv2.FindContours(bin, out Point[][] c,
                          out HierarchyIndex[] h, RetrievalModes.External,
                          ContourApproximationModes.ApproxSimple)
               Cv2.DrawContours(img, c, -1, Scalar.Lime, 2)
    Draw       Cv2.Rectangle / Circle / Line / Ellipse / Polylines / FillPoly
               Cv2.PutText(img, s, org, HersheyFonts.HersheySimplex, 1.0,
                          Scalar.White, 2)
    Warp       Cv2.GetRotationMatrix2D(center, angle, scale) +
               Cv2.WarpAffine(src, dst, m, size)
    Camera     using var cap = VideoCapture.FromCamera(0);
               cap.Set(VideoCaptureProperties.FrameWidth, 1280);
               while (cap.Read(frame) && !frame.Empty()) { ... }
    Write vid  new VideoWriter(path, FourCC.MJPG, fps, size); writer.Write(m)
    Features   ORB.Create(1000) / SIFT.Create();
               orb.DetectAndCompute(img, default, out kp, desc);
               new BFMatcher(NormTypes.Hamming, crossCheck: true).Match(a, b)
    Detect     new CascadeClassifier(xml).DetectMultiScale(gray)
               new QRCodeDetector().DetectAndDecode(img, out pts)
    Motion     BackgroundSubtractorMOG2.Create().Apply(frame, mask)
               Cv2.CalcOpticalFlowPyrLK(prev, next, prevPts, ref nextPts,
                          out status, out err)
    Track      TrackerCSRT.Create(); t.Init(img, box); t.Update(img, ref box)
    ML         var m = SVM.Create();
               m.Train(samples, SampleTypes.RowSample, responses);
               m.Predict(query)
    DNN        var net = Cv2.Dnn.ReadNetFromONNX(path);
               net.SetInput(Cv2.Dnn.BlobFromImage(img, 1.0/255,
                          new Size(640,640), default, true, false));
               using var y = net.Forward();
               net.ForwardAll("Identity", "Identity_1")   //multi-output
    Show       Cv2.ImShow("w", mat); Cv2.WaitKey(1); Cv2.DestroyAllWindows()
    WPF        mat.ToWriteableBitmap() / mat.ToBitmapSource() /
               WriteableBitmapConverter.ToWriteableBitmap(mat, existingBitmap)
    Errors     OpenCVException (native: Status/FuncName/ErrMsg/FileName/Line)
               OpenCvSharpException (managed + native-load diagnostics)
    Analyzers  OCVS001 Row().At<T>(int)   OCVS002 Mat property in loop cond
               OCVS003 Row()/Col() in loop OCVS004 submatrix not disposed
    Golden     "using var" everything; reuse Mats across frames; cache
    rules      Rows/Cols; BGR not RGB; check Empty() and IsOpened().
================================================================================
