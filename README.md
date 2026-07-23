# CodeBrix.VideoProcessing.OpenCV5

A fully managed .NET binding for OpenCV 5, derived from the OpenCvSharp5 project, providing image processing, video capture/analysis, camera calibration, object detection, machine learning, and the OpenCV contrib extra modules to .NET applications on Windows, Linux, and macOS (x64 and ARM64, plus RISC-V 64 on Linux).
CodeBrix.VideoProcessing.OpenCV5 has no managed dependencies other than .NET, and is provided as a .NET 10 library and associated `CodeBrix.VideoProcessing.OpenCV5.ApacheLicenseForever` NuGet package, plus per-platform native binding packages (see below).

CodeBrix.VideoProcessing.OpenCV5 supports applications and assemblies that target Microsoft .NET version 10.0 and later.
Microsoft .NET version 10.0 is a Long-Term Supported (LTS) version of .NET, and was released on Nov 11, 2025; and will be actively supported by Microsoft until Nov 14, 2028.
Please update your C#/.NET code and projects to the latest LTS version of Microsoft .NET.

## CodeBrix.VideoProcessing.OpenCV5 supports:

* The OpenCV 5 core, imgproc, imgcodecs, videoio, video, calib3d, features, flann, dnn, ml, objdetect, photo, stitching, and highgui modules via the `Cv2` static class and the `Mat` family of types
* The OpenCV contrib extra modules: aruco, barcode, face, img_hash, line_descriptor, quality, saliency, shape, text, tracking, wechat_qrcode, xfeatures2d, ximgproc, xphoto, dnn_superres, and more
* Windows x64 and ARM64, Linux x64, ARM64, and RISC-V 64, and macOS x64 and Apple Silicon via per-platform native runtime packages
* WPF interop (`Mat` ↔ `BitmapSource` / `WriteableBitmap`) via the `CodeBrix.VideoProcessing.OpenCV5.Wpf.ApacheLicenseForever` package
* Built-in Roslyn analyzers that catch common `Mat` usage mistakes (undisposed `Row`/`Col` results, `Mat` property access in loop conditions) at compile time

## The package family

| NuGet package | Contents |
|---|---|
| `CodeBrix.VideoProcessing.OpenCV5.ApacheLicenseForever` | The managed binding (all platforms) + Roslyn analyzers |
| `CodeBrix.VideoProcessing.OpenCV5.Wpf.ApacheLicenseForever` | WPF `BitmapSource`/`WriteableBitmap` converters (Windows only) |
| `CodeBrix.VideoProcessing.OpenCV5.WindowsX64.ApacheLicenseForever` | Native binding for Windows x64 (includes the FFmpeg videoio plugin) |
| `CodeBrix.VideoProcessing.OpenCV5.WindowsArm64.ApacheLicenseForever` | Native binding for Windows ARM64 |
| `CodeBrix.VideoProcessing.OpenCV5.LinuxX64.ApacheLicenseForever` | Native binding for Linux x64 |
| `CodeBrix.VideoProcessing.OpenCV5.LinuxArm64.ApacheLicenseForever` | Native binding for Linux ARM64 |
| `CodeBrix.VideoProcessing.OpenCV5.LinuxRiscv64.ApacheLicenseForever` | Native binding for Linux RISC-V 64 — usable today with experimental riscv64 .NET 10 SDK builds |
| `CodeBrix.VideoProcessing.OpenCV5.MacOSX64.ApacheLicenseForever` | Native binding for macOS x64 |
| `CodeBrix.VideoProcessing.OpenCV5.MacOSArm64.ApacheLicenseForever` | Native binding for macOS ARM64 (Apple Silicon) |

Applications reference the core package plus the native runtime package(s) matching their target platform(s).

The Linux native libraries are portable, statically-linked builds (the manylinux model): one binary per architecture that runs on effectively any modern glibc distribution — Debian, Ubuntu, Raspberry Pi OS, RHEL-family, and more (glibc 2.28+ for x64/ARM64; glibc 2.39+ for RISC-V 64).

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

## License

The project is licensed under the Apache 2.0 License. see: https://en.wikipedia.org/wiki/Apache_License

CodeBrix.VideoProcessing.OpenCV5 is derived from the OpenCvSharp project by shimat and contributors (https://github.com/shimat/opencvsharp), also licensed under the Apache 2.0 License. See THIRD-PARTY-NOTICES.txt for full attribution, including the provenance of the vendored native libraries.
