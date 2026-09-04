# CodeBrix.VideoProcessing.OpenCV5

A fully managed .NET binding for OpenCV 5, providing image processing, video capture/analysis, camera calibration, object detection, machine learning, and the OpenCV contrib extra modules to .NET applications on Windows, Linux, and macOS (x64 and ARM64, plus RISC-V 64 on Linux).
CodeBrix.VideoProcessing.OpenCV5 has no managed dependencies other than .NET, and is provided as a .NET 10 library and associated `CodeBrix.VideoProcessing.OpenCV5.ApacheLicenseForever` NuGet package, plus a WPF interop package and seven per-platform native binding packages - nine in all, listed under Installation.

CodeBrix.VideoProcessing.OpenCV5 supports applications and assemblies that target Microsoft .NET version 10.0 and later.
Microsoft .NET version 10.0 is a Long-Term Supported (LTS) version of .NET, and was released on Nov 11, 2025; and will be actively supported by Microsoft until Nov 14, 2028.
Please update your C#/.NET code and projects to the latest LTS version of Microsoft .NET.

## Installation

Every application starts with the managed binding package:

```
dotnet add package CodeBrix.VideoProcessing.OpenCV5.ApacheLicenseForever
```

Note that the NuGet package ID and the namespace are different - there is no package named plain `CodeBrix.VideoProcessing.OpenCV5`:

* NuGet package ID: `CodeBrix.VideoProcessing.OpenCV5.ApacheLicenseForever`
* Assembly and primary namespace: `CodeBrix.VideoProcessing.OpenCV5` - i.e. `using CodeBrix.VideoProcessing.OpenCV5;`

XML documentation (IntelliSense) ships alongside the assembly, and the Roslyn analyzers are inside the same package - there is nothing extra to add for them.

### Which packages do I reference?

**The managed package contains no native code, so it cannot run on its own.** Reference the core package plus one native runtime package per platform your application targets - a cross-platform application references several. Add the WPF package only if you display `Mat` images in a WPF window.

```
dotnet add package CodeBrix.VideoProcessing.OpenCV5.ApacheLicenseForever
dotnet add package CodeBrix.VideoProcessing.OpenCV5.LinuxX64.ApacheLicenseForever
```

### The package family

| NuGet package | Contents |
|---|---|
| `CodeBrix.VideoProcessing.OpenCV5.ApacheLicenseForever` | The managed binding (all platforms) + Roslyn analyzers |
| `CodeBrix.VideoProcessing.OpenCV5.Wpf.ApacheLicenseForever` | WPF `BitmapSource`/`WriteableBitmap` converters (Windows only) |
| `CodeBrix.VideoProcessing.OpenCV5.WindowsX64.ApacheLicenseForever` | Native binding for Windows x64 (includes the FFmpeg videoio plugin) |
| `CodeBrix.VideoProcessing.OpenCV5.WindowsArm64.ApacheLicenseForever` | Native binding for Windows ARM64 |
| `CodeBrix.VideoProcessing.OpenCV5.LinuxX64.ApacheLicenseForever` | Native binding for Linux x64 |
| `CodeBrix.VideoProcessing.OpenCV5.LinuxArm64.ApacheLicenseForever` | Native binding for Linux ARM64 |
| `CodeBrix.VideoProcessing.OpenCV5.LinuxRiscv64.ApacheLicenseForever` | Native binding for Linux RISC-V 64 |
| `CodeBrix.VideoProcessing.OpenCV5.MacOSX64.ApacheLicenseForever` | Native binding for macOS x64 |
| `CodeBrix.VideoProcessing.OpenCV5.MacOSArm64.ApacheLicenseForever` | Native binding for macOS ARM64 (Apple Silicon) |

The Linux native libraries are portable, statically-linked builds (the manylinux model): one binary per architecture that runs on effectively any modern glibc distribution - Debian, Ubuntu, Raspberry Pi OS, RHEL-family, and more (glibc 2.28+ for x64/ARM64; glibc 2.38+ for RISC-V 64).

## CodeBrix.VideoProcessing.OpenCV5 supports:

* The OpenCV 5 core, imgproc, imgcodecs, videoio, video, calib3d, features, flann, dnn, ml, objdetect, photo, stitching, and highgui modules via the `Cv2` static class and the `Mat` family of types
* The OpenCV contrib extra modules: aruco, barcode, face, img_hash, line_descriptor, quality, saliency, shape, text, tracking, wechat_qrcode, xfeatures2d, ximgproc, xphoto, dnn_superres, and more
* Windows x64 and ARM64, Linux x64, ARM64, and RISC-V 64, and macOS x64 and Apple Silicon via per-platform native runtime packages
* WPF interop (`Mat` ↔ `BitmapSource` / `WriteableBitmap`) via the `CodeBrix.VideoProcessing.OpenCV5.Wpf.ApacheLicenseForever` package
* Built-in Roslyn analyzers that catch common `Mat` usage mistakes (undisposed `Row`/`Col` results, `Mat` property access in loop conditions) at compile time

## Sample Code

### Reading, processing, and saving an image

```csharp
using CodeBrix.VideoProcessing.OpenCV5;

using var src = Cv2.ImRead("input.jpg", ImreadModes.Grayscale);
using var dst = new Mat();

Cv2.Canny(src, dst, 50, 200);
Cv2.ImWrite("edges.png", dst);
```

### Capturing frames from a video file

```csharp
using CodeBrix.VideoProcessing.OpenCV5;

using var capture = new VideoCapture("movie.mp4");
using var frame = new Mat();

while (capture.Read(frame))
{
    // process each frame ...
}
```

## Documentation

The NuGet package includes `AGENT-README.txt`, a complete API reference and usage guide written for AI coding agents - point your agent at that file when it is writing code against this library. The same file ships in all nine packages and covers the whole family, including which native package to reference.

Additional sample code and usage examples are available in the test projects:
https://github.com/ellisnet/CodeBrix.VideoProcessing.OpenCV5/tree/main/tests

## License

CodeBrix.VideoProcessing.OpenCV5 is licensed under the Apache License 2.0 - see the
[LICENSE](https://github.com/ellisnet/CodeBrix.VideoProcessing.OpenCV5/blob/main/LICENSE) file.

For licensing and provenance information about the open source code included in
this package - including the provenance of the vendored native libraries - see
[THIRD-PARTY-NOTICES.txt](https://github.com/ellisnet/CodeBrix.VideoProcessing.OpenCV5/blob/main/THIRD-PARTY-NOTICES.txt).
