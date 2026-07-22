using System;
using System.Runtime.InteropServices;
using CodeBrix.VideoProcessing.OpenCV5.Internal;
using Xunit;

namespace CodeBrix.VideoProcessing.OpenCV5.Tests;
//Added for CodeBrix (not an upstream OpenCvSharp file): tests for the native
//  library load-failure diagnostics in NativeLibraryLoadDiagnostics.cs. These
//  tests deliberately avoid NativeMethods (whose static constructor attempts
//  the native load), so they run whether or not the native library is present
//  or loadable.

public class NativeLoadDiagnosticsTests
{
    [Fact]
    public void NativeLibraryFileNameMatchesPlatformConvention()
    {
        var fileName = NativeLibraryLoadDiagnostics.NativeLibraryFileName;
        if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            Assert.Equal("OpenCvSharpExtern.dll", fileName);
        else if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
            Assert.Equal("libOpenCvSharpExtern.dylib", fileName);
        else
            Assert.Equal("libOpenCvSharpExtern.so", fileName);
    }

    [Fact]
    public void RuntimePackageNameCoversCurrentPlatform()
    {
        var package = NativeLibraryLoadDiagnostics.GetRuntimePackageNameForCurrentPlatform();
        Assert.StartsWith("CodeBrix.VideoProcessing.OpenCV5.", package, StringComparison.Ordinal);
        Assert.EndsWith(".ApacheLicenseForever", package, StringComparison.Ordinal);
    }

    [Fact]
    public void ProbingDirectoriesIncludeApplicationBaseDirectory()
    {
        var dirs = NativeLibraryLoadDiagnostics.GetNativeProbingDirectories();
        Assert.NotEmpty(dirs);
        Assert.Contains(AppContext.BaseDirectory, dirs);
    }

    [Fact]
    public void DiagnosticStatesRootCauseForCurrentEnvironment()
    {
        // Environment-agnostic: whatever state this test host is in (native library
        // absent, present-and-loadable, or present-but-missing-dependencies), the
        // diagnostic must name the library file, the RID, and exactly one of the
        // known root-cause verdicts.
        var message = NativeLibraryLoadDiagnostics.Build();

        Assert.Contains(NativeLibraryLoadDiagnostics.NativeLibraryFileName, message, StringComparison.Ordinal);
        Assert.Contains(RuntimeInformation.RuntimeIdentifier, message, StringComparison.Ordinal);

        var notFound = message.Contains("NOT FOUND", StringComparison.Ordinal);
        var foundButFailed = message.Contains("FAILED TO LOAD", StringComparison.Ordinal);
        var loadsFine = message.Contains("loads successfully on its own", StringComparison.Ordinal);
        var wrongArch = message.Contains("wrong CPU", StringComparison.Ordinal);
        Assert.True(notFound || foundButFailed || loadsFine || wrongArch,
            "Diagnostic must state one of the known root-cause verdicts. Actual message: " + message);
    }
}
